import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/vpn_models.dart';

typedef SpeedTestProgressCallback = void Function(double progress);

/// Describes an error that occurred while attempting to run a speed test.
class SpeedTestException implements Exception {
  SpeedTestException(this.message, {this.cause});

  final String message;
  final Object? cause;

  @override
  String toString() => 'SpeedTestException($message, cause: $cause)';
}

/// Executes latency, download and upload measurements against public CDN test
/// endpoints. Values are converted to Mbps for display.
class SpeedTestService {
  SpeedTestService({http.Client? httpClient}) : _client = httpClient ?? http.Client();

  final http.Client _client;

  static final Uri _pingUri = Uri.parse('https://www.google.com/generate_204');
  static final Uri _downloadUri = Uri.parse('https://speed.cloudflare.com/__down');
  static final Uri _uploadUri = Uri.parse('https://speed.cloudflare.com/__up');
  static final Uri _ipLookupUri = Uri.parse('https://api64.ipify.org?format=json');

  Future<SpeedTestResult> runTest({
    required VpnLocation location,
    SpeedTestProgressCallback? onProgress,
    int downloadSizeBytes = 5 * 1024 * 1024,
    int uploadSizeBytes = 2 * 1024 * 1024,
  }) async {
    try {
      onProgress?.call(0.02);
      final pingSamples = await _measurePing(_pingUri, attempts: 5);
      final pingMs = _average(pingSamples);
      final jitterMs = _calculateJitter(pingSamples);
      onProgress?.call(0.18);

      final downloadMbps = await _measureDownload(
        _downloadUri.replace(queryParameters: <String, String>{
          'bytes': downloadSizeBytes.toString(),
        }),
        expectedBytes: downloadSizeBytes,
        onProgress: (value) => onProgress?.call(0.18 + value * 0.55),
      );

      final uploadMbps = await _measureUpload(
        _uploadUri,
        uploadSizeBytes,
        onProgress: (value) => onProgress?.call(0.75 + value * 0.2),
      );

      final ip = await _fetchIpAddress();
      onProgress?.call(1.0);

      return SpeedTestResult(
        downloadMbps: downloadMbps,
        uploadMbps: uploadMbps,
        pingMs: pingMs,
        jitterMs: jitterMs,
        timestamp: DateTime.now(),
        ipAddress: ip,
        location: location,
      );
    } catch (error) {
      throw SpeedTestException('Unable to run speed test', cause: error);
    }
  }

  Future<List<double>> _measurePing(Uri uri, {int attempts = 4}) async {
    final List<double> results = <double>[];
    for (int i = 0; i < attempts; i++) {
      final stopwatch = Stopwatch()..start();
      try {
        final response = await _client
            .get(uri)
            .timeout(const Duration(seconds: 6));
        stopwatch.stop();
        if (response.statusCode >= 200 && response.statusCode < 400) {
          results.add(stopwatch.elapsedMicroseconds / 1000);
        }
      } catch (_) {
        stopwatch.stop();
      }
      await Future<void>.delayed(const Duration(milliseconds: 150));
    }
    if (results.isEmpty) {
      throw SpeedTestException('Ping test timed out');
    }
    return results;
  }

  Future<double> _measureDownload(
    Uri uri, {
    required int expectedBytes,
    SpeedTestProgressCallback? onProgress,
  }) async {
    final request = http.Request('GET', uri);
    final stopwatch = Stopwatch()..start();
    final response = await _client.send(request).timeout(const Duration(seconds: 30));

    int received = 0;
    final completer = Completer<void>();
    response.stream.listen(
      (List<int> chunk) {
        received += chunk.length;
        if (expectedBytes > 0) {
          onProgress?.call(received / expectedBytes);
        }
      },
      onError: completer.completeError,
      onDone: completer.complete,
      cancelOnError: true,
    );
    await completer.future;
    stopwatch.stop();

    if (received <= 0) {
      throw SpeedTestException('No bytes received during download test');
    }

    final seconds = stopwatch.elapsedMicroseconds / 1e6;
    final bits = received * 8;
    return bits / seconds / 1e6;
  }

  Future<double> _measureUpload(
    Uri uri,
    int totalBytes, {
    SpeedTestProgressCallback? onProgress,
  }) async {
    final request = http.StreamedRequest('POST', uri);
    request.headers['Content-Type'] = 'application/octet-stream';

    final chunkSize = 64 * 1024;
    final zeroChunk = Uint8List(chunkSize);
    int sent = 0;

    while (sent < totalBytes) {
      final remaining = totalBytes - sent;
      final length = min(chunkSize, remaining);
      request.sink.add(zeroChunk.sublist(0, length));
      sent += length;
      if (totalBytes > 0) {
        onProgress?.call(sent / totalBytes);
      }
      await Future<void>.delayed(Duration.zero);
    }

    await request.sink.close();

    final stopwatch = Stopwatch()..start();
    final response = await _client.send(request).timeout(const Duration(seconds: 30));
    await response.stream.drain();
    stopwatch.stop();

    if (sent <= 0) {
      throw SpeedTestException('No bytes uploaded during upload test');
    }

    final seconds = stopwatch.elapsedMicroseconds / 1e6;
    final bits = sent * 8;
    return bits / seconds / 1e6;
  }

  Future<String> _fetchIpAddress() async {
    try {
      final response = await _client.get(_ipLookupUri).timeout(const Duration(seconds: 8));
      if (response.statusCode == 200) {
        final Map<String, dynamic> json = jsonDecode(response.body) as Map<String, dynamic>;
        final ip = json['ip'] as String?;
        if (ip != null && ip.isNotEmpty) {
          return ip;
        }
      }
    } catch (_) {
      // Ignore, we will return a placeholder below.
    }
    return 'Unknown';
  }

  double _average(List<double> values) {
    if (values.isEmpty) return 0;
    return values.reduce((double a, double b) => a + b) / values.length;
  }

  double _calculateJitter(List<double> samples) {
    if (samples.length < 2) return 0;
    double total = 0;
    for (int i = 1; i < samples.length; i++) {
      total += (samples[i] - samples[i - 1]).abs();
    }
    return total / (samples.length - 1);
  }

  @visibleForTesting
  void dispose() {
    _client.close();
  }
}
