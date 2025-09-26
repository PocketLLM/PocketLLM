/// File Overview:
/// - Purpose: Convenience wrapper that resolves the base API URL using
///   `ApiEndpoints` helpers for legacy front-end HTTP calls.
/// - Backend Migration: Deprecate alongside `PocketLLMService`; the backend
///   should inform the client about routing without this indirection.
import 'api_endpoints.dart';

final String apiBaseUrl = ApiEndpoints.buildUri(
  '',
  includeApiSuffix: true,
).toString();