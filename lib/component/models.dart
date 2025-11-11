/// File Overview:
/// - Purpose: Shared data models used across the frontend, including message
///   history and provider metadata with some hardcoded defaults.
/// - Backend Migration: Review all classes; many fields (e.g., provider lists,
///   static enums) should align with backend contracts instead of local copies.
import '../services/model_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'dart:convert';

class AIModel {
  final String id;
  final String description;
  final String provider;
  final List<String> parameterVariants;
  final int downloads;
  final int comments;
  final DateTime releaseDate;
  final String? downloadUrl;
  final String? providerUrl;
  final List<String> tools;

  // Add a getter for name that returns the id
  String get name => id;

  AIModel({
    required this.id,
    required this.provider,
    required this.description,
    required this.parameterVariants,
    required this.releaseDate,
    this.downloads = 0,
    this.comments = 0,
    this.downloadUrl,
    this.providerUrl,
    this.tools = const [],
  });
}

class ModelsRepository {
  static Future<List<AIModel>> getAvailableModels() async {
    return [];
  }
}

class SearchResult {
  final String title;
  final String url;
  final String snippet;
  final DateTime? publishedDate;
  
  SearchResult({
    required this.title,
    required this.url,
    required this.snippet,
    this.publishedDate,
  });
  
  // Add fromJson and toJson methods for serialization
  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'url': url,
      'snippet': snippet,
      'publishedDate': publishedDate?.toIso8601String(),
    };
  }
  
  factory SearchResult.fromJson(Map<String, dynamic> json) {
    return SearchResult(
      title: json['title'],
      url: json['url'],
      snippet: json['snippet'],
      publishedDate: json['publishedDate'] != null
          ? DateTime.parse(json['publishedDate'])
          : null,
    );
  }
}

class Message {
  final String? id;
  String content;
  final bool isUser;
  final DateTime timestamp;
  bool isThinking;
  final bool isStreaming;
  final bool isError;
  final Map<String, dynamic>? metadata;
  final List<SearchResult>? sources;

  Message({
    this.id,
    required this.content,
    required this.isUser,
    required this.timestamp,
    this.isThinking = false,
    this.isStreaming = false,
    this.isError = false,
    this.metadata,
    this.sources,
  });

  // Add fromJson and toJson methods for serialization
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'content': content,
      'isUser': isUser,
      'timestamp': timestamp.toIso8601String(),
      'isThinking': isThinking,
      'isStreaming': isStreaming,
      'isError': isError,
      'metadata': metadata,
      'sources': sources?.map((s) => s.toJson()).toList(),
    };
  }

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id']?.toString(),
      content: json['content'] ?? '',
      isUser: json['isUser'] ?? false,
      timestamp: json['timestamp'] != null 
          ? DateTime.parse(json['timestamp']) 
          : DateTime.now(),
      isThinking: json['isThinking'] ?? false,
      isStreaming: json['isStreaming'] ?? false,
      isError: json['isError'] ?? false,
      metadata: json['metadata'] is Map<String, dynamic>
          ? Map<String, dynamic>.from(json['metadata'])
          : null,
      sources: json['sources'] != null
          ? (json['sources'] as List).map((s) => SearchResult.fromJson(s as Map<String, dynamic>)).toList()
          : null,
    );
  }

  // Create a copy of this message with updated properties
  Message copyWith({
    String? id,
    String? content,
    bool? isUser,
    DateTime? timestamp,
    bool? isThinking,
    bool? isStreaming,
    bool? isError,
    Map<String, dynamic>? metadata,
    List<SearchResult>? sources,
  }) {
    return Message(
      id: id ?? this.id,
      content: content ?? this.content,
      isUser: isUser ?? this.isUser,
      timestamp: timestamp ?? this.timestamp,
      isThinking: isThinking ?? this.isThinking,
      isStreaming: isStreaming ?? this.isStreaming,
      isError: isError ?? this.isError,
      metadata: metadata ?? this.metadata,
      sources: sources ?? this.sources,
    );
  }
}

// Enum for model providers
enum ModelProvider {
  pocketLLM,
  ollama,
  openAI,
  groq,
  openRouter,
  imageRouter,
  anthropic,
  mistral,
  deepseek,
  lmStudio,
  googleAI,
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
        return 'OpenAI';
      case ModelProvider.groq:
        return 'Groq';
      case ModelProvider.anthropic:
        return 'Anthropic';
      case ModelProvider.openRouter:
        return 'OpenRouter';
      case ModelProvider.imageRouter:
        return 'ImageRouter';
      case ModelProvider.mistral:
        return 'Mistral AI';
      case ModelProvider.deepseek:
        return 'DeepSeek';
      case ModelProvider.lmStudio:
        return 'LM Studio';
      case ModelProvider.googleAI:
        return 'Google AI';
    }
  }

  String? get brandAsset {
    switch (this) {
      case ModelProvider.pocketLLM:
        return 'assets/icons/logo2.png';
      case ModelProvider.ollama:
        return 'assets/brand_icons/ollama.png';
      case ModelProvider.openAI:
        return 'assets/brand_icons/openai.svg';
      case ModelProvider.groq:
        return 'assets/brand_icons/groq.svg';
      case ModelProvider.anthropic:
        return 'assets/brand_icons/Claude_AI_logo.svg';
      case ModelProvider.openRouter:
        return 'assets/brand_icons/openrouter.jpeg';
      case ModelProvider.imageRouter:
        return 'assets/brand_icons/hyperbrowser.svg';
      case ModelProvider.mistral:
        return 'assets/brand_icons/mistral.png';
      case ModelProvider.deepseek:
        return 'assets/brand_icons/deepseek.png';
      case ModelProvider.lmStudio:
        return 'assets/brand_icons/lmstudio.png';
      case ModelProvider.googleAI:
        return 'assets/brand_icons/Google_Gemini_icon_2025.svg';
    }
  }

  String get defaultBaseUrl {
    switch (this) {
      case ModelProvider.pocketLLM:
        return 'https://pocket-llm-api.vercel.app';
      case ModelProvider.ollama:
        return 'http://localhost:11434';
      case ModelProvider.openAI:
        return 'https://api.openai.com/v1';
      case ModelProvider.groq:
        return 'https://api.groq.com/openai/v1';
      case ModelProvider.anthropic:
        return 'https://api.anthropic.com';
      case ModelProvider.openRouter:
        return 'https://openrouter.ai/api';
      case ModelProvider.imageRouter:
        return 'https://api.imagerouter.com';
      case ModelProvider.mistral:
        return 'https://api.mistral.ai/v1';
      case ModelProvider.deepseek:
        return 'https://api.deepseek.com/v1';
      case ModelProvider.lmStudio:
        return 'http://localhost:1234';
      case ModelProvider.googleAI:
        return 'https://generativelanguage.googleapis.com';
    }
  }

  IconData get icon {
    switch (this) {
      case ModelProvider.pocketLLM:
        return Icons.person;
      case ModelProvider.ollama:
        return Icons.computer;
      case ModelProvider.openAI:
        return Icons.auto_awesome;
      case ModelProvider.groq:
        return Icons.flash_on;
      case ModelProvider.anthropic:
        return Icons.psychology;
      case ModelProvider.openRouter:
        return Icons.route;
      case ModelProvider.imageRouter:
        return Icons.image;
      case ModelProvider.mistral:
        return Icons.cloud;
      case ModelProvider.deepseek:
        return Icons.search;
      case ModelProvider.lmStudio:
        return Icons.settings;
      case ModelProvider.googleAI:
        return Icons.g_mobiledata;
    }
  }

  Color get color {
    switch (this) {
      case ModelProvider.pocketLLM:
        return Colors.purple;
      case ModelProvider.ollama:
        return Colors.blue;
      case ModelProvider.openAI:
        return Color(0xFF10A37F);
      case ModelProvider.groq:
        return Colors.deepOrange;
      case ModelProvider.anthropic:
        return Color(0xFFB4306A);
      case ModelProvider.openRouter:
        return Colors.deepPurple;
      case ModelProvider.imageRouter:
        return Colors.orangeAccent;
      case ModelProvider.mistral:
        return Colors.indigo;
      case ModelProvider.deepseek:
        return Colors.teal;
      case ModelProvider.lmStudio:
        return Colors.grey;
      case ModelProvider.googleAI:
        return Color(0xFF4285F4);
    }
  }

  String get backendId {
    switch (this) {
      case ModelProvider.pocketLLM:
        return 'pocketllm';
      case ModelProvider.ollama:
        return 'ollama';
      case ModelProvider.openAI:
        return 'openai';
      case ModelProvider.groq:
        return 'groq';
      case ModelProvider.anthropic:
        return 'anthropic';
      case ModelProvider.openRouter:
        return 'openrouter';
      case ModelProvider.imageRouter:
        return 'imagerouter';
      case ModelProvider.mistral:
        return 'mistral';
      case ModelProvider.deepseek:
        return 'deepseek';
      case ModelProvider.lmStudio:
        return 'lmstudio';
      case ModelProvider.googleAI:
        return 'googleai';
    }
  }

  static ModelProvider fromBackend(String value) {
    switch (value.toLowerCase()) {
      case 'pocketllm':
        return ModelProvider.pocketLLM;
      case 'ollama':
        return ModelProvider.ollama;
      case 'openai':
        return ModelProvider.openAI;
      case 'groq':
        return ModelProvider.groq;
      case 'anthropic':
        return ModelProvider.anthropic;
      case 'openrouter':
        return ModelProvider.openRouter;
      case 'imagerouter':
        return ModelProvider.imageRouter;
      case 'mistral':
        return ModelProvider.mistral;
      case 'deepseek':
        return ModelProvider.deepseek;
      case 'lmstudio':
        return ModelProvider.lmStudio;
      case 'googleai':
        return ModelProvider.googleAI;
      default:
        return ModelProvider.pocketLLM;
    }
  }
}

class ProviderConnection {
  final String id;
  final ModelProvider provider;
  final String displayName;
  final String? baseUrl;
  final bool isActive;
  final bool hasApiKey;
  final String? apiKeyPreview;
  final Map<String, dynamic>? metadata;
  final String? statusMessage;

  ProviderConnection({
    required this.id,
    required this.provider,
    required this.displayName,
    required this.baseUrl,
    required this.isActive,
    required this.hasApiKey,
    this.apiKeyPreview,
    this.metadata,
    this.statusMessage,
  });

  factory ProviderConnection.fromJson(Map<String, dynamic> json) {
    Map<String, dynamic>? _asMap(dynamic value) {
      if (value is Map<String, dynamic>) {
        return value;
      }
      if (value is Map) {
        return value.map(
          (key, dynamic v) => MapEntry(key.toString(), v),
        );
      }
      return null;
    }

    String? _string(dynamic value) => value is String ? value : null;

    final providerId = _string(json['provider']) ?? '';
    final provider = providerId.isNotEmpty
        ? ModelProviderExtension.fromBackend(providerId)
        : ModelProvider.pocketLLM;

    String fallbackName() {
      if (providerId.isEmpty) {
        return provider.displayName;
      }
      final normalizedId = providerId.toLowerCase();
      if (normalizedId == provider.backendId.toLowerCase()) {
        return provider.displayName;
      }
      return providerId;
    }

    final displayName = _string(json['displayName']) ??
        _string(json['display_name']) ??
        fallbackName();

    final baseUrl = _string(json['baseUrl']) ?? _string(json['base_url']);
    final metadata = _asMap(json['metadata']);
    final apiKeyPreview =
        _string(json['apiKeyPreview']) ?? _string(json['api_key_preview']);
    final statusMessage = _string(json['message']) ?? _string(json['status_message']);

    return ProviderConnection(
      id: _string(json['id']) ?? '',
      provider: provider,
      displayName: displayName,
      baseUrl: baseUrl,
      isActive: json['isActive'] == true || json['is_active'] == true,
      hasApiKey: json['hasApiKey'] == true || json['has_api_key'] == true,
      apiKeyPreview: apiKeyPreview,
      metadata: metadata,
      statusMessage: statusMessage,
    );
  }
}

class ProviderStatusInfo {
  final ModelProvider provider;
  final String displayName;
  final bool configured;
  final bool isActive;
  final bool hasApiKey;
  final String? apiKeyPreview;
  final String message;

  ProviderStatusInfo({
    required this.provider,
    required this.displayName,
    required this.configured,
    required this.isActive,
    required this.hasApiKey,
    this.apiKeyPreview,
    required this.message,
  });

  factory ProviderStatusInfo.fromJson(Map<String, dynamic> json) {
    String? _string(dynamic value) => value is String ? value : null;

    final providerId = _string(json['provider']) ?? '';
    final provider = ModelProviderExtension.fromBackend(providerId);

    String fallbackName() {
      if (providerId.isEmpty) {
        return provider.displayName;
      }
      final normalizedId = providerId.toLowerCase();
      if (normalizedId == provider.backendId.toLowerCase()) {
        return provider.displayName;
      }
      return providerId;
    }

    return ProviderStatusInfo(
      provider: provider,
      displayName: _string(json['displayName']) ??
          _string(json['display_name']) ??
          fallbackName(),
      configured: json['configured'] == true || json['is_configured'] == true,
      isActive: json['isActive'] == true || json['is_active'] == true,
      hasApiKey: json['hasApiKey'] == true || json['has_api_key'] == true,
      apiKeyPreview: _string(json['apiKeyPreview']) ??
          _string(json['api_key_preview']),
      message: _string(json['message']) ?? _string(json['status_message']) ?? '',
    );
  }
}

class AvailableModelOption {
  final String id;
  final String name;
  final String provider;
  final String? description;
  final Map<String, dynamic>? metadata;

  AvailableModelOption({
    required this.id,
    required this.name,
    required this.provider,
    this.description,
    this.metadata,
  });

  factory AvailableModelOption.fromJson(Map<String, dynamic> json, String provider) {
    return AvailableModelOption(
      id: json['id'] ?? json['name'] ?? '',
      name: json['name'] ?? json['id'] ?? '',
      provider: provider,
      description: json['description'],
      metadata: json,
    );
  }
}

class AvailableModelsResponse {
  final List<AvailableModelOption> models;
  final String? message;
  final List<String> configuredProviders;
  final List<String> missingProviders;
  final bool usingFallback;

  const AvailableModelsResponse({
    required this.models,
    this.message,
    this.configuredProviders = const <String>[],
    this.missingProviders = const <String>[],
    this.usingFallback = false,
  });
}

// Model configuration class
class ModelConfig {
  String id;
  String name;
  ModelProvider provider;
  String? providerId;
  String baseUrl;
  String? apiKey;
  String model;
  String? systemPrompt;
  double temperature;
  int? maxTokens;
  double? topP;
  double? frequencyPenalty;
  double? presencePenalty;
  Map<String, dynamic>? additionalParams;
  Map<String, dynamic>? metadata;
  bool isDefault;
  bool isActive;
  DateTime createdAt;
  DateTime updatedAt;

  ModelConfig({
    required this.id,
    required this.name,
    required this.provider,
    this.providerId,
    required this.baseUrl,
    this.apiKey,
    required this.model,
    this.systemPrompt,
    this.temperature = 0.7,
    this.maxTokens = 2048,
    this.topP = 1.0,
    this.frequencyPenalty = 0.0,
    this.presencePenalty = 0.0,
    this.additionalParams,
    this.metadata,
    this.isDefault = false,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'provider': provider.backendId,
      'providerId': providerId,
      'baseUrl': baseUrl,
      'apiKey': apiKey,
      'model': model,
      'systemPrompt': systemPrompt,
      'temperature': temperature,
      'maxTokens': maxTokens,
      'topP': topP,
      'frequencyPenalty': frequencyPenalty,
      'presencePenalty': presencePenalty,
      'additionalParams': additionalParams,
      'metadata': metadata,
      'isDefault': isDefault,
      'isActive': isActive,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
    };
  }

  factory ModelConfig.fromJson(Map<String, dynamic> json) {
    Map<String, dynamic>? _asMap(dynamic value) {
      if (value is Map<String, dynamic>) {
        return value;
      }
      if (value is Map) {
        return value.map(
          (key, dynamic v) => MapEntry(key.toString(), v),
        );
      }
      return null;
    }

    String? _string(dynamic value) => value is String ? value : null;

    double? _double(dynamic value) {
      if (value is num) {
        return value.toDouble();
      }
      if (value is String) {
        return double.tryParse(value);
      }
      return null;
    }

    int? _int(dynamic value) {
      if (value is num) {
        return value.toInt();
      }
      if (value is String) {
        return int.tryParse(value);
      }
      return null;
    }

    DateTime _parseDate(dynamic value) {
      if (value is int) {
        return DateTime.fromMillisecondsSinceEpoch(value);
      }
      if (value is String) {
        return DateTime.tryParse(value) ?? DateTime.now();
      }
      if (value is DateTime) {
        return value;
      }
      return DateTime.now();
    }

    final providerValue = json['provider'];
    final ModelProvider provider;
    if (providerValue is int) {
      provider = ModelProvider.values[providerValue];
    } else if (providerValue is String) {
      provider = ModelProviderExtension.fromBackend(providerValue);
    } else {
      provider = ModelProvider.pocketLLM;
    }

    final providerDetails =
        _asMap(json['providerDetails']) ?? _asMap(json['provider_details']);
    final settings =
        _asMap(json['settings']) ?? _asMap(json['modelSettings']);

    final metadata = Map<String, dynamic>.from(
      _asMap(json['metadata']) ?? const <String, dynamic>{},
    );
    final additionalParams = Map<String, dynamic>.from(
      _asMap(json['additionalParams']) ?? const <String, dynamic>{},
    );

    final systemPrompt = _string(settings?['system_prompt']) ??
        _string(json['systemPrompt']);
    final temperature =
        _double(settings?['temperature']) ?? _double(json['temperature']) ?? 0.7;
    final maxTokens =
        _int(settings?['max_tokens']) ?? _int(json['maxTokens']);
    final topP =
        _double(settings?['top_p']) ?? _double(json['topP']) ?? 1.0;
    final frequencyPenalty =
        _double(settings?['frequency_penalty']) ??
        _double(json['frequencyPenalty']) ??
        0.0;
    final presencePenalty =
        _double(settings?['presence_penalty']) ??
        _double(json['presencePenalty']) ??
        0.0;

    final settingsMetadata = _asMap(settings?['metadata']);
    if (settingsMetadata != null) {
      metadata.addAll(settingsMetadata);
    }

    if (settings != null) {
      additionalParams.addAll(settings);
      additionalParams.removeWhere((key, _) =>
          {
            'temperature',
            'max_tokens',
            'top_p',
            'frequency_penalty',
            'presence_penalty',
            'system_prompt',
            'metadata',
          }.contains(key));
    }

    if (json['description'] != null && metadata['description'] == null) {
      metadata['description'] = json['description'];
    }

    final baseUrl = _string(json['baseUrl']) ??
        _string(json['base_url']) ??
        _string(providerDetails?['baseUrl']) ??
        _string(providerDetails?['base_url']) ??
        provider.defaultBaseUrl;

    final modelName = _string(json['display_name']) ??
        _string(json['name']) ??
        _string(json['model']) ??
        'Model';

    return ModelConfig(
      id: json['id'],
      name: modelName,
      provider: provider,
      providerId: _string(json['providerId']) ?? _string(json['provider_id']),
      baseUrl: baseUrl,
      apiKey: _string(json['apiKey']) ?? _string(json['api_key']),
      model: _string(json['model']) ?? modelName,
      systemPrompt: systemPrompt,
      temperature: temperature,
      maxTokens: maxTokens,
      topP: topP,
      frequencyPenalty: frequencyPenalty,
      presencePenalty: presencePenalty,
      additionalParams:
          additionalParams.isEmpty ? null : Map<String, dynamic>.from(additionalParams),
      metadata: metadata.isEmpty ? null : Map<String, dynamic>.from(metadata),
      isDefault: json['isDefault'] == true || json['is_default'] == true,
      isActive: json['isActive'] != false && json['is_active'] != false,
      createdAt: _parseDate(json['createdAt'] ?? json['created_at']),
      updatedAt: _parseDate(json['updatedAt'] ?? json['updated_at']),
    );
  }

  ModelConfig copyWith({
    String? id,
    String? name,
    ModelProvider? provider,
    String? providerId,
    String? baseUrl,
    String? apiKey,
    String? model,
    String? systemPrompt,
    double? temperature,
    int? maxTokens,
    double? topP,
    double? frequencyPenalty,
    double? presencePenalty,
    Map<String, dynamic>? additionalParams,
    Map<String, dynamic>? metadata,
    bool? isDefault,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ModelConfig(
      id: id ?? this.id,
      name: name ?? this.name,
      provider: provider ?? this.provider,
      providerId: providerId ?? this.providerId,
      baseUrl: baseUrl ?? this.baseUrl,
      apiKey: apiKey ?? this.apiKey,
      model: model ?? this.model,
      systemPrompt: systemPrompt ?? this.systemPrompt,
      temperature: temperature ?? this.temperature,
      maxTokens: maxTokens ?? this.maxTokens,
      topP: topP ?? this.topP,
      frequencyPenalty: frequencyPenalty ?? this.frequencyPenalty,
      presencePenalty: presencePenalty ?? this.presencePenalty,
      additionalParams: additionalParams ?? this.additionalParams,
      metadata: metadata ?? this.metadata,
      isDefault: isDefault ?? this.isDefault,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class Source {
  final String title;
  final String url;
  final String snippet;

  Source({
    required this.title,
    required this.url,
    required this.snippet,
  });
}

class Conversation {
  final String id;
  final String title;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<Message> messages;
  final String? modelConfigId;
  
  String? get modelId => modelConfigId;
  
  Conversation({
    required this.id,
    required this.title,
    required this.createdAt,
    required this.updatedAt,
    required this.messages,
    this.modelConfigId,
  });
  
  // Create a copy of this conversation with updated properties
  Conversation copyWith({
    String? id,
    String? title,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<Message>? messages,
    String? modelConfigId,
    String? modelId,
  }) {
    return Conversation(
      id: id ?? this.id,
      title: title ?? this.title,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      messages: messages ?? this.messages,
      modelConfigId: modelConfigId ?? modelId ?? this.modelConfigId,
    );
  }
  
  // Generate a title from the first user message content
  static String generateTitle(List<Message> messages) {
    final firstUserMessage = messages.firstWhere(
      (msg) => msg.isUser,
      orElse: () => Message(
        content: 'New Chat',
        isUser: true,
        timestamp: DateTime.now(),
      ),
    );
    
    // Get the first 30 characters or the first line, whichever is shorter
    String content = firstUserMessage.content.trim();
    
    if (content.contains('\n')) {
      content = content.split('\n').first.trim();
    }
    
    if (content.length > 30) {
      content = content.substring(0, 27) + '...';
    }
    
    return content.isEmpty ? 'New Chat' : content;
  }
  
  // Add fromJson and toJson methods for serialization
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'messages': messages.map((m) => m.toJson()).toList(),
      'modelId': modelConfigId,
      'modelConfigId': modelConfigId,
    };
  }
  
  factory Conversation.fromJson(Map<String, dynamic> json) {
    return Conversation(
      id: json['id'] ?? '',
      title: json['title'] ?? 'New Chat',
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : DateTime.now(),
      messages: json['messages'] != null
          ? (json['messages'] as List)
              .map((m) => Message.fromJson(m as Map<String, dynamic>))
              .toList()
          : <Message>[],
      modelConfigId: json['modelConfigId'] ?? json['modelId'],
    );
  }
  
  // Create a new conversation with a generated ID
  factory Conversation.create({String? title, String? modelConfigId, String? modelId}) {
    final now = DateTime.now();
    return Conversation(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title ?? 'New Chat',
      createdAt: now,
      updatedAt: now,
      messages: [],
      modelConfigId: modelConfigId ?? modelId,
    );
  }
}
