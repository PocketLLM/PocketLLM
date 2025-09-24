import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

class BackendApiService {
  BackendApiService._internal();
  static final BackendApiService _instance = BackendApiService._internal();
  factory BackendApiService() => _instance;

  static const String _baseUrl = String.fromEnvironment(
    'POCKETLLM_BACKEND_URL',
    defaultValue: 'http://localhost:8000/v1',
  );

  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  Future<Map<String, String>> _buildHeaders() async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    final token = await _secureStorage.read(key: 'supabase_access_token');
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }

    return headers;
  }

  Uri _resolveUri(String path, [Map<String, String>? query]) {
    final normalized = path.startsWith('/') ? path.substring(1) : path;
    return Uri.parse('$_baseUrl/$normalized').replace(queryParameters: query);
  }

  Future<dynamic> get(String path, {Map<String, String>? query}) async {
    final response = await http.get(
      _resolveUri(path, query),
      headers: await _buildHeaders(),
    );
    return _handleResponse(response);
  }

  Future<dynamic> post(String path, {Map<String, dynamic>? body}) async {
    final response = await http.post(
      _resolveUri(path),
      headers: await _buildHeaders(),
      body: jsonEncode(body ?? {}),
    );
    return _handleResponse(response);
  }

  Future<dynamic> patch(String path, {Map<String, dynamic>? body}) async {
    final response = await http.patch(
      _resolveUri(path),
      headers: await _buildHeaders(),
      body: jsonEncode(body ?? {}),
    );
    return _handleResponse(response);
  }

  Future<dynamic> delete(String path) async {
    final response = await http.delete(
      _resolveUri(path),
      headers: await _buildHeaders(),
    );
    return _handleResponse(response);
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
