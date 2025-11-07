/// Remote chat API client for conversation CRUD and messaging.
import 'package:flutter/foundation.dart';

import '../component/models.dart';
import 'backend_api_service.dart';

class RemoteChatService {
  RemoteChatService._internal();
  static final RemoteChatService _instance = RemoteChatService._internal();
  factory RemoteChatService() => _instance;

  final BackendApiService _api = BackendApiService();

  Future<List<Conversation>> fetchChats() async {
    final data = await _api.get('chats');
    if (data is! List) return const [];
    return data
        .whereType<Map>()
        .map((raw) => _mapConversationSummary(Map<String, dynamic>.from(raw as Map)))
        .toList();
  }

  Future<Conversation> fetchChat(String chatId) async {
    final data = await _api.get('chats/$chatId');
    if (data is! Map<String, dynamic>) {
      throw StateError('Unexpected chat payload: $data');
    }
    return _mapConversationDetail(data);
  }

  Future<Conversation> createChat({
    String? title,
    String? modelConfigId,
    String? initialMessage,
  }) async {
    final body = <String, dynamic>{
      if (title != null && title.trim().isNotEmpty) 'title': title.trim(),
      if (modelConfigId != null && modelConfigId.isNotEmpty) 'model_config_id': modelConfigId,
      if (initialMessage != null && initialMessage.trim().isNotEmpty) 'initial_message': initialMessage.trim(),
    };
    final data = await _api.post('chats', body: body.isEmpty ? null : body);
    return _mapConversationSummary(Map<String, dynamic>.from(data as Map));
  }

  Future<Conversation> updateChat(
    String chatId, {
    String? title,
    String? modelConfigId,
  }) async {
    final body = <String, dynamic>{};
    if (title != null) body['title'] = title;
    if (modelConfigId != null) body['model_config_id'] = modelConfigId;
    final data = await _api.put('chats/$chatId', body: body);
    return _mapConversationSummary(Map<String, dynamic>.from(data as Map));
  }

  Future<void> deleteChat(String chatId) async {
    await _api.delete('chats/$chatId');
  }

  Future<Message> sendMessage({
    required String chatId,
    required String content,
    bool stream = false,
  }) async {
    final data = await _api.post(
      'chats/$chatId/messages',
      body: {
        'content': content,
        'role': 'user',
        'stream': stream,
      },
    );
    return _mapMessage(Map<String, dynamic>.from(data as Map));
  }

  Future<List<Message>> fetchMessages(String chatId) async {
    final data = await _api.get('chats/$chatId/messages');
    if (data is! List) return const [];
    return data
        .whereType<Map>()
        .map((raw) => _mapMessage(Map<String, dynamic>.from(raw as Map)))
        .toList();
  }

  Conversation _mapConversationSummary(Map<String, dynamic> payload) {
    return Conversation(
      id: payload['id']?.toString() ?? '',
      title: payload['title']?.toString() ?? 'New Chat',
      createdAt: _parseDate(payload['created_at']) ?? DateTime.now(),
      updatedAt: _parseDate(payload['updated_at']) ?? DateTime.now(),
      messages: const [],
      modelConfigId: payload['model_config_id']?.toString(),
    );
  }

  Conversation _mapConversationDetail(Map<String, dynamic> payload) {
    final chat = payload['chat'];
    if (chat is! Map<String, dynamic>) {
      throw StateError('Malformed conversation payload: $payload');
    }
    final messages = (payload['messages'] as List<dynamic>? ?? const [])
        .whereType<Map>()
        .map((raw) => _mapMessage(Map<String, dynamic>.from(raw as Map)))
        .toList();
    final summary = _mapConversationSummary(chat);
    return summary.copyWith(
      messages: messages,
      updatedAt: messages.isNotEmpty ? messages.last.timestamp : summary.updatedAt,
    );
  }

  Message _mapMessage(Map<String, dynamic> payload) {
    final role = payload['role']?.toString().toLowerCase() ?? 'assistant';
    return Message(
      id: payload['id']?.toString(),
      content: payload['content']?.toString() ?? '',
      isUser: role == 'user',
      timestamp: _parseDate(payload['created_at']) ?? DateTime.now(),
      metadata: payload['metadata'] is Map<String, dynamic>
          ? Map<String, dynamic>.from(payload['metadata'] as Map)
          : null,
    );
  }

  DateTime? _parseDate(dynamic value) {
    if (value is DateTime) return value;
    if (value is String && value.isNotEmpty) {
      return DateTime.tryParse(value)?.toLocal();
    }
    return null;
  }
}
