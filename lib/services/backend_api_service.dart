import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

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

  Uri _resolveUri(String baseUrl, String path, [Map<String, String>? query]) {
    final normalizedPath = path.startsWith('/') ? path.substring(1) : path;
    return Uri.parse('$baseUrl/$normalizedPath').replace(queryParameters: query);
  }

  Future<dynamic> get(String path, {Map<String, String>? query}) async {
    final headers = await _buildHeaders();
    final response = await _executeWithFallback(
      (baseUrl) => http.get(
        _resolveUri(baseUrl, path, query),
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
    final urls = <String>[];
    final seen = <String>{};

    void addCandidate(String raw) {
      final normalized = _normalizeBaseUrl(raw);
      if (normalized == null) {
        return;
      }

      final withSuffix = _ensureSuffix(normalized, suffix);
      if (seen.add(withSuffix)) {
        urls.add(withSuffix);
      }
    }

    const primaryCandidates = [
      String.fromEnvironment('POCKETLLM_BACKEND_URL', defaultValue: ''),
      String.fromEnvironment('POCKETLLM_BACKEND_BASE_URL', defaultValue: ''),
      String.fromEnvironment('POCKETLLM_BACKEND_ROOT_URL', defaultValue: ''),
      String.fromEnvironment('BACKEND_BASE_URL', defaultValue: ''),
    ];

    for (final candidate in primaryCandidates) {
      addCandidate(candidate);
    }

    if (urls.isEmpty) {
      addCandidate('http://localhost:8000');
    }

    const fallbackCandidates = [
      String.fromEnvironment('POCKETLLM_FALLBACK_BACKEND_URL', defaultValue: ''),
      String.fromEnvironment('FALLBACK_BACKEND_URL', defaultValue: ''),
    ];

    for (final candidate in fallbackCandidates) {
      addCandidate(candidate);
    }

    return List.unmodifiable(urls);
  }

  static String _resolveApiSuffix() {
    const suffixCandidates = [
      String.fromEnvironment('POCKETLLM_BACKEND_SUFFIX', defaultValue: ''),
      String.fromEnvironment('POCKETLLM_BACKEND_API_SUFFIX', defaultValue: ''),
      String.fromEnvironment('BACKEND_API_SUFFIX', defaultValue: ''),
    ];

    for (final candidate in suffixCandidates) {
      final trimmed = candidate.trim();
      if (trimmed.isNotEmpty) {
        return trimmed;
      }
    }

    return 'v1';
  }

  static String? _normalizeBaseUrl(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      return null;
    }

    var normalized = trimmed;
    while (normalized.endsWith('/')) {
      normalized = normalized.substring(0, normalized.length - 1);
    }
    return normalized;
  }

  static String _ensureSuffix(String baseUrl, String suffix) {
    final sanitizedSuffix = suffix.trim();
    if (sanitizedSuffix.isEmpty) {
      return baseUrl;
    }

    final normalizedSuffix = sanitizedSuffix.startsWith('/')
        ? sanitizedSuffix.substring(1)
        : sanitizedSuffix;

    if (normalizedSuffix.isEmpty) {
      return baseUrl;
    }

    if (baseUrl.toLowerCase().endsWith('/${normalizedSuffix.toLowerCase()}')) {
      return baseUrl;
    }

    return '$baseUrl/$normalizedSuffix';
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

        if (response.statusCode >= 500 && !isLastAttempt) {
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

  dynamic _handleResponse(http.Response response) {
    try {
      final decoded = jsonDecode(response.body);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return decoded['data'];
      }

      final errorMessage = decoded['error']?['message'] ?? response.reasonPhrase;
      throw BackendApiException(response.statusCode, errorMessage ?? 'Unknown error');
    } catch (e) {
      if (e is BackendApiException) {
        throw e;
      }
      debugPrint('BackendApiService error: $e');
      throw BackendApiException(response.statusCode, 'Failed to parse backend response');
    }
  }
}

class BackendApiException implements Exception {
  final int statusCode;
  final String message;

  BackendApiException(this.statusCode, this.message);

  @override
  String toString() => 'BackendApiException($statusCode): $message';
}
