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
  static final List<AIModel> models = [
    AIModel(
      id: 'deepseek-r1',
      provider: 'DeepSeek',
      description: 'DeepSeek\'s first-generation of reasoning models with comparable performance to OpenAI-r1, including six dense models distilled from DeepSeek-R1 based on Llama and Qwen.',
      parameterVariants: ['1.5b', '7b', '8b', '14b', '32b', '67b'],
      downloads: 20000000,
      comments: 29,
      releaseDate: DateTime.now().subtract(Duration(days: 14)),
    ),
    AIModel(
      id: 'llama3.3',
      provider: 'Meta',
      description: 'New state of the art 70B model. Llama 3.3 70B offers similar performance compared to the Llama 3.1 405B model.',
      parameterVariants: ['70b'],
      downloads: 1400000,
      comments: 14,
      releaseDate: DateTime.now().subtract(Duration(days: 60)),
      tools: ['tools'],
    ),
    AIModel(
      id: 'phi4',
      provider: 'Microsoft',
      description: 'Phi-4 is a 14B parameter, state-of-the-art open model from Microsoft.',
      parameterVariants: ['14b'],
      downloads: 702800,
      comments: 5,
      releaseDate: DateTime.now().subtract(Duration(days: 42)),
    ),
    AIModel(
      id: 'llama3.2',
      provider: 'Meta',
      description: 'Meta\'s Llama 3.2 goes small with 1B and 3B models.',
      parameterVariants: ['1b', '3b'],
      downloads: 9300000,
      comments: 63,
      releaseDate: DateTime.now().subtract(Duration(days: 150)),
      tools: ['tools'],
    ),
    AIModel(
      id: 'llama3.1',
      provider: 'Meta',
      description: 'Llama 3.1 is a new state-of-the-art model from Meta available in 8B, 70B and 405B parameter sizes.',
      parameterVariants: ['8b', '70b', '405b'],
      downloads: 24800000,
      comments: 93,
      releaseDate: DateTime.now().subtract(Duration(days: 60)),
      tools: ['tools'],
    ),
  ];
  // Change this method to return Future
  static Future<List<AIModel>> getAvailableModels() async {
    final sortedModels = List<AIModel>.from(models);
    sortedModels.sort((a, b) => b.releaseDate.compareTo(a.releaseDate));
    return sortedModels;
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
  String content;
  final bool isUser;
  final DateTime timestamp;
  bool isThinking;
  final bool isStreaming;
  final bool isError;
  final List<SearchResult>? sources;

  Message({
    required this.content,
    required this.isUser,
    required this.timestamp,
    this.isThinking = false,
    this.isStreaming = false,
    this.isError = false,
    this.sources,
  });

  // Add fromJson and toJson methods for serialization
  Map<String, dynamic> toJson() {
    return {
      'content': content,
      'isUser': isUser,
      'timestamp': timestamp.toIso8601String(),
      'isThinking': isThinking,
      'isStreaming': isStreaming,
      'isError': isError,
      'sources': sources?.map((s) => s.toJson()).toList(),
    };
  }

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      content: json['content'] ?? '',
      isUser: json['isUser'] ?? false,
      timestamp: json['timestamp'] != null 
          ? DateTime.parse(json['timestamp']) 
          : DateTime.now(),
      isThinking: json['isThinking'] ?? false,
      isStreaming: json['isStreaming'] ?? false,
      isError: json['isError'] ?? false,
      sources: json['sources'] != null
          ? (json['sources'] as List).map((s) => SearchResult.fromJson(s as Map<String, dynamic>)).toList()
          : null,
    );
  }

  // Create a copy of this message with updated properties
  Message copyWith({
    String? content,
    bool? isUser,
    DateTime? timestamp,
    bool? isThinking,
    bool? isStreaming,
    bool? isError,
    List<SearchResult>? sources,
  }) {
    return Message(
      content: content ?? this.content,
      isUser: isUser ?? this.isUser,
      timestamp: timestamp ?? this.timestamp,
      isThinking: isThinking ?? this.isThinking,
      isStreaming: isStreaming ?? this.isStreaming,
      isError: isError ?? this.isError,
      sources: sources ?? this.sources,
    );
  }
}

// Enum for model providers
enum ModelProvider {
  pocketLLM,
  ollama,
  openAI,
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
      case ModelProvider.anthropic:
        return 'Anthropic';
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

  String get defaultBaseUrl {
    switch (this) {
      case ModelProvider.pocketLLM:
        return 'https://api.pocketllm.com';
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
      case ModelProvider.anthropic:
        return Icons.psychology;
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
      case ModelProvider.anthropic:
        return Color(0xFFB4306A);
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
}

// Model configuration class
class ModelConfig {
  String id;
  String name;
  ModelProvider provider;
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
  DateTime createdAt;
  DateTime updatedAt;

  ModelConfig({
    required this.id,
    required this.name,
    required this.provider,
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
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'provider': provider.index,
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
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
    };
  }

  factory ModelConfig.fromJson(Map<String, dynamic> json) {
    return ModelConfig(
      id: json['id'],
      name: json['name'],
      provider: ModelProvider.values[json['provider']],
      baseUrl: json['baseUrl'],
      apiKey: json['apiKey'],
      model: json['model'],
      systemPrompt: json['systemPrompt'],
      temperature: json['temperature'] ?? 0.7,
      maxTokens: json['maxTokens'] ?? 2048,
      topP: json['topP'] ?? 1.0,
      frequencyPenalty: json['frequencyPenalty'] ?? 0.0,
      presencePenalty: json['presencePenalty'] ?? 0.0,
      additionalParams: json['additionalParams'],
      createdAt: DateTime.fromMillisecondsSinceEpoch(json['createdAt']),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(json['updatedAt']),
    );
  }

  ModelConfig copyWith({
    String? id,
    String? name,
    ModelProvider? provider,
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
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ModelConfig(
      id: id ?? this.id,
      name: name ?? this.name,
      provider: provider ?? this.provider,
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
  final String? modelId;
  
  Conversation({
    required this.id,
    required this.title,
    required this.createdAt,
    required this.updatedAt,
    required this.messages,
    this.modelId,
  });
  
  // Create a copy of this conversation with updated properties
  Conversation copyWith({
    String? id,
    String? title,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<Message>? messages,
    String? modelId,
  }) {
    return Conversation(
      id: id ?? this.id,
      title: title ?? this.title,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      messages: messages ?? this.messages,
      modelId: modelId ?? this.modelId,
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
      'modelId': modelId,
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
      modelId: json['modelId'],
    );
  }
  
  // Create a new conversation with a generated ID
  factory Conversation.create({String? title, String? modelId}) {
    final now = DateTime.now();
    return Conversation(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title ?? 'New Chat',
      createdAt: now,
      updatedAt: now,
      messages: [],
      modelId: modelId,
    );
  }
}