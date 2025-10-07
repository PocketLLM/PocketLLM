/// File Overview:
/// - Purpose: Utility for normalizing backend URLs and building endpoint URIs.
/// - Backend Migration: Keep until backend provides generated API client; then
///   consolidate to avoid duplicated string handling.
import 'package:flutter/foundation.dart';

class ApiEndpoints {
  ApiEndpoints._();

  static const String defaultBackendBaseUrl = String.fromEnvironment(
    'POCKETLLM_BACKEND_URL',
    defaultValue: 'https://pocket-llm-api.vercel.app',
  );

  static const String defaultDocsUrl = String.fromEnvironment(
    'POCKETLLM_BACKEND_DOCS_URL',
    defaultValue: 'https://pocket-llm-api.vercel.app/docs',
  );

  static const String defaultHealthUrl = String.fromEnvironment(
    'POCKETLLM_BACKEND_HEALTH_URL',
    defaultValue: 'https://pocket-llm-api.vercel.app/health',
  );

  static const String defaultApiSuffix = String.fromEnvironment(
    'POCKETLLM_BACKEND_SUFFIX',
    defaultValue: 'v1',
  );

  static const List<String> defaultBaseUrls = <String>[
    defaultBackendBaseUrl,
    'https://pocket-llm-api.vercel.app',
  ];

  static String resolveBaseUrl([String? override]) {
    final value = (override ?? defaultBackendBaseUrl).trim();
    if (value.isEmpty) {
      return defaultBackendBaseUrl;
    }

    var normalized = value;
    while (normalized.endsWith('/')) {
      normalized = normalized.substring(0, normalized.length - 1);
    }
    return normalized;
  }

  static String resolveDocsUrl([String? override]) => _normalizeUrl(override ?? defaultDocsUrl);

  static String resolveHealthUrl([String? override]) => _normalizeUrl(override ?? defaultHealthUrl);

  static Uri buildUri(
    String path, {
    Map<String, String>? queryParameters,
    bool includeApiSuffix = true,
    String? overrideBaseUrl,
  }) {
    final base = resolveBaseUrl(overrideBaseUrl);
    final buffer = StringBuffer(base);

    final suffix = includeApiSuffix ? defaultApiSuffix.trim() : '';
    if (suffix.isNotEmpty) {
      final sanitizedSuffix = _trimSlashes(suffix);
      final lowerSuffix = '/${sanitizedSuffix.toLowerCase()}';
      if (!base.toLowerCase().endsWith(lowerSuffix)) {
        buffer.write('/$sanitizedSuffix');
      }
    }

    final normalizedPath = _trimLeadingSlash(path);
    if (normalizedPath.isNotEmpty) {
      buffer.write('/$normalizedPath');
    }

    final uri = Uri.parse(buffer.toString());
    return uri.replace(queryParameters: queryParameters);
  }

  static List<String> mergeBaseUrls(Iterable<String> additional) {
    final seen = <String>{};
    final resolved = <String>[];

    void add(String value) {
      final normalized = resolveBaseUrl(value);
      if (seen.add(normalized)) {
        resolved.add(normalized);
      }
    }

    for (final candidate in defaultBaseUrls) {
      if (candidate.trim().isEmpty) continue;
      add(candidate);
    }

    for (final candidate in additional) {
      if (candidate.trim().isEmpty) continue;
      add(candidate);
    }

    if (resolved.isEmpty) {
      resolved.add(resolveBaseUrl(defaultBackendBaseUrl));
    }

    debugPrint('ApiEndpoints.mergeBaseUrls resolved: $resolved');
    return List.unmodifiable(resolved);
  }

  static String get docsUrl => resolveDocsUrl();

  static String get healthUrl => resolveHealthUrl();

  static Uri authSignIn({String? baseUrl}) =>
      buildUri('/auth/signin', overrideBaseUrl: baseUrl);

  static Uri authSignUp({String? baseUrl}) =>
      buildUri('/auth/signup', overrideBaseUrl: baseUrl);

  static Uri userProfile({String? baseUrl}) =>
      buildUri('/users/profile', overrideBaseUrl: baseUrl);

  static String _trimLeadingSlash(String value) {
    var result = value.trim();
    while (result.startsWith('/')) {
      result = result.substring(1);
    }
    return result;
  }

  static String _trimSlashes(String value) {
    var result = value.trim();
    while (result.startsWith('/')) {
      result = result.substring(1);
    }
    while (result.endsWith('/')) {
      result = result.substring(0, result.length - 1);
    }
    return result;
  }

  static String _normalizeUrl(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      return trimmed;
    }
    return trimmed.endsWith('/') ? trimmed.substring(0, trimmed.length - 1) : trimmed;
  }
}
