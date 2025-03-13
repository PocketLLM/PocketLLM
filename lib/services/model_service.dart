import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ollama_dart/ollama_dart.dart';
import 'pocket_llm_service.dart';
import 'auth_service.dart';

// Enum for model providers
enum ModelProvider {
  pocketLLM,
  ollama,
  openAI,
  anthropic,
  mistral,
  deepseek,
  lmStudio,
}

// Extension to get display name for providers
extension ModelProviderExtension on ModelProvider {
  String get displayName {
    switch (this) {
      case ModelProvider.pocketLLM:
        return 'PocketLLM';
      case ModelProvider.ollama:
        return 'Ollama';
      case ModelProvider.openAI:
        return 'OpenAI Compatible';
      case ModelProvider.anthropic:
        return 'Anthropic';
      case ModelProvider.mistral:
        return 'Mistral AI';
      case ModelProvider.deepseek:
        return 'DeepSeek';
      case ModelProvider.lmStudio:
        return 'LM Studio';
    }
  }

  String get defaultBaseUrl {
    switch (this) {
      case ModelProvider.pocketLLM:
        return 'https://api.sree.shop/v1';
      case ModelProvider.ollama:
        return 'http://localhost:11434';
      case ModelProvider.openAI:
        return 'https://api.openai.com/v1';
      case ModelProvider.anthropic:
        return 'https://api.anthropic.com';
      case ModelProvider.mistral:
        return 'https://api.mistral.ai/v1';
      case ModelProvider.deepseek:
        return 'https://api.deepseek.com/v1';
      case ModelProvider.lmStudio:
        return 'http://localhost:1234/v1';
    }
  }

  IconData get icon {
    switch (this) {
      case ModelProvider.pocketLLM:
        return Icons.smart_toy;
      case ModelProvider.ollama:
        return Icons.terminal;
      case ModelProvider.openAI:
        return Icons.auto_awesome;
      case ModelProvider.anthropic:
        return Icons.psychology;
      case ModelProvider.mistral:
        return Icons.cloud;
      case ModelProvider.deepseek:
        return Icons.search;
      case ModelProvider.lmStudio:
        return Icons.science;
    }
  }

  Color get color {
    switch (this) {
      case ModelProvider.pocketLLM:
        return Color(0xFF8B5CF6);
      case ModelProvider.ollama:
        return Colors.orange;
      case ModelProvider.openAI:
        return Colors.green;
      case ModelProvider.anthropic:
        return Colors.purple;
      case ModelProvider.mistral:
        return Colors.blue;
      case ModelProvider.deepseek:
        return Colors.teal;
      case ModelProvider.lmStudio:
        return Colors.indigo;
    }
  }
}

// Model configuration class
class ModelConfig {
  final String id;
  final String name;
  final ModelProvider provider;
  final String baseUrl;
  final String? apiKey;
  final Map<String, dynamic>? additionalParams;

  ModelConfig({
    required this.id,
    required this.name,
    required this.provider,
    required this.baseUrl,
    this.apiKey,
    this.additionalParams,
  });

  // Convert to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'provider': provider.index,
      'baseUrl': baseUrl,
      'apiKey': apiKey,
      'additionalParams': additionalParams,
    };
  }

  // Create from JSON for retrieval
  factory ModelConfig.fromJson(Map<String, dynamic> json) {
    return ModelConfig(
      id: json['id'],
      name: json['name'],
      provider: ModelProvider.values[json['provider']],
      baseUrl: json['baseUrl'],
      apiKey: json['apiKey'],
      additionalParams: json['additionalParams'],
    );
  }
}

// Service to manage model configurations
class ModelService {
  static const String _storageKey = 'model_configs';
  static const String _selectedModelKey = 'selected_model';
  
  // Default Ollama URL
  static const String defaultOllamaUrl = 'http://localhost:11434';
  
  // Get all saved model configurations
  static Future<List<ModelConfig>> getModelConfigs() async {
    final prefs = await SharedPreferences.getInstance();
    final String? configsJson = prefs.getString(_storageKey);
    
    if (configsJson == null) {
      return [];
    }
    
    final List<dynamic> configsList = jsonDecode(configsJson);
    return configsList.map((json) => ModelConfig.fromJson(json)).toList();
  }
  
  // Save a new model configuration
  static Future<void> saveModelConfig(ModelConfig config) async {
    final prefs = await SharedPreferences.getInstance();
    final List<ModelConfig> configs = await getModelConfigs();
    
    // Check if config with same ID already exists
    final existingIndex = configs.indexWhere((c) => c.id == config.id);
    if (existingIndex >= 0) {
      configs[existingIndex] = config;
    } else {
      configs.add(config);
    }
    
    final String configsJson = jsonEncode(configs.map((c) => c.toJson()).toList());
    await prefs.setString(_storageKey, configsJson);
  }
  
  // Delete a model configuration
  static Future<void> deleteModelConfig(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final List<ModelConfig> configs = await getModelConfigs();
    
    configs.removeWhere((c) => c.id == id);
    
    final String configsJson = jsonEncode(configs.map((c) => c.toJson()).toList());
    await prefs.setString(_storageKey, configsJson);
  }
  
  // Set the selected model
  static Future<void> setSelectedModel(String id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_selectedModelKey, id);
  }
  
  // Clear the selected model (when no models are available)
  static Future<void> clearSelectedModel() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_selectedModelKey);
  }
  
  // Get the selected model
  static Future<String?> getSelectedModel() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_selectedModelKey);
  }
  
  // Get available models from Ollama
  static Future<List<String>> getOllamaModels(String baseUrl) async {
    try {
      debugPrint('Fetching Ollama models from $baseUrl');
      // Use direct HTTP request instead of the client's listModels method
      final response = await http.get(
        Uri.parse('$baseUrl/api/tags'),
        headers: {
          'Content-Type': 'application/json',
        },
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final models = (data['models'] as List<dynamic>?) ?? [];
        return models.map((model) => model['name'].toString()).toList();
      } else {
        // Try the v1 API endpoint if the api/tags endpoint fails
        final v1Response = await http.get(
          Uri.parse('$baseUrl/v1/models'),
          headers: {
            'Content-Type': 'application/json',
          },
        );
        
        if (v1Response.statusCode == 200) {
          final data = jsonDecode(v1Response.body);
          final models = (data['models'] as List<dynamic>?) ?? [];
          return models.map((model) => model['name'].toString()).toList();
        }
        
        debugPrint('Failed to fetch Ollama models: ${response.statusCode} ${response.body}');
        return [];
      }
    } catch (e) {
      debugPrint('Error fetching Ollama models: $e');
      return [];
    }
  }
  
  // Test connection to model provider
  static Future<bool> testConnection(ModelConfig config) async {
    try {
      switch (config.provider) {
        case ModelProvider.pocketLLM:
          return await PocketLLMService.testConnection(config);
        
        case ModelProvider.ollama:
          // Use direct HTTP request instead of the client
          final response = await http.get(
            Uri.parse('${config.baseUrl}/api/tags'),
            headers: {
              'Content-Type': 'application/json',
            },
          );
          
          if (response.statusCode == 200) {
            return true;
          }
          
          // Try the v1 API endpoint if the api/tags endpoint fails
          final v1Response = await http.get(
            Uri.parse('${config.baseUrl}/v1/models'),
            headers: {
              'Content-Type': 'application/json',
            },
          );
          
          return v1Response.statusCode == 200;
        
        case ModelProvider.openAI:
          final response = await http.get(
            Uri.parse('${config.baseUrl}/models'),
            headers: {
              'Authorization': 'Bearer ${config.apiKey}',
              'Content-Type': 'application/json',
            },
          );
          return response.statusCode == 200;
        
        case ModelProvider.anthropic:
          final response = await http.get(
            Uri.parse('${config.baseUrl}/v1/models'),
            headers: {
              'x-api-key': config.apiKey ?? '',
              'Content-Type': 'application/json',
              'anthropic-version': '2023-06-01',
            },
          );
          return response.statusCode == 200;
        
        case ModelProvider.mistral:
          final response = await http.get(
            Uri.parse('${config.baseUrl}/models'),
            headers: {
              'Authorization': 'Bearer ${config.apiKey}',
              'Content-Type': 'application/json',
            },
          );
          return response.statusCode == 200;
        
        case ModelProvider.deepseek:
          final response = await http.get(
            Uri.parse('${config.baseUrl}/models'),
            headers: {
              'Authorization': 'Bearer ${config.apiKey}',
              'Content-Type': 'application/json',
            },
          );
          return response.statusCode == 200;
        
        case ModelProvider.lmStudio:
          // Implement LM Studio connection test
          final response = await http.get(
            Uri.parse('${config.baseUrl}/models'),
            headers: {
              'Content-Type': 'application/json',
            },
          );
          return response.statusCode == 200;
      }
    } catch (e) {
      debugPrint('Connection test failed: $e');
      return false;
    }
  }

  // Initialize default configurations
  static Future<void> initializeDefaultConfigs() async {
    final configs = await getModelConfigs();
    
    // Only add default configs if no configs exist
    if (configs.isEmpty) {
      // Initialize PocketLLM API key securely
      await PocketLLMService.initializeApiKey();
      
      // Add PocketLLM default config
      final pocketLLMConfig = PocketLLMService.createDefaultConfig();
      await saveModelConfig(pocketLLMConfig);
      await setSelectedModel(pocketLLMConfig.id);
    }
  }

  // Get default base URL for provider
  static String getDefaultBaseUrl(ModelProvider provider) {
    return provider.defaultBaseUrl;
  }

  // Get provider icon
  static IconData getProviderIcon(ModelProvider provider) {
    return provider.icon;
  }

  // Get provider color
  static Color getProviderColor(ModelProvider provider) {
    return provider.color;
  }

  static Future<List<ModelConfig>> getFilteredModelConfigs() async {
    final authService = AuthService();
    final List<ModelConfig> allConfigs = await getModelConfigs();

    if (!authService.isLoggedIn) {
      return allConfigs.where((config) => config.provider != ModelProvider.pocketLLM).toList();
    }

    return allConfigs;
  }
}