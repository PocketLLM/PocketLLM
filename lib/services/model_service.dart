import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'pocket_llm_service.dart';
import '../component/models.dart';
import 'package:flutter/foundation.dart';
import 'remote_model_service.dart';

// Service to manage model configurations
class ModelService {
  static final ModelService _instance = ModelService._internal();
  factory ModelService() => _instance;
  ModelService._internal();

  static const String _defaultModelKey = 'default_model';

  final RemoteModelService _remoteModelService = RemoteModelService();
  List<ModelConfig> _cachedModels = [];

  // Get all saved model configurations
  Future<List<ModelConfig>> getSavedModels({bool refreshRemote = true}) async {
    if (!refreshRemote && _cachedModels.isNotEmpty) {
      return _cachedModels;
    }

    try {
      final remoteModels = await _remoteModelService.getModels();
      await _ensureDefaultModel(remoteModels);
      return _cachedModels;
    } catch (e) {
      debugPrint('Remote model fetch failed: $e');
      return _cachedModels;
    }
  }
  
  // Save a new model configuration
  Future<void> saveModel(ModelConfig model) async {
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

    try {
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
      await _ensureDefaultModel(remoteModels);
    } catch (e) {
      debugPrint('Remote saveModel failed: $e');
      rethrow;
    }
  }

  // Delete a model configuration
  Future<void> deleteModel(String modelId) async {
    try {
      await _remoteModelService.deleteModel(modelId);
      final remainingModels = await _remoteModelService.getModels();
      await _ensureDefaultModel(remainingModels);
    } catch (e) {
      debugPrint('Failed to delete model: $e');
      rethrow;
    }
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
      await _ensureDefaultModel(remoteModels);
    } catch (e) {
      debugPrint('Failed to refresh models after import: $e');
    }
    return importedModels;
  }
  
  // Set the selected model
  Future<void> setDefaultModel(String modelId) async {
    final prefs = await SharedPreferences.getInstance();
    if (modelId.isEmpty) {
      await prefs.remove(_defaultModelKey);
    } else {
      await prefs.setString(_defaultModelKey, modelId);
    }

    if (_cachedModels.isEmpty) {
      return;
    }

    _cachedModels = _cachedModels
        .map(
          (model) => model.copyWith(
            isDefault: modelId.isNotEmpty && model.id == modelId,
          ),
        )
        .toList();
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

        case ModelProvider.openRouter:
          final baseUri = Uri.parse(config.baseUrl);
          final response = await http.get(
            baseUri.resolve('models'),
            headers: {
              'Authorization': 'Bearer ${config.apiKey}',
              'Content-Type': 'application/json',
            },
          );

          if (response.statusCode == 200) {
            return true;
          }

          final fallbackResponse = await http.get(
            baseUri.resolve('v1/models'),
            headers: {
              'Authorization': 'Bearer ${config.apiKey}',
              'Content-Type': 'application/json',
            },
          );

          return fallbackResponse.statusCode == 200;

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

  Future<void> _ensureDefaultModel(List<ModelConfig> models) async {
    final prefs = await SharedPreferences.getInstance();

    if (models.isEmpty) {
      await prefs.remove(_defaultModelKey);
      _cachedModels = [];
      return;
    }

    final storedDefaultId = prefs.getString(_defaultModelKey);

    String? resolvedDefaultId;
    for (final model in models) {
      if (model.isDefault) {
        resolvedDefaultId = model.id;
        break;
      }
    }

    if (resolvedDefaultId == null && storedDefaultId != null) {
      for (final model in models) {
        if (model.id == storedDefaultId) {
          resolvedDefaultId = model.id;
          break;
        }
      }
    }

    resolvedDefaultId ??= models.first.id;

    if (storedDefaultId != resolvedDefaultId) {
      await prefs.setString(_defaultModelKey, resolvedDefaultId);
    }

    _cachedModels = models
        .map(
          (model) => model.copyWith(
            isDefault: model.id == resolvedDefaultId,
          ),
        )
        .toList();
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