/// File Overview:
/// - Purpose: Low-level HTTP client that supports base URL fallbacks and token
///   injection for backend API access.
/// - Backend Migration: Keep but audit once backend consolidates URLs and
///   authentication; may be replaced by generated client.
import 'dart:async';
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
  final Duration _tokenRefreshWindow = const Duration(minutes: 5);
  final Duration _tokenExpiryGrace = const Duration(seconds: 30);

  Completer<bool>? _refreshCompleter;

  static const String _accessTokenKey = 'auth.accessToken';
  static const String _refreshTokenKey = 'auth.refreshToken';
  static const String _tokenExpiryKey = 'auth.accessTokenExpiry';

  Future<Map<String, String>> _buildHeaders() async {
    await _ensureValidAccessToken();

    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    final candidates = [
      await _secureStorage.read(key: 'supabase_access_token'),
      await _secureStorage.read(key: _accessTokenKey),
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

  Future<void> _ensureValidAccessToken() async {
    final expiryIso = await _secureStorage.read(key: _tokenExpiryKey);
    if (expiryIso == null || expiryIso.isEmpty) {
      return;
    }

    DateTime? expiry;
    try {
      expiry = DateTime.parse(expiryIso).toUtc();
    } catch (error) {
      debugPrint('BackendApiService: Failed to parse access token expiry: $error');
      await _secureStorage.delete(key: _tokenExpiryKey);
      return;
    }

    final now = DateTime.now().toUtc();
    final timeUntilExpiry = expiry.difference(now);

    if (timeUntilExpiry <= Duration.zero || timeUntilExpiry <= _tokenExpiryGrace) {
      final refreshed = await _refreshAccessToken(force: true);
      if (!refreshed) {
        await _clearStoredTokens();
      }
      return;
    }

    if (timeUntilExpiry <= _tokenRefreshWindow) {
      await _refreshAccessToken(force: false);
    }
  }

  Future<bool> _refreshAccessToken({required bool force}) async {
    final existingRefreshToken = await _secureStorage.read(key: _refreshTokenKey);
    if (existingRefreshToken == null || existingRefreshToken.isEmpty) {
      if (force) {
        await _clearStoredTokens();
      }
      return false;
    }

    if (_refreshCompleter != null) {
      return _refreshCompleter!.future;
    }

    final completer = Completer<bool>();
    _refreshCompleter = completer;
    final future = completer.future;

    try {
      final response = await _executeWithFallback(
        (baseUrl) => http.post(
          _resolveUri(baseUrl, 'auth/refresh'),
          headers: const {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
          body: jsonEncode({'refresh_token': existingRefreshToken}),
        ),
      );

      final payload = _handleResponse(response);
      if (payload is! Map) {
        throw BackendApiException(response.statusCode, 'Unexpected refresh response payload');
      }

      final tokensPayload = payload['tokens'];
      final sessionPayload = payload['session'];
      if (tokensPayload is! Map) {
        throw const BackendApiException(500, 'Refresh response missing tokens payload');
      }

      final accessToken = tokensPayload['access_token'] as String?;
      final refreshToken = tokensPayload['refresh_token'] as String?;
      final expiresIn = tokensPayload['expires_in'];

      if (accessToken == null || accessToken.isEmpty) {
        throw const BackendApiException(500, 'Refresh response missing access token');
      }

      DateTime? expiresAt;
      if (expiresIn is num) {
        expiresAt = DateTime.now().toUtc().add(Duration(seconds: expiresIn.toInt()));
      } else if (sessionPayload is Map && sessionPayload['expires_at'] is String) {
        try {
          expiresAt = DateTime.parse(sessionPayload['expires_at'] as String).toUtc();
        } catch (error) {
          debugPrint('BackendApiService: Failed to parse refreshed session expiry: $error');
        }
      }

      await _secureStorage.write(key: _accessTokenKey, value: accessToken);
      await _secureStorage.write(key: 'auth.accessToken', value: accessToken);
      await _secureStorage.write(key: 'supabase_access_token', value: accessToken);

      if (refreshToken != null && refreshToken.isNotEmpty) {
        await _secureStorage.write(key: _refreshTokenKey, value: refreshToken);
        await _secureStorage.write(key: 'auth.refreshToken', value: refreshToken);
      }

      if (expiresAt != null) {
        final expiryValue = expiresAt.toIso8601String();
        await _secureStorage.write(key: _tokenExpiryKey, value: expiryValue);
        await _secureStorage.write(key: 'auth.accessTokenExpiry', value: expiryValue);
      } else {
        await _secureStorage.delete(key: _tokenExpiryKey);
      }

      if (!completer.isCompleted) {
        completer.complete(true);
      }
    } on BackendApiException catch (error) {
      debugPrint('BackendApiService: Token refresh failed: $error');
      if (force || error.statusCode == 401) {
        await _clearStoredTokens();
      }
      if (!completer.isCompleted) {
        completer.complete(false);
      }
    } catch (error, stackTrace) {
      debugPrint('BackendApiService: Unexpected token refresh error: $error');
      debugPrint(stackTrace.toString());
      if (force) {
        await _clearStoredTokens();
      }
      if (!completer.isCompleted) {
        completer.complete(false);
      }
    } finally {
      _refreshCompleter = null;
    }

    return future;
  }

  Future<void> _clearStoredTokens() async {
    await _secureStorage.delete(key: _accessTokenKey);
    await _secureStorage.delete(key: 'auth.accessToken');
    await _secureStorage.delete(key: _refreshTokenKey);
    await _secureStorage.delete(key: 'auth.refreshToken');
    await _secureStorage.delete(key: _tokenExpiryKey);
    await _secureStorage.delete(key: 'auth.accessTokenExpiry');
    await _secureStorage.delete(key: 'supabase_access_token');
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

        // Provide more specific error messages
        String errorMessage = error.toString();
        if (error is http.ClientException && 
            errorMessage.contains('Failed host lookup')) {
          errorMessage = 'Unable to connect to server. Please check your internet connection.';
        }

        if (!isLastAttempt) {
          debugPrint(
            'BackendApiService: Request to $baseUrl failed ($errorMessage). Trying fallback backend.',
          );
          continue;
        }

        if (lastResponse != null) {
          return lastResponse;
        }

        // Throw a more user-friendly error
        Error.throwWithStackTrace(
          Exception(errorMessage),
          stackTrace,
        );
      }
    }

    if (lastResponse != null) {
      return lastResponse;
    }

    if (lastError != null && lastStackTrace != null) {
      // Provide a more user-friendly error for network issues
      String errorMessage = lastError.toString();
      if (errorMessage.contains('Failed host lookup') || 
          errorMessage.contains('SocketException')) {
        errorMessage = 'Unable to connect to the server. Please check your internet connection.';
      } else if (errorMessage.contains('500')) {
        errorMessage = 'Server error. Please try again later.';
      }
      
      Error.throwWithStackTrace(
        Exception(errorMessage),
        lastStackTrace,
      );
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
      
      // Check if response is valid JSON
      if (hasBody) {
        try {
          final decoded = jsonDecode(rawBody);
          if (response.statusCode >= 200 && response.statusCode < 300) {
            // Return the entire response data, not just the 'data' field
            return decoded;
          }

          final errorMessage = _extractErrorMessage(decoded) ?? response.reasonPhrase;
          throw BackendApiException(response.statusCode, errorMessage ?? 'Unknown error');
        } catch (e) {
          // Handle non-JSON responses (like plain text error messages)
          if (e is! FormatException) rethrow;
          
          // If it's a format exception, treat the raw body as the error message
          final errorMessage = hasBody ? rawBody : response.reasonPhrase;
          if (response.statusCode >= 200 && response.statusCode < 300) {
            // For successful responses that aren't valid JSON, return as is
            return rawBody;
          }
          throw BackendApiException(response.statusCode, errorMessage ?? 'Unknown error');
        }
      } else {
        // No response body
        if (response.statusCode >= 200 && response.statusCode < 300) {
          return <String, dynamic>{}; // Return empty map for successful responses with no body
        }
        throw BackendApiException(response.statusCode, response.reasonPhrase ?? 'Unknown error');
      }
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
