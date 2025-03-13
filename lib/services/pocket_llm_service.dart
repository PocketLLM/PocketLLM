import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'model_service.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class PocketLLMService {
  static const String baseUrl = 'https://api.sree.shop/v1';
  static const _secureStorage = FlutterSecureStorage();
  static const String _apiKeyKey = 'pocketllm_api_key';

  // Initialize API key securely
  static Future<void> initializeApiKey() async {
    String? storedKey = await _secureStorage.read(key: _apiKeyKey);
    if (storedKey == null) {
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

  // Get chat completion (non-streaming)
  static Future<String> getPocketLLMResponse(
    ModelConfig config,
    String userMessage,
  ) async {
    try {
      final apiKey = await getApiKey();
      if (apiKey == null) {
        throw Exception('API key not found');
      }

      final messages = [];
      
      // Add system prompt if provided
      final systemPrompt = config.additionalParams?['systemPrompt'] as String? ?? '';
      if (systemPrompt.isNotEmpty) {
        messages.add({'role': 'system', 'content': systemPrompt});
      }
      
      messages.add({'role': 'user', 'content': userMessage});
      
      final temperature = config.additionalParams?['temperature'] ?? 0.7;

      // Ensure the full URL is constructed correctly
      final uri = Uri.parse('$baseUrl/chat/completions');
      debugPrint('Making request to: $uri');

      final response = await http.post(
        uri,
        headers: {
          'Authorization': 'Bearer $apiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'model': config.id,
          'messages': messages,
          'temperature': temperature,
          'stream': false
        }),
      );

      debugPrint('Response status: ${response.statusCode}');
      debugPrint('Response body: ${response.body}');
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['choices'] == null || data['choices'].isEmpty) {
          throw Exception('Invalid response format: missing choices');
        }
        final choice = data['choices'][0];
        if (choice['message'] == null || choice['message']['content'] == null) {
          throw Exception('Invalid response format: missing message content');
        }
        return choice['message']['content'];
      } else {
        final errorBody = jsonDecode(response.body);
        final errorMessage = errorBody['error']?['message'] ?? 'Unknown error';
        debugPrint('PocketLLM API error: ${response.statusCode} $errorMessage');
        throw Exception('Failed to get response: $errorMessage');
      }
    } catch (e) {
      debugPrint('Error getting PocketLLM response: $e');
      throw Exception('Error getting response: $e');
    }
  }

  // Create default model config
  static ModelConfig createDefaultConfig() {
    const String modelId = 'claude-3-5-sonnet';
    return ModelConfig(
      id: modelId,
      name: modelId,
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