import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import 'api_endpoints.dart';

typedef _RequestInvoker = Future<http.Response> Function(String baseUrl);

class BackendApiService {
  BackendApiService._internal();
  static final BackendApiService _instance = BackendApiService._internal();
  factory BackendApiService() => _instance;

  static final List<String> _baseUrls = _resolveBaseUrls();
  static List<String> get baseUrls => _baseUrls;

  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  Future<Map<String, String>> _buildHeaders() async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    final candidates = [
      await _secureStorage.read(key: 'supabase_access_token'),
      await _secureStorage.read(key: 'auth.accessToken'),
    ];

    final token = candidates.firstWhere(
      (value) => value != null && value.isNotEmpty,
      orElse: () => null,
    );
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }

    return headers;
  }

  Uri _resolveUri(
    String baseUrl,
    String path, {
    Map<String, String>? query,
    bool withSuffix = true,
  }) {
    final normalizedPath = path.startsWith('/') ? path.substring(1) : path;

    var finalBase = baseUrl;
    while (finalBase.endsWith('/')) {
      finalBase = finalBase.substring(0, finalBase.length - 1);
    }

    if (withSuffix) {
      var suffix = _resolveApiSuffix().trim();
      while (suffix.startsWith('/')) {
        suffix = suffix.substring(1);
      }
      while (suffix.endsWith('/')) {
        suffix = suffix.substring(0, suffix.length - 1);
      }

      if (suffix.isNotEmpty) {
        final lowerSuffix = '/${suffix.toLowerCase()}';
        if (!finalBase.toLowerCase().endsWith(lowerSuffix)) {
          finalBase = '$finalBase/$suffix';
        }
      }
    }

    return Uri.parse('$finalBase/$normalizedPath').replace(queryParameters: query);
  }

  Future<dynamic> get(
    String path, {
    Map<String, String>? query,
    bool withSuffix = true,
  }) async {
    final headers = await _buildHeaders();
    final response = await _executeWithFallback(
      (baseUrl) => http.get(
        _resolveUri(
          baseUrl,
          path,
          query: query,
          withSuffix: withSuffix,
        ),
        headers: headers,
      ),
    );
    return _handleResponse(response);
  }

  Future<dynamic> post(String path, {Map<String, dynamic>? body}) async {
    final headers = await _buildHeaders();
    final response = await _executeWithFallback(
      (baseUrl) => http.post(
        _resolveUri(baseUrl, path),
        headers: headers,
        body: jsonEncode(body ?? {}),
      ),
    );
    return _handleResponse(response);
  }

  Future<dynamic> put(String path, {Map<String, dynamic>? body}) async {
    final headers = await _buildHeaders();
    final response = await _executeWithFallback(
      (baseUrl) => http.put(
        _resolveUri(baseUrl, path),
        headers: headers,
        body: jsonEncode(body ?? {}),
      ),
    );
    return _handleResponse(response);
  }

  Future<dynamic> patch(String path, {Map<String, dynamic>? body}) async {
    final headers = await _buildHeaders();
    final response = await _executeWithFallback(
      (baseUrl) => http.patch(
        _resolveUri(baseUrl, path),
        headers: headers,
        body: jsonEncode(body ?? {}),
      ),
    );
    return _handleResponse(response);
  }

  Future<dynamic> delete(String path) async {
    final headers = await _buildHeaders();
    final response = await _executeWithFallback(
      (baseUrl) => http.delete(
        _resolveUri(baseUrl, path),
        headers: headers,
      ),
    );
    return _handleResponse(response);
  }

  static List<String> _resolveBaseUrls() {
    final suffix = _resolveApiSuffix();
    const primaryEnvironmentCandidates = [
      String.fromEnvironment('POCKETLLM_BACKEND_URL', defaultValue: ''),
      String.fromEnvironment('POCKETLLM_BACKEND_BASE_URL', defaultValue: ''),
      String.fromEnvironment('POCKETLLM_BACKEND_ROOT_URL', defaultValue: ''),
      String.fromEnvironment('BACKEND_BASE_URL', defaultValue: ''),
    ];

    const fallbackEnvironmentCandidates = [
      String.fromEnvironment('POCKETLLM_FALLBACK_BACKEND_URL', defaultValue: ''),
      String.fromEnvironment('FALLBACK_BACKEND_URL', defaultValue: ''),
    ];

    final environmentCandidates = <String>[
      ...primaryEnvironmentCandidates,
      ...fallbackEnvironmentCandidates,
    ];

    final environmentOrder = <String>[];
    final environmentSet = <String>{};
    for (final candidate in environmentCandidates) {
      final trimmed = candidate.trim();
      if (trimmed.isEmpty) {
        continue;
      }

      final normalized = _stripSuffix(
        ApiEndpoints.resolveBaseUrl(trimmed),
        suffix,
      );

      if (environmentSet.add(normalized)) {
        environmentOrder.add(normalized);
      }
    }

    final merged = List.of(
      ApiEndpoints.mergeBaseUrls(environmentCandidates),
    );

    final ordered = <String>[];
    final seen = <String>{};

    for (final normalized in environmentOrder) {
      if (seen.add(normalized)) {
        ordered.add(normalized);
      }
    }

    for (final candidate in merged) {
      final cleaned = _stripSuffix(candidate, suffix);
      if (seen.add(cleaned)) {
        ordered.add(cleaned);
      }
    }

    debugPrint('Resolved backend URLs: $ordered');
    return List.unmodifiable(ordered);
  }

  static String _resolveApiSuffix() => ApiEndpoints.defaultApiSuffix;

  static String _stripSuffix(String baseUrl, String suffix) {
    var sanitizedSuffix = suffix.trim();
    while (sanitizedSuffix.startsWith('/')) {
      sanitizedSuffix = sanitizedSuffix.substring(1);
    }
    while (sanitizedSuffix.endsWith('/')) {
      sanitizedSuffix = sanitizedSuffix.substring(0, sanitizedSuffix.length - 1);
    }

    if (sanitizedSuffix.isEmpty) {
      return baseUrl;
    }

    final suffixFragment = '/${sanitizedSuffix.toLowerCase()}';
    if (baseUrl.toLowerCase().endsWith(suffixFragment)) {
      var withoutSuffix = baseUrl.substring(0, baseUrl.length - suffixFragment.length);
      while (withoutSuffix.endsWith('/')) {
        withoutSuffix = withoutSuffix.substring(0, withoutSuffix.length - 1);
      }
      return withoutSuffix;
    }
    return baseUrl;
  }

  Future<http.Response> _executeWithFallback(_RequestInvoker invoke) async {
    http.Response? lastResponse;
    Object? lastError;
    StackTrace? lastStackTrace;

    for (var index = 0; index < _baseUrls.length; index++) {
      final baseUrl = _baseUrls[index];
      final isLastAttempt = index == _baseUrls.length - 1;

      try {
        final response = await invoke(baseUrl);

        if (_shouldRetryResponse(response.statusCode) && !isLastAttempt) {
          lastResponse = response;
          debugPrint(
            'BackendApiService: Received status ${response.statusCode} from $baseUrl. Trying fallback backend.',
          );
          continue;
        }

        return response;
      } catch (error, stackTrace) {
        lastError = error;
        lastStackTrace = stackTrace;

        if (!isLastAttempt) {
          debugPrint(
            'BackendApiService: Request to $baseUrl failed ($error). Trying fallback backend.',
          );
          continue;
        }

        if (lastResponse != null) {
          return lastResponse!;
        }

        Error.throwWithStackTrace(error, stackTrace);
      }
    }

    if (lastResponse != null) {
      return lastResponse!;
    }

    if (lastError != null && lastStackTrace != null) {
      Error.throwWithStackTrace(lastError!, lastStackTrace!);
    }

    throw StateError('No backend URL configured.');
  }

  bool _shouldRetryResponse(int statusCode) {
    if (statusCode >= 500) {
      return true;
    }
    const retryableStatuses = {404, 405, 409, 0};
    return retryableStatuses.contains(statusCode);
  }

  dynamic _handleResponse(http.Response response) {
    try {
      final rawBody = response.body;
      final hasBody = rawBody.isNotEmpty && rawBody.trim().isNotEmpty;
      final decoded = hasBody ? jsonDecode(rawBody) : <String, dynamic>{};
      if (response.statusCode >= 200 && response.statusCode < 300) {
        // Return the entire response data, not just the 'data' field
        return decoded;
      }

      final errorMessage = _extractErrorMessage(decoded) ?? response.reasonPhrase;
      throw BackendApiException(response.statusCode, errorMessage ?? 'Unknown error');
    } catch (e) {
      if (e is BackendApiException) {
        throw e;
      }
      debugPrint('BackendApiService error: $e');
      throw BackendApiException(response.statusCode, 'Failed to parse backend response');
    }
  }

  String? _extractErrorMessage(dynamic payload) {
    if (payload == null) {
      return null;
    }

    if (payload is String) {
      final trimmed = payload.trim();
      return trimmed.isEmpty ? null : trimmed;
    }

    if (payload is Map<String, dynamic>) {
      for (final key in ['error', 'message', 'detail', 'description']) {
        if (!payload.containsKey(key)) {
          continue;
        }
        final resolved = _extractErrorMessage(payload[key]);
        if (resolved != null && resolved.isNotEmpty) {
          return resolved;
        }
      }
      return null;
    }

    if (payload is List) {
      for (final element in payload) {
        final resolved = _extractErrorMessage(element);
        if (resolved != null && resolved.isNotEmpty) {
          return resolved;
        }
      }
    }

    return null;
  }
}

class BackendApiException implements Exception {
  final int statusCode;
  final String message;

  BackendApiException(this.statusCode, this.message);

  @override
  String toString() => 'BackendApiException($statusCode): $message';
}
