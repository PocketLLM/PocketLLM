import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'model_service.dart';
import '../component/models.dart';
import 'error_service.dart';
import 'network_service.dart';

enum ModelHealthStatus {
  healthy,
  unhealthy,
  unknown,
  testing,
}

class ModelHealthInfo {
  final String modelId;
  final ModelHealthStatus status;
  final DateTime lastChecked;
  final String? error;
  final Duration? responseTime;
  final Map<String, dynamic>? additionalInfo;

  ModelHealthInfo({
    required this.modelId,
    required this.status,
    required this.lastChecked,
    this.error,
    this.responseTime,
    this.additionalInfo,
  });

  ModelHealthInfo copyWith({
    ModelHealthStatus? status,
    DateTime? lastChecked,
    String? error,
    Duration? responseTime,
    Map<String, dynamic>? additionalInfo,
  }) {
    return ModelHealthInfo(
      modelId: modelId,
      status: status ?? this.status,
      lastChecked: lastChecked ?? this.lastChecked,
      error: error ?? this.error,
      responseTime: responseTime ?? this.responseTime,
      additionalInfo: additionalInfo ?? this.additionalInfo,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'modelId': modelId,
      'status': status.toString(),
      'lastChecked': lastChecked.toIso8601String(),
      'error': error,
      'responseTimeMs': responseTime?.inMilliseconds,
      'additionalInfo': additionalInfo,
    };
  }

  factory ModelHealthInfo.fromJson(Map<String, dynamic> json) {
    return ModelHealthInfo(
      modelId: json['modelId'],
      status: ModelHealthStatus.values.firstWhere(
        (e) => e.toString() == json['status'],
        orElse: () => ModelHealthStatus.unknown,
      ),
      lastChecked: DateTime.parse(json['lastChecked']),
      error: json['error'],
      responseTime: json['responseTimeMs'] != null 
          ? Duration(milliseconds: json['responseTimeMs'])
          : null,
      additionalInfo: json['additionalInfo'] != null
          ? Map<String, dynamic>.from(json['additionalInfo'])
          : null,
    );
  }
}

class ModelState extends ChangeNotifier {
  static final ModelState _instance = ModelState._internal();
  factory ModelState() => _instance;
  ModelState._internal();

  final ValueNotifier<String?> _selectedModelId = ValueNotifier<String?>(null);
  final ValueNotifier<List<ModelConfig>> _availableModels = ValueNotifier<List<ModelConfig>>([]);
  final ValueNotifier<Map<String, ModelHealthInfo>> _modelHealthStatus = ValueNotifier<Map<String, ModelHealthInfo>>({});
  
  ValueNotifier<String?> get selectedModelId => _selectedModelId;
  ValueNotifier<List<ModelConfig>> get availableModels => _availableModels;
  ValueNotifier<Map<String, ModelHealthInfo>> get modelHealthStatus => _modelHealthStatus;
  
  final ModelService _modelService = ModelService();
  final ErrorService _errorService = ErrorService();
  final NetworkService _networkService = NetworkService();
  
  Timer? _healthCheckTimer;
  bool _isInitialized = false;
  String? _fallbackModelId;
  
  // Configuration
  static const Duration _healthCheckInterval = Duration(minutes: 5);
  static const Duration _healthCheckTimeout = Duration(seconds: 10);
  static const int _maxRetries = 3;

  bool get isInitialized => _isInitialized;
  String? get fallbackModelId => _fallbackModelId;
  
  ModelConfig? get selectedModel {
    final selectedId = _selectedModelId.value;
    if (selectedId == null) return null;
    
    try {
      return _availableModels.value.firstWhere((model) => model.id == selectedId);
    } catch (e) {
      return null;
    }
  }

  ModelHealthInfo? getModelHealth(String modelId) {
    return _modelHealthStatus.value[modelId];
  }

  List<ModelConfig> get healthyModels {
    return _availableModels.value.where((model) {
      final health = _modelHealthStatus.value[model.id];
      return health?.status == ModelHealthStatus.healthy;
    }).toList();
  }

  Future<void> init() async {
    try {
      debugPrint('ModelState: Initializing enhanced model state...');
      
      // Load available models
      await _loadAvailableModels();
      
      // Load selected model
      final selectedId = await _modelService.getDefaultModel();
      debugPrint('ModelState: Initialized with selected model ID: $selectedId');
      
      if (selectedId != null && selectedId.isNotEmpty) {
        await _setSelectedModelInternal(selectedId, validateHealth: true);
      }
      
      // Set up fallback model
      await _setupFallbackModel();
      
      // Start health monitoring
      _startHealthMonitoring();
      
      _isInitialized = true;
      debugPrint('ModelState: Enhanced initialization complete');
      
    } catch (e, stackTrace) {
      await _errorService.logError(
        'ModelState initialization failed: $e',
        stackTrace,
        type: ErrorType.initialization,
        context: 'ModelState.init',
      );
      debugPrint('ModelState: Error initializing: $e');
    }
  }

  Future<void> _loadAvailableModels() async {
    try {
      final models = await _modelService.getSavedModels();
      _availableModels.value = models;
      
      // Initialize health status for all models
      final healthMap = <String, ModelHealthInfo>{};
      for (final model in models) {
        healthMap[model.id] = ModelHealthInfo(
          modelId: model.id,
          status: ModelHealthStatus.unknown,
          lastChecked: DateTime.now(),
        );
      }
      _modelHealthStatus.value = healthMap;
      
      debugPrint('ModelState: Loaded ${models.length} available models');
    } catch (e, stackTrace) {
      await _errorService.logError(
        'Failed to load available models: $e',
        stackTrace,
        type: ErrorType.unknown,
        context: 'ModelState._loadAvailableModels',
      );
    }
  }

  Future<void> _setupFallbackModel() async {
    try {
      final models = _availableModels.value;
      if (models.isEmpty) return;
      
      // Prefer local models (Ollama) as fallback
      final localModels = models.where((m) => m.provider == ModelProvider.ollama).toList();
      if (localModels.isNotEmpty) {
        _fallbackModelId = localModels.first.id;
      } else {
        _fallbackModelId = models.first.id;
      }
      
      debugPrint('ModelState: Set fallback model to: $_fallbackModelId');
    } catch (e) {
      debugPrint('ModelState: Error setting up fallback model: $e');
    }
  }

  Future<void> setSelectedModel(String id) async {
    try {
      await _setSelectedModelInternal(id, validateHealth: true);
    } catch (e, stackTrace) {
      await _errorService.logError(
        'Failed to set selected model: $e',
        stackTrace,
        type: ErrorType.unknown,
        context: 'ModelState.setSelectedModel',
      );
      debugPrint('ModelState: Error setting selected model: $e');
    }
  }

  Future<void> _setSelectedModelInternal(String id, {bool validateHealth = false}) async {
    debugPrint('ModelState: Setting selected model ID to: $id');
    
    // Validate model exists
    final models = _availableModels.value;
    final modelExists = models.any((model) => model.id == id);
    
    if (!modelExists) {
      debugPrint('ModelState: Warning - Selected model ID $id does not exist in saved models');
      await _handleModelNotFound(id);
      return;
    }
    
    final model = models.firstWhere((model) => model.id == id);
    
    // Validate model health if requested
    if (validateHealth) {
      final isHealthy = await _validateModelHealth(model);
      if (!isHealthy) {
        debugPrint('ModelState: Model $id failed health check, attempting fallback');
        await _handleUnhealthyModel(id);
        return;
      }
    }
    
    // Set the model
    await _modelService.setDefaultModel(id);
    _selectedModelId.value = id;
    
    debugPrint('ModelState: Now using model: ${model.name} (${model.provider})');
    notifyListeners();
  }

  Future<void> _handleModelNotFound(String modelId) async {
    await _errorService.logError(
      'Selected model not found: $modelId',
      null,
      type: ErrorType.unknown,
      severity: ErrorSeverity.medium,
      context: 'ModelState._handleModelNotFound',
    );
    
    // Try fallback
    if (_fallbackModelId != null && _fallbackModelId != modelId) {
      debugPrint('ModelState: Using fallback model: $_fallbackModelId');
      await _setSelectedModelInternal(_fallbackModelId!, validateHealth: false);
    } else {
      // Clear selection if no fallback available
      _selectedModelId.value = null;
      notifyListeners();
    }
  }

  Future<void> _handleUnhealthyModel(String modelId) async {
    await _errorService.logError(
      'Model health check failed: $modelId',
      null,
      type: ErrorType.unknown,
      severity: ErrorSeverity.medium,
      context: 'ModelState._handleUnhealthyModel',
    );
    
    // Try to find a healthy alternative
    final healthyAlternatives = healthyModels;
    if (healthyAlternatives.isNotEmpty) {
      final alternative = healthyAlternatives.first;
      debugPrint('ModelState: Using healthy alternative: ${alternative.id}');
      await _setSelectedModelInternal(alternative.id, validateHealth: false);
    } else if (_fallbackModelId != null && _fallbackModelId != modelId) {
      debugPrint('ModelState: Using fallback model: $_fallbackModelId');
      await _setSelectedModelInternal(_fallbackModelId!, validateHealth: false);
    } else {
      // Keep the unhealthy model but log the issue
      await _modelService.setDefaultModel(modelId);
      _selectedModelId.value = modelId;
      notifyListeners();
    }
  }

  Future<bool> _validateModelHealth(ModelConfig model) async {
    if (!_networkService.isOnline) {
      // Skip validation if offline
      return true;
    }
    
    try {
      debugPrint('ModelState: Validating health for model: ${model.name}');
      
      final stopwatch = Stopwatch()..start();
      final isHealthy = await _performHealthCheck(model);
      stopwatch.stop();
      
      final healthInfo = ModelHealthInfo(
        modelId: model.id,
        status: isHealthy ? ModelHealthStatus.healthy : ModelHealthStatus.unhealthy,
        lastChecked: DateTime.now(),
        responseTime: stopwatch.elapsed,
        error: isHealthy ? null : 'Health check failed',
      );
      
      _updateModelHealth(model.id, healthInfo);
      
      return isHealthy;
    } catch (e, stackTrace) {
      await _errorService.logError(
        'Model health validation failed for ${model.id}: $e',
        stackTrace,
        type: ErrorType.unknown,
        context: 'ModelState._validateModelHealth',
      );
      
      _updateModelHealth(model.id, ModelHealthInfo(
        modelId: model.id,
        status: ModelHealthStatus.unhealthy,
        lastChecked: DateTime.now(),
        error: e.toString(),
      ));
      
      return false;
    }
  }

  Future<bool> _performHealthCheck(ModelConfig model) async {
    switch (model.provider) {
      case ModelProvider.ollama:
        return await _checkOllamaHealth(model);
      case ModelProvider.openAI:
        return await _checkOpenAIHealth(model);
      case ModelProvider.anthropic:
        return await _checkAnthropicHealth(model);
      case ModelProvider.lmStudio:
        return await _checkLMStudioHealth(model);
      case ModelProvider.pocketLLM:
        return await _checkPocketLLMHealth(model);
      case ModelProvider.mistral:
        return await _checkMistralHealth(model);
      case ModelProvider.deepseek:
        return await _checkDeepSeekHealth(model);
      case ModelProvider.googleAI:
        return await _checkGoogleAIHealth(model);
      default:
        return false;
    }
  }

  Future<bool> _checkOllamaHealth(ModelConfig model) async {
    try {
      final response = await http.get(
        Uri.parse('${model.baseUrl}/api/tags'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(_healthCheckTimeout);
      
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<bool> _checkOpenAIHealth(ModelConfig model) async {
    try {
      final response = await http.get(
        Uri.parse('https://api.openai.com/v1/models'),
        headers: {
          'Authorization': 'Bearer ${model.apiKey}',
          'Content-Type': 'application/json',
        },
      ).timeout(_healthCheckTimeout);
      
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<bool> _checkAnthropicHealth(ModelConfig model) async {
    try {
      // Simple ping to Anthropic API
      final response = await http.post(
        Uri.parse('https://api.anthropic.com/v1/messages'),
        headers: {
          'x-api-key': model.apiKey ?? '',
          'Content-Type': 'application/json',
          'anthropic-version': '2023-06-01',
        },
        body: '{"model":"${model.model}","max_tokens":1,"messages":[{"role":"user","content":"test"}]}',
      ).timeout(_healthCheckTimeout);
      
      // Accept both 200 and 400 (bad request) as healthy responses
      return response.statusCode == 200 || response.statusCode == 400;
    } catch (e) {
      return false;
    }
  }

  Future<bool> _checkLMStudioHealth(ModelConfig model) async {
    try {
      final response = await http.get(
        Uri.parse('${model.baseUrl}/v1/models'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(_healthCheckTimeout);
      
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<bool> _checkPocketLLMHealth(ModelConfig model) async {
    try {
      final response = await http.get(
        Uri.parse('${model.baseUrl}/health'),
        headers: {
          'Authorization': 'Bearer ${model.apiKey}',
          'Content-Type': 'application/json',
        },
      ).timeout(_healthCheckTimeout);
      
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<bool> _checkMistralHealth(ModelConfig model) async {
    try {
      final response = await http.get(
        Uri.parse('https://api.mistral.ai/v1/models'),
        headers: {
          'Authorization': 'Bearer ${model.apiKey}',
          'Content-Type': 'application/json',
        },
      ).timeout(_healthCheckTimeout);
      
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<bool> _checkDeepSeekHealth(ModelConfig model) async {
    try {
      final response = await http.get(
        Uri.parse('https://api.deepseek.com/v1/models'),
        headers: {
          'Authorization': 'Bearer ${model.apiKey}',
          'Content-Type': 'application/json',
        },
      ).timeout(_healthCheckTimeout);
      
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<bool> _checkGoogleAIHealth(ModelConfig model) async {
    try {
      final response = await http.get(
        Uri.parse('https://generativelanguage.googleapis.com/v1/models?key=${model.apiKey}'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(_healthCheckTimeout);
      
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  void _updateModelHealth(String modelId, ModelHealthInfo healthInfo) {
    final currentHealth = Map<String, ModelHealthInfo>.from(_modelHealthStatus.value);
    currentHealth[modelId] = healthInfo;
    _modelHealthStatus.value = currentHealth;
    notifyListeners();
  }

  void _startHealthMonitoring() {
    _healthCheckTimer?.cancel();
    _healthCheckTimer = Timer.periodic(_healthCheckInterval, (_) {
      _performPeriodicHealthChecks();
    });
    
    debugPrint('ModelState: Started health monitoring (${_healthCheckInterval.inMinutes} min intervals)');
  }

  Future<void> _performPeriodicHealthChecks() async {
    if (!_networkService.isOnline) {
      debugPrint('ModelState: Skipping health checks - offline');
      return;
    }
    
    debugPrint('ModelState: Performing periodic health checks...');
    
    final models = _availableModels.value;
    final futures = models.map((model) async {
      try {
        await _validateModelHealth(model);
      } catch (e) {
        debugPrint('ModelState: Health check failed for ${model.id}: $e');
      }
    });
    
    await Future.wait(futures);
    debugPrint('ModelState: Periodic health checks completed');
  }

  Future<void> forceHealthCheck({String? modelId}) async {
    if (modelId != null) {
      // Check specific model
      final model = _availableModels.value.firstWhere(
        (m) => m.id == modelId,
        orElse: () => throw ArgumentError('Model not found: $modelId'),
      );
      
      _updateModelHealth(modelId, ModelHealthInfo(
        modelId: modelId,
        status: ModelHealthStatus.testing,
        lastChecked: DateTime.now(),
      ));
      
      await _validateModelHealth(model);
    } else {
      // Check all models
      await _performPeriodicHealthChecks();
    }
  }

  Future<void> refreshAvailableModels() async {
    await _loadAvailableModels();
    await _setupFallbackModel();
    
    // Re-validate selected model if it exists
    final selectedId = _selectedModelId.value;
    if (selectedId != null) {
      final modelExists = _availableModels.value.any((m) => m.id == selectedId);
      if (!modelExists) {
        await _handleModelNotFound(selectedId);
      }
    }
  }

  Future<void> clearSelectedModel() async {
    try {
      debugPrint('ModelState: Clearing selected model');
      await _modelService.setDefaultModel('');
      _selectedModelId.value = null;
      notifyListeners();
    } catch (e, stackTrace) {
      await _errorService.logError(
        'Failed to clear selected model: $e',
        stackTrace,
        type: ErrorType.unknown,
        context: 'ModelState.clearSelectedModel',
      );
      debugPrint('ModelState: Error clearing selected model: $e');
    }
  }

  Map<String, dynamic> getHealthSummary() {
    final health = _modelHealthStatus.value;
    final total = health.length;
    final healthy = health.values.where((h) => h.status == ModelHealthStatus.healthy).length;
    final unhealthy = health.values.where((h) => h.status == ModelHealthStatus.unhealthy).length;
    final unknown = health.values.where((h) => h.status == ModelHealthStatus.unknown).length;
    final testing = health.values.where((h) => h.status == ModelHealthStatus.testing).length;
    
    return {
      'total': total,
      'healthy': healthy,
      'unhealthy': unhealthy,
      'unknown': unknown,
      'testing': testing,
      'lastCheck': health.values.isNotEmpty 
          ? health.values.map((h) => h.lastChecked).reduce((a, b) => a.isAfter(b) ? a : b).toIso8601String()
          : null,
    };
  }

  @override
  void dispose() {
    _healthCheckTimer?.cancel();
    _selectedModelId.dispose();
    _availableModels.dispose();
    _modelHealthStatus.dispose();
    super.dispose();
  }
}