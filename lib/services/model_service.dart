import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'pocket_llm_service.dart';
import '../component/models.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import 'remote_model_service.dart';

// Service to manage model configurations
class ModelService {
  static final ModelService _instance = ModelService._internal();
  factory ModelService() => _instance;
  ModelService._internal();

  static const String _modelsKey = 'saved_models';
  static const String _defaultModelKey = 'default_model';

  final RemoteModelService _remoteModelService = RemoteModelService();
  
  // Get all saved model configurations
  Future<List<ModelConfig>> getSavedModels({bool refreshRemote = true}) async {
    if (refreshRemote) {
      try {
        final remoteModels = await _remoteModelService.getModels();
        await _cacheModels(remoteModels);
        return remoteModels;
      } catch (e) {
        debugPrint('Remote model fetch failed, falling back to cache: $e');
      }
    }

    return await _loadCachedModels();
  }
  
  // Save a new model configuration
  Future<void> saveModel(ModelConfig model) async {
    try {
      final sharedSettings = <String, dynamic>{};
      if (model.systemPrompt != null && model.systemPrompt!.isNotEmpty) {
        sharedSettings['systemPrompt'] = model.systemPrompt;
      }
      sharedSettings['temperature'] = model.temperature;
      if (model.maxTokens != null) {
        sharedSettings['maxTokens'] = model.maxTokens;
      }
      if (model.topP != null) {
        sharedSettings['topP'] = model.topP;
      }
      if (model.presencePenalty != null) {
        sharedSettings['presencePenalty'] = model.presencePenalty;
      }
      if (model.frequencyPenalty != null) {
        sharedSettings['frequencyPenalty'] = model.frequencyPenalty;
      }

      await _remoteModelService.importModels(
        provider: model.provider,
        selections: [
          AvailableModelOption(
            id: model.model,
            name: model.name,
            provider: model.provider.backendId,
            description: model.metadata?['description'] ?? model.systemPrompt,
            metadata: model.metadata ?? model.additionalParams,
          )
        ],
        providerId: model.providerId,
        sharedSettings: sharedSettings,
      );
      final remoteModels = await _remoteModelService.getModels();
      await _cacheModels(remoteModels);
      await _setDefaultIfFirstModel(remoteModels.isNotEmpty ? remoteModels.first.id : model.id);
    } catch (e) {
      debugPrint('Remote saveModel failed, storing locally: $e');
      await _saveModelLocally(model);
    }
  }

  // Delete a model configuration
  Future<void> deleteModel(String modelId) async {
    try {
      await _remoteModelService.deleteModel(modelId);
      final remoteModels = await _remoteModelService.getModels();
      await _cacheModels(remoteModels);
    } catch (e) {
      debugPrint('Remote deleteModel failed, updating cache locally: $e');
      final prefs = await SharedPreferences.getInstance();
      final cached = await _loadCachedModels();
      cached.removeWhere((m) => m.id == modelId);
      final modelJsonList = cached.map((m) => json.encode(m.toJson())).toList();
      await prefs.setStringList(_modelsKey, modelJsonList);
    }

    final defaultId = await getDefaultModel();
    if (defaultId == modelId) {
      final cached = await _loadCachedModels();
      if (cached.isNotEmpty) {
        await setDefaultModel(cached.first.id);
      }
    }
  }

  Future<void> _cacheModels(List<ModelConfig> models) async {
    final prefs = await SharedPreferences.getInstance();
    final modelJsonList = models.map((m) => json.encode(m.toJson())).toList();
    await prefs.setStringList(_modelsKey, modelJsonList);
  }

  Future<List<ModelConfig>> _loadCachedModels() async {
    final prefs = await SharedPreferences.getInstance();
    final savedModelsJson = prefs.getStringList(_modelsKey) ?? [];

    final List<ModelConfig> models = [];
    for (final modelJson in savedModelsJson) {
      try {
        final Map<String, dynamic> modelMap = json.decode(modelJson);
        models.add(ModelConfig.fromJson(modelMap));
      } catch (e) {
        debugPrint('Error parsing cached model: $e');
      }
    }
    return models;
  }

  Future<void> _saveModelLocally(ModelConfig model) async {
    final prefs = await SharedPreferences.getInstance();
    final models = await _loadCachedModels();

    bool modelExists = false;
    for (int i = 0; i < models.length; i++) {
      if (models[i].id == model.id) {
        models[i] = model.copyWith(updatedAt: DateTime.now());
        modelExists = true;
        break;
      }
    }

    if (!modelExists) {
      model = model.copyWith(
        id: model.id.isEmpty ? const Uuid().v4() : model.id,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      models.add(model);
    }

    await _cacheModels(models);
    await _setDefaultIfFirstModel(model.id);
  }

  Future<List<ProviderConnection>> getProviders() async {
    try {
      return await _remoteModelService.getProviders();
    } catch (e) {
      debugPrint('Failed to load providers: $e');
      return [];
    }
  }

  Future<ProviderConnection> activateProvider({
    required ModelProvider provider,
    String? apiKey,
    String? baseUrl,
    Map<String, dynamic>? metadata,
  }) {
    return _remoteModelService.activateProvider(
      provider: provider,
      apiKey: apiKey,
      baseUrl: baseUrl,
      metadata: metadata,
    );
  }

  Future<ProviderConnection> updateProvider({
    required ModelProvider provider,
    String? apiKey,
    String? baseUrl,
    Map<String, dynamic>? metadata,
    bool? isActive,
    bool removeApiKey = false,
  }) {
    return _remoteModelService.updateProvider(
      provider: provider,
      apiKey: apiKey,
      baseUrl: baseUrl,
      metadata: metadata,
      isActive: isActive,
      removeApiKey: removeApiKey,
    );
  }

  Future<void> deactivateProvider(ModelProvider provider) {
    return _remoteModelService.deactivateProvider(provider);
  }

  Future<List<AvailableModelOption>> getProviderModels({
    required ModelProvider provider,
    String? search,
  }) {
    return _remoteModelService.getProviderModels(
      provider: provider,
      search: search,
    );
  }

  Future<List<ModelConfig>> importModelsFromProvider({
    required ModelProvider provider,
    required List<AvailableModelOption> selections,
    String? providerId,
    Map<String, dynamic>? sharedSettings,
  }) async {
    final importedModels = await _remoteModelService.importModels(
      provider: provider,
      selections: selections,
      providerId: providerId,
      sharedSettings: sharedSettings,
    );
    try {
      final remoteModels = await _remoteModelService.getModels();
      await _cacheModels(remoteModels);
      if (remoteModels.isNotEmpty) {
        await _setDefaultIfFirstModel(remoteModels.first.id);
      }
    } catch (e) {
      debugPrint('Failed to refresh models after import: $e');
    }
    return importedModels;
  }
  
  // Set the selected model
  Future<void> setDefaultModel(String modelId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_defaultModelKey, modelId);
  }
  
  // Get the selected model
  Future<String?> getDefaultModel() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_defaultModelKey);
  }
  
  // Add alias method for getDefaultModel
  Future<String?> getDefaultModelId() async {
    return getDefaultModel();
  }
  
  // Get the selected model
  Future<ModelConfig?> getDefaultModelConfig() async {
    final defaultId = await getDefaultModel();
    if (defaultId == null) return null;
    
    final models = await getSavedModels();
    if (models.isEmpty) return null;
    
    try {
      return models.firstWhere(
        (model) => model.id == defaultId,
        orElse: () => models.first,
      );
    } catch (e) {
      return models.first;
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
          
        case ModelProvider.googleAI:
          final response = await http.get(
            Uri.parse('${config.baseUrl}/v1beta/models'),
            headers: {
              'Authorization': 'Bearer ${config.apiKey}',
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
      final defaultId = await getDefaultModel();
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
    // For PocketLLM, use a placeholder value instead of actual URL
    if (provider == ModelProvider.pocketLLM) {
      return "[SECURED API ENDPOINT]"; // Use a placeholder instead of actual URL
    }
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
    String baseUrl = provider.defaultBaseUrl;
    
    // For PocketLLM, use a placeholder value instead of actual URL
    if (provider == ModelProvider.pocketLLM) {
      baseUrl = "[SECURED API ENDPOINT]"; // Use a placeholder instead of actual URL
    }
    
    String defaultModelName = provider == ModelProvider.googleAI ? "gemini-1.5-pro" : "default";
    
    final model = ModelConfig(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: '${provider.displayName} Default',
      provider: provider,
      baseUrl: baseUrl,
      model: defaultModelName,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    
    await saveModel(model);
    await setDefaultModel(model.id);
    return model;
  }

  // Private helper method to set default model if it's the first one
  Future<void> _setDefaultIfFirstModel(String modelId) async {
    final models = await getSavedModels();
    final defaultId = await getDefaultModel();
    
    if (models.length == 1 || defaultId == null) {
      await setDefaultModel(modelId);
    }
  }

  Future<ModelConfig?> getModelById(String modelId) async {
    final models = await getSavedModels();
    try {
      return models.firstWhere((model) => model.id == modelId);
    } catch (e) {
      return null;
    }
  }
}