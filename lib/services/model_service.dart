import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ollama_dart/ollama_dart.dart';
import 'pocket_llm_service.dart';
import 'auth_service.dart';
import '../component/models.dart';
import 'package:flutter/foundation.dart';

// Service to manage model configurations
class ModelService {
  static const String _modelsKey = 'saved_models';
  static const String _defaultModelKey = 'default_model';
  
  // Default Ollama URL
  static const String defaultOllamaUrl = 'http://localhost:11434';
  
  static const String _apiUrl = 'https://api.sree.shop/v1/models';
  
  // Get all saved model configurations
  Future<List<ModelConfig>> getSavedModels() async {
    final prefs = await SharedPreferences.getInstance();
    final modelsJson = prefs.getStringList(_modelsKey) ?? [];
    return modelsJson.map((json) => ModelConfig.fromJson(jsonDecode(json))).toList();
  }
  
  // Save a new model configuration
  Future<void> saveModel(ModelConfig model) async {
    final prefs = await SharedPreferences.getInstance();
    final models = await getSavedModels();
    
    // Update existing model or add new one
    final index = models.indexWhere((m) => m.id == model.id);
    if (index != -1) {
      models[index] = model;
    } else {
      models.add(model);
    }

    final modelsJson = models.map((m) => jsonEncode(m.toJson())).toList();
    await prefs.setStringList(_modelsKey, modelsJson);
  }
  
  // Delete a model configuration
  Future<void> deleteModel(String modelId) async {
    final prefs = await SharedPreferences.getInstance();
    final models = await getSavedModels();
    models.removeWhere((m) => m.id == modelId);
    
    final modelsJson = models.map((m) => jsonEncode(m.toJson())).toList();
    await prefs.setStringList(_modelsKey, modelsJson);
    
    // If deleted model was default, clear default model
    final defaultModelId = await getDefaultModelId();
    if (defaultModelId == modelId) {
      await prefs.remove(_defaultModelKey);
    }
  }
  
  // Set the selected model
  Future<void> setDefaultModel(String modelId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_defaultModelKey, modelId);
  }
  
  // Get the selected model
  Future<String?> getDefaultModelId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_defaultModelKey);
  }
  
  // Get the selected model
  Future<ModelConfig?> getDefaultModel() async {
    final defaultId = await getDefaultModelId();
    if (defaultId == null) return null;
    
    final models = await getSavedModels();
    try {
      return models.firstWhere((m) => m.id == defaultId);
    } catch (e) {
      // If no model is found, return null
      return null;
    }
  }
  
  // Get available models from Ollama
  Future<List<String>> getOllamaModels(String baseUrl) async {
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
  Future<bool> testConnection(ModelConfig config) async {
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
  Future<void> initializeDefaultConfigs() async {
    final configs = await getSavedModels();
    
    // Create a PocketLLM default config if it doesn't exist
    if (!configs.any((c) => c.provider == ModelProvider.pocketLLM)) {
      // Initialize PocketLLM API key securely
      await PocketLLMService.initializeApiKey();
      
      // Add PocketLLM default config
      final pocketLLMConfig = await createDefaultModel(ModelProvider.pocketLLM);
      await saveModel(pocketLLMConfig);
      
      // Set as default if no default exists
      final defaultId = await getDefaultModelId();
      if (defaultId == null) {
        await setDefaultModel(pocketLLMConfig.id);
      }
    }
    
    // Create an Ollama default config if it doesn't exist
    if (!configs.any((c) => c.provider == ModelProvider.ollama)) {
      final ollamaConfig = await createDefaultModel(ModelProvider.ollama);
      await saveModel(ollamaConfig);
    }
  }

  // Get default base URL for provider
  String getDefaultBaseUrl(ModelProvider provider) {
    return provider.defaultBaseUrl;
  }

  // Get provider icon
  IconData getProviderIcon(ModelProvider provider) {
    return provider.icon;
  }

  // Get provider color
  Color getProviderColor(ModelProvider provider) {
    return provider.color;
  }

  Future<List<ModelConfig>> getFilteredModelConfigs() async {
    final List<ModelConfig> allConfigs = await getSavedModels();
    // Always return all configs, regardless of login status
    return allConfigs;
  }

  Future<ModelConfig> createDefaultModel(ModelProvider provider) async {
    final model = ModelConfig(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: '${provider.displayName} Default',
      provider: provider,
      baseUrl: provider.defaultBaseUrl,
      model: 'default',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    
    await saveModel(model);
    await setDefaultModel(model.id);
    return model;
  }
}