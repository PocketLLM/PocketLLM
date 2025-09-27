/// File Overview:
/// - Purpose: Client-side orchestration layer for model CRUD operations that
///   mixes backend calls with cached fallbacks.
/// - Backend Migration: Simplify to a pure data access wrapper once backend
///   persists models and selection state.
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../component/models.dart';
import 'pocket_llm_service.dart';
import 'remote_model_service.dart';

// Service to manage model configurations
class ModelService {
  static final ModelService _instance = ModelService._internal();
  factory ModelService() => _instance;
  ModelService._internal();

  final RemoteModelService _remoteModelService = RemoteModelService();

  List<ModelConfig> _cachedModels = [];
  String? _defaultModelId;
  bool _cacheInitialized = false;

  // Get all saved model configurations
  Future<List<ModelConfig>> getSavedModels({bool refreshRemote = true}) async {
    if (!_cacheInitialized) {
      refreshRemote = true;
    }

    if (refreshRemote) {
      try {
        await _refreshCache();
      } catch (e) {
        debugPrint('Remote model fetch failed, using cached data: $e');
        // Check if we have cached models to use
        if (_cachedModels.isEmpty) {
          // Show a more informative message to the user
          debugPrint('No cached models available. The app will attempt to create default local models.');
          // We'll let the calling code handle creating defaults if needed
          rethrow;
        }
      }
    }

    return List.unmodifiable(_cachedModels);
  }

  // Save a new model configuration
  Future<ModelConfig> saveModel(ModelConfig model) async {
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
      final importedModels = await _remoteModelService.importModels(
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

      await _refreshCache();

      if (importedModels.isNotEmpty) {
        return importedModels.firstWhere(
          (imported) =>
              imported.model == model.model && imported.provider == model.provider,
          orElse: () => importedModels.first,
        );
      }

      return _cachedModels.firstWhere(
        (cached) => cached.model == model.model && cached.provider == model.provider,
        orElse: () => _cachedModels.first,
      );
    } catch (e) {
      debugPrint('Remote saveModel failed: $e');
      rethrow;
    }
  }

  // Delete a model configuration
  Future<void> deleteModel(String modelId) async {
    try {
      await _remoteModelService.deleteModel(modelId);
    } catch (e) {
      debugPrint('Remote deleteModel failed: $e');
      rethrow;
    }

    await _refreshCache();
  }

  Future<List<ProviderConnection>> getProviders() async {
    try {
      final configurations = await _remoteModelService.getProviderConfigurations();
      final statuses = await _remoteModelService.getProviderStatuses();
      final configurationMap = {for (final config in configurations) config.provider: config};

      final merged = statuses.map((status) {
        final config = configurationMap[status.provider];
        return ProviderConnection(
          id: config?.id ?? '',
          provider: status.provider,
          displayName: status.displayName,
          baseUrl: config?.baseUrl ?? status.provider.defaultBaseUrl,
          isActive: status.isActive,
          hasApiKey: status.hasApiKey,
          apiKeyPreview: status.apiKeyPreview,
          metadata: config?.metadata,
          statusMessage: status.message,
        );
      }).toList();

      final knownProviders = {for (final connection in merged) connection.provider};
      for (final provider in [ModelProvider.ollama, ModelProvider.anthropic]) {
        if (knownProviders.contains(provider)) continue;
        merged.add(
          ProviderConnection(
            id: '',
            provider: provider,
            displayName: provider.displayName,
            baseUrl: provider.defaultBaseUrl,
            isActive: provider == ModelProvider.ollama,
            hasApiKey: provider == ModelProvider.ollama,
            apiKeyPreview: null,
            metadata: const {},
            statusMessage: provider == ModelProvider.ollama
                ? 'Local Ollama models are managed on this device.'
                : 'Provider configuration not yet available.',
          ),
        );
      }

      merged.sort((a, b) => a.displayName.compareTo(b.displayName));

      return merged;
    } catch (e) {
      debugPrint('Failed to load providers: $e');
      rethrow;
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

    await _refreshCache();
    return importedModels;
  }

  // Set the selected model
  Future<void> setDefaultModel(String modelId) async {
    if (!_cacheInitialized) {
      await _refreshCache();
    }

    await _remoteModelService.setDefaultModel(modelId);
    _applyDefaultLocally(modelId);
  }

  // Get the selected model
  Future<String?> getDefaultModel() async {
    if (!_cacheInitialized) {
      await _refreshCache();
    }
    return _defaultModelId;
  }

  // Add alias method for getDefaultModel
  Future<String?> getDefaultModelId() async {
    return getDefaultModel();
  }

  // Get the selected model configuration
  Future<ModelConfig?> getDefaultModelConfig() async {
    final models = await getSavedModels();
    if (models.isEmpty) {
      return null;
    }

    final defaultId = await getDefaultModel();
    if (defaultId == null) {
      return models.first;
    }

    try {
      return models.firstWhere((model) => model.id == defaultId);
    } catch (_) {
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

        case ModelProvider.groq:
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
          final response = await http.get(
            Uri.parse('${config.baseUrl}/v1/models'),
            headers: {
              'Authorization': 'Bearer ${config.apiKey}',
              'Content-Type': 'application/json',
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
      final savedConfig = await saveModel(pocketLLMConfig);

      // Set as default if no default exists
      final defaultId = await getDefaultModel();
      if (defaultId == null) {
        await setDefaultModel(savedConfig.id);
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

    return ModelConfig(
      id: '',
      name: '${provider.displayName} Default',
      provider: provider,
      baseUrl: baseUrl,
      model: defaultModelName,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  Future<ModelConfig?> getModelById(String modelId) async {
    final models = await getSavedModels(refreshRemote: false);
    try {
      return models.firstWhere((model) => model.id == modelId);
    } catch (_) {
      return null;
    }
  }

  Future<void> _refreshCache() async {
    try {
      final models = await _remoteModelService.getModels();
      await _applyCache(models);
    } catch (e) {
      // Provide a more user-friendly error message
      if (e.toString().contains('Failed host lookup') || 
          e.toString().contains('SocketException')) {
        debugPrint('Unable to connect to the model server. Using local models only.');
      }
      rethrow;
    }
  }

  Future<void> _applyCache(List<ModelConfig> models) async {
    _cachedModels = List<ModelConfig>.from(models);
    _cacheInitialized = true;

    String? remoteDefaultId;
    for (final model in _cachedModels) {
      if (model.isDefault) {
        remoteDefaultId = model.id;
        break;
      }
    }

    if (remoteDefaultId != null) {
      _applyDefaultLocally(remoteDefaultId);
      return;
    }

    if (_cachedModels.isEmpty) {
      _defaultModelId = null;
      return;
    }

    final fallbackId = _cachedModels.first.id;
    try {
      await _remoteModelService.setDefaultModel(fallbackId);
    } catch (e) {
      debugPrint('Failed to set default model remotely: $e');
    }
    _applyDefaultLocally(fallbackId);
  }

  void _applyDefaultLocally(String modelId) {
    _defaultModelId = modelId;
    _cachedModels = _cachedModels
        .map((model) => model.copyWith(isDefault: model.id == modelId))
        .toList();
  }
}
