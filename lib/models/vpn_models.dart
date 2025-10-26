import 'dart:math';

import 'package:flutter/foundation.dart';

/// Represents the current VPN connection status.
@immutable
class ConnectionStatus {
  const ConnectionStatus._(this.value);

  final String value;

  static const ConnectionStatus disconnected = ConnectionStatus._('disconnected');
  static const ConnectionStatus connecting = ConnectionStatus._('connecting');
  static const ConnectionStatus connected = ConnectionStatus._('connected');

  bool get isConnected => this == ConnectionStatus.connected;
  bool get isConnecting => this == ConnectionStatus.connecting;

  static const List<ConnectionStatus> values = <ConnectionStatus>[
    disconnected,
    connecting,
    connected,
  ];

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is ConnectionStatus && other.value == value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => value;
}

/// Describes the connection quality based on measured latency and reliability.
@immutable
class ConnectionQuality {
  const ConnectionQuality._(this.label, this.description, this.colorName);

  final String label;
  final String description;
  final String colorName;

  static const ConnectionQuality excellent =
      ConnectionQuality._('Excellent', 'Ultra-low latency and stable', 'blue');
  static const ConnectionQuality good =
      ConnectionQuality._('Good', 'Reliable for streaming and browsing', 'green');
  static const ConnectionQuality fair =
      ConnectionQuality._('Fair', 'Usable with occasional drops', 'amber');
  static const ConnectionQuality poor =
      ConnectionQuality._('Poor', 'High latency or limited bandwidth', 'red');

  static ConnectionQuality fromLatency(int latencyMs) {
    if (latencyMs <= 40) return excellent;
    if (latencyMs <= 75) return good;
    if (latencyMs <= 120) return fair;
    return poor;
  }

  static ConnectionQuality mix(ConnectionQuality a, ConnectionQuality b) {
    final indexA = values.indexOf(a);
    final indexB = values.indexOf(b);
    final mixedIndex = (indexA + indexB) ~/ 2;
    return values[mixedIndex.clamp(0, values.length - 1)];
  }

  static const List<ConnectionQuality> values = <ConnectionQuality>[
    excellent,
    good,
    fair,
    poor,
  ];

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is ConnectionQuality && other.label == label;

  @override
  int get hashCode => label.hashCode;

  @override
  String toString() => label;
}

/// Stores information about an available VPN exit location.
@immutable
class VpnLocation {
  const VpnLocation({
    required this.city,
    required this.countryCode,
    required this.latencyMs,
    this.isPremium = false,
    this.flagEmoji,
  });

  final String city;
  final String countryCode;
  final int latencyMs;
  final bool isPremium;
  final String? flagEmoji;

  String get displayName => '$city';
  String get formattedLatency => '${latencyMs} ms';
  String get emoji => flagEmoji ?? _countryCodeToEmoji(countryCode);

  ConnectionQuality get quality => ConnectionQuality.fromLatency(latencyMs);
}

/// Captures the result of a completed speed test run.
@immutable
class SpeedTestResult {
  const SpeedTestResult({
    required this.downloadMbps,
    required this.uploadMbps,
    required this.pingMs,
    required this.jitterMs,
    required this.timestamp,
    required this.ipAddress,
    required this.location,
  });

  final double downloadMbps;
  final double uploadMbps;
  final double pingMs;
  final double jitterMs;
  final DateTime timestamp;
  final String ipAddress;
  final VpnLocation location;

  String get formattedDownload => _formatMbps(downloadMbps);
  String get formattedUpload => _formatMbps(uploadMbps);
  String get formattedPing => '${pingMs.toStringAsFixed(1)} ms';
  String get formattedJitter => '${jitterMs.toStringAsFixed(1)} ms';

  static String _formatMbps(double value) => '${value.toStringAsFixed(1)} Mbps';
}

/// Enumerates history entry types for the History tab.
enum HistoryEntryType {
  connection,
  speedTest,
}

/// Represents a historical record of either connection changes or completed
/// speed tests.
@immutable
class HistoryEntry {
  const HistoryEntry.connection({
    required this.timestamp,
    required this.location,
    required this.status,
    required this.duration,
    required this.dataUsageMb,
    required this.quality,
  })  : type = HistoryEntryType.connection,
        speedTestResult = null;

  const HistoryEntry.speedTest({
    required SpeedTestResult result,
  })  : timestamp = result.timestamp,
        location = result.location,
        status = ConnectionStatus.connected,
        duration = Duration.zero,
        dataUsageMb = 0,
        quality = result.location.quality,
        type = HistoryEntryType.speedTest,
        speedTestResult = result;

  final HistoryEntryType type;
  final DateTime timestamp;
  final VpnLocation location;
  final ConnectionStatus status;
  final Duration duration;
  final double dataUsageMb;
  final ConnectionQuality quality;
  final SpeedTestResult? speedTestResult;

  String get formattedDuration {
    if (duration.inSeconds == 0) return '—';
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    }
    if (minutes > 0) {
      return '${minutes}m ${seconds}s';
    }
    return '${seconds}s';
  }

  String get formattedDataUsage {
    if (dataUsageMb <= 0) return '—';
    if (dataUsageMb >= 1024) {
      final gb = dataUsageMb / 1024;
      return '${gb.toStringAsFixed(2)} GB';
    }
    return '${dataUsageMb.toStringAsFixed(1)} MB';
  }
}

String _countryCodeToEmoji(String countryCode) {
  if (countryCode.length != 2) return '🌐';
  final upper = countryCode.toUpperCase();
  final int first = upper.codeUnitAt(0) - 0x41 + 0x1F1E6;
  final int second = upper.codeUnitAt(1) - 0x41 + 0x1F1E6;
  return String.fromCharCode(first) + String.fromCharCode(second);
}

ConnectionQuality randomQuality(Random random) {
  return ConnectionQuality.values[random.nextInt(ConnectionQuality.values.length)];
}
