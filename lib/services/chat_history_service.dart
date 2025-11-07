/// Chat history coordinator that keeps local notifiers in sync with the backend.
import 'package:flutter/foundation.dart';

import '../component/models.dart';
import 'remote_chat_service.dart';

class ChatHistoryService {
  ChatHistoryService._internal();
  static final ChatHistoryService _instance = ChatHistoryService._internal();
  factory ChatHistoryService() => _instance;

  final RemoteChatService _remote = RemoteChatService();

  List<Conversation> _cachedConversations = [];
  bool _initialised = false;

  final ValueNotifier<List<Conversation>> conversationsNotifier =
      ValueNotifier<List<Conversation>>([]);
  final ValueNotifier<Conversation?> activeConversationNotifier =
      ValueNotifier<Conversation?>(null);

  Future<List<Conversation>> loadConversations({bool refresh = false}) async {
    if (_initialised && !refresh && _cachedConversations.isNotEmpty) {
      return _cachedConversations;
    }
    try {
      final conversations = await _remote.fetchChats();
      _cachedConversations = List.from(conversations);
      conversationsNotifier.value = List.unmodifiable(_cachedConversations);
      _initialised = true;
      if (activeConversationNotifier.value == null &&
          _cachedConversations.isNotEmpty) {
        await setActiveConversation(_cachedConversations.first.id);
      }
    } catch (error, stackTrace) {
      debugPrint('ChatHistoryService: Failed to load conversations: $error');
      debugPrint(stackTrace.toString());
      rethrow;
    }
    return _cachedConversations;
  }

  Future<Conversation> createConversation({String? title, String? modelId}) async {
    final conversation = await _remote.createChat(
      title: title,
      modelConfigId: modelId,
    );
    _cachedConversations.insert(0, conversation);
    conversationsNotifier.value = List.unmodifiable(_cachedConversations);
    await setActiveConversation(conversation.id);
    return conversation;
  }

  Conversation? getConversation(String id) {
    try {
      return _cachedConversations.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<void> setActiveConversation(String? conversationId) async {
    if (conversationId == null) {
      activeConversationNotifier.value = null;
      return;
    }

    final existing = getConversation(conversationId);
    if (existing != null && existing.messages.isNotEmpty) {
      activeConversationNotifier.value = existing;
      return;
    }

    try {
      final fresh = await _remote.fetchChat(conversationId);
      _upsertConversation(fresh);
      activeConversationNotifier.value = fresh;
    } catch (error) {
      debugPrint('ChatHistoryService: Failed to set active conversation: $error');
    }
  }

  Future<void> addMessageToConversation(String conversationId, Message message) async {
    final index = _cachedConversations.indexWhere((c) => c.id == conversationId);
    if (index == -1) return;

    final conversation = _cachedConversations[index];
    final updated = conversation.copyWith(
      messages: List<Message>.from(conversation.messages)..add(message),
      updatedAt: DateTime.now(),
    );
    _cachedConversations[index] = updated;
    conversationsNotifier.value = List.unmodifiable(_cachedConversations);
    if (activeConversationNotifier.value?.id == conversationId) {
      activeConversationNotifier.value = updated;
    }
  }

  Future<void> updateConversation(Conversation updatedConversation) async {
    _upsertConversation(updatedConversation);
    if (activeConversationNotifier.value?.id == updatedConversation.id) {
      activeConversationNotifier.value = updatedConversation;
    }
  }

  Future<void> updateConversationTitle(String conversationId, String newTitle) async {
    await _remote.updateChat(conversationId, title: newTitle);
    final existing = getConversation(conversationId);
    if (existing == null) return;
    final updated = existing.copyWith(title: newTitle, updatedAt: DateTime.now());
    _upsertConversation(updated);
    if (activeConversationNotifier.value?.id == conversationId) {
      activeConversationNotifier.value = updated;
    }
  }

  Future<void> updateConversationModel(String conversationId, String modelConfigId) async {
    await _remote.updateChat(conversationId, modelConfigId: modelConfigId);
    final existing = getConversation(conversationId);
    if (existing == null) return;
    final updated = existing.copyWith(modelConfigId: modelConfigId);
    _upsertConversation(updated);
  }

  Future<void> deleteConversation(String conversationId) async {
    await _remote.deleteChat(conversationId);
    _cachedConversations.removeWhere((c) => c.id == conversationId);
    conversationsNotifier.value = List.unmodifiable(_cachedConversations);
    if (activeConversationNotifier.value?.id == conversationId) {
      activeConversationNotifier.value = null;
    }
  }

  Future<void> clearAllConversations() async {
    final ids = _cachedConversations.map((c) => c.id).toList();
    for (final id in ids) {
      await deleteConversation(id);
    }
    activeConversationNotifier.value = null;
  }

  Future<Message> sendMessage(String conversationId, String content) async {
    final response = await _remote.sendMessage(chatId: conversationId, content: content);
    await refreshConversation(conversationId);
    return response;
  }

  Future<List<Message>> refreshConversation(String conversationId) async {
    final detail = await _remote.fetchChat(conversationId);
    _upsertConversation(detail);
    if (activeConversationNotifier.value?.id == conversationId) {
      activeConversationNotifier.value = detail;
    }
    return detail.messages;
  }

  void _upsertConversation(Conversation conversation) {
    final index = _cachedConversations.indexWhere((c) => c.id == conversation.id);
    if (index >= 0) {
      _cachedConversations[index] = conversation;
    } else {
      _cachedConversations.insert(0, conversation);
    }
    conversationsNotifier.value = List.unmodifiable(_cachedConversations);
  }
}
