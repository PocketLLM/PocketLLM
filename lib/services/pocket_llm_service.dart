import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'model_service.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart'; // Add this for secure storage

class PocketLLMService {
  static const String baseUrl = 'https://api.sree.shop/v1';
  static const _secureStorage = FlutterSecureStorage();
  static const String _apiKeyKey = 'pocketllm_api_key'; // Key for secure storage

  // Initialize API key securely
  static Future<void> initializeApiKey() async {
    // Check if API key exists in secure storage
    String? storedKey = await _secureStorage.read(key: _apiKeyKey);
    if (storedKey == null) {
      // Store the default API key securely if not present
      await _secureStorage.write(
        key: _apiKeyKey,
        value: 'ddc-m4qlvrgpt1W1E4ZXc4bvm5T5Z6CRFLeXRCx9AbRuQOcGpFFrX2',
      );
    }
  }

  // Get API key securely
  static Future<String?> getApiKey() async {
    return await _secureStorage.read(key: _apiKeyKey);
  }

  // Get available models
  static Future<List<Map<String, dynamic>>> getAvailableModels() async {
    try {
      final apiKey = await getApiKey();
      if (apiKey == null) {
        throw Exception('API key not found');
      }

      final response = await http.get(
        Uri.parse('$baseUrl/models'),
        headers: {
          'Authorization': 'Bearer $apiKey',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(data['data'] ?? []);
      } else {
        throw Exception('Failed to fetch models: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error fetching PocketLLM models: $e');
      throw Exception('Error fetching models: $e');
    }
  }

  // Get chat completion
  static Future<Map<String, dynamic>> getChatCompletion({
    required String model,
    required List<Map<String, String>> messages,
    double temperature = 0.7,
  }) async {
    try {
      final apiKey = await getApiKey();
      if (apiKey == null) {
        throw Exception('API key not found');
      }

      final response = await http.post(
        Uri.parse('$baseUrl/chat/completions'),
        headers: {
          'Authorization': 'Bearer $apiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'model': model,
          'messages': messages,
          'temperature': temperature,
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to get completion: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error getting chat completion: $e');
      throw Exception('Error getting completion: $e');
    }
  }

  // Create default model config
  static ModelConfig createDefaultConfig() {
    const String modelId = 'claude-3-5-sonnet'; // Updated default model ID
    return ModelConfig(
      id: modelId,
      name: modelId, // Use ID as name
      provider: ModelProvider.pocketLLM,
      baseUrl: baseUrl,
      apiKey: null,
      additionalParams: {
        'temperature': 0.7,
        'systemPrompt': 'You are a helpful AI assistant.',
      },
    );
  }

  // Test connection
  static Future<bool> testConnection(ModelConfig config) async {
    try {
      final apiKey = await getApiKey();
      if (apiKey == null) {
        return false;
      }

      final response = await http.get(
        Uri.parse('${config.baseUrl}/models'),
        headers: {
          'Authorization': 'Bearer $apiKey',
          'Content-Type': 'application/json',
        },
      );
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Error testing PocketLLM connection: $e');
      return false;
    }
  }
}