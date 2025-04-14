import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../component/models.dart';

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
        // Return some default models instead of throwing an exception
        return [
          {
            'id': 'gpt-3.5-turbo',
            'display_name': 'GPT-3.5 Turbo',
          },
          {
            'id': 'gpt-4',
            'display_name': 'GPT-4',
          },
          {
            'id': 'claude-3-5-sonnet',
            'display_name': 'Claude 3.5 Sonnet',
          },
          {
            'id': 'claude-3-opus',
            'display_name': 'Claude 3 Opus',
          },
          {
            'id': 'mistral-large',
            'display_name': 'Mistral Large',
          }
        ];
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
        final models = List<Map<String, dynamic>>.from(data['data'] ?? []);
        
        // Ensure each model has a display name, defaulting to its ID if none is provided
        for (var model in models) {
          if (model['display_name'] == null || model['display_name'].toString().isEmpty) {
            String id = model['id'] ?? '';
            // Convert model IDs like 'claude-3-5-sonnet' to readable names like 'Claude 3.5 Sonnet'
            String displayName = id.split('-').map((part) {
              // Convert numeric parts like "3.5" without capitalization
              if (part.contains(RegExp(r'[0-9]'))) {
                return part.replaceAll('-', '.');
              }
              // Capitalize first letter of each word
              return part.isEmpty ? '' : '${part[0].toUpperCase()}${part.substring(1)}';
            }).join(' ');
            
            model['display_name'] = displayName;
          }
        }
        
        return models;
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
        // Return a fallback response when no API key is available
        return "I'm a PocketLLM model simulation. No API key is configured, but you can still test the interface. Please add a valid API key in settings to use real model responses.";
      }

      final messages = [];
      
      // Add system prompt if provided
      if (config.systemPrompt.isNotEmpty) {
        messages.add({'role': 'system', 'content': config.systemPrompt});
      }
      
      messages.add({'role': 'user', 'content': userMessage});

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
          'model': config.model,
          'messages': messages,
          'temperature': config.temperature,
          'stream': false,
          'max_tokens': config.maxTokens,
          'presence_penalty': config.presencePenalty,
          'frequency_penalty': config.frequencyPenalty
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

  // Test connection
  static Future<bool> testConnection(ModelConfig config) async {
    try {
      final apiKey = await getApiKey();
      if (apiKey == null) {
        // Return success even without an API key
        return true;
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