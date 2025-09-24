import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../component/models.dart';

class ChatHistoryService {
  static const String _localChatHistoryKey = 'chat_conversations';
  
  // Cached conversations
  List<Conversation> _cachedConversations = [];
  
  // Stream controller for conversations
  final ValueNotifier<List<Conversation>> conversationsNotifier = ValueNotifier<List<Conversation>>([]);
  
  // Current active conversation
  final ValueNotifier<Conversation?> activeConversationNotifier = ValueNotifier<Conversation?>(null);
  
  // Load conversations from local storage
  Future<List<Conversation>> loadConversations() async {
    try {
      // Load from local storage
      await _loadFromLocalStorage();
      
      // Sort conversations by updatedAt
      _cachedConversations.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      conversationsNotifier.value = List.from(_cachedConversations);
      
      return _cachedConversations;
    } catch (e) {
      debugPrint('Error loading conversations: $e');
      // If there's an error, return whatever we have in the cache
      return _cachedConversations;
    }
  }
  
  // Load conversations from local storage
  Future<void> _loadFromLocalStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedData = prefs.getString(_localChatHistoryKey);
      if (savedData != null) {
        final List<dynamic> decodedData = jsonDecode(savedData);
        _cachedConversations = decodedData
            .map((json) => Conversation.fromJson(json))
            .toList();
      }
    } catch (e) {
      debugPrint('Error loading conversations from local storage: $e');
    }
  }
  
  // Save conversations to local storage
  Future<void> _saveToLocalStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final encodedData = jsonEncode(_cachedConversations.map((c) => c.toJson()).toList());
      await prefs.setString(_localChatHistoryKey, encodedData);
    } catch (e) {
      debugPrint('Error saving conversations to local storage: $e');
    }
  }
  
  // Create a new conversation
  Future<Conversation> createConversation({String? title, String? modelId}) async {
    final conversation = Conversation.create(title: title, modelId: modelId);
    
    _cachedConversations.insert(0, conversation);
    conversationsNotifier.value = List.from(_cachedConversations);
    
    await _saveToLocalStorage();
    
    // Set as active conversation
    activeConversationNotifier.value = conversation;
    
    return conversation;
  }
  
  // Get a conversation by ID
  Conversation? getConversation(String id) {
    try {
      return _cachedConversations.firstWhere((c) => c.id == id);
    } catch (e) {
      debugPrint('Error finding conversation with ID $id: $e');
      return null;
    }
  }
  
  // Set active conversation
  void setActiveConversation(String? conversationId) {
    if (conversationId == null) {
      activeConversationNotifier.value = null;
      return;
    }
    
    final conversation = getConversation(conversationId);
    if (conversation != null) {
      debugPrint('Setting active conversation to: ${conversation.id} (${conversation.title})');
      activeConversationNotifier.value = conversation;
    } else {
      debugPrint('Warning: Tried to set active conversation to non-existent ID: $conversationId');
      // Attempt to load conversations in case it was not loaded yet
      loadConversations().then((_) {
        final reloadedConversation = getConversation(conversationId);
        if (reloadedConversation != null) {
          debugPrint('Found conversation after reload: ${reloadedConversation.id}');
          activeConversationNotifier.value = reloadedConversation;
        }
      });
    }
  }
  
  // Add a message to a conversation
  Future<void> addMessageToConversation(String conversationId, Message message) async {
    try {
      final index = _cachedConversations.indexWhere((c) => c.id == conversationId);
      if (index == -1) return;
      
      final conversation = _cachedConversations[index];
      final messages = List<Message>.from(conversation.messages)..add(message);
      
      // Update the conversation with the new message
      final updatedConversation = conversation.copyWith(
        messages: messages,
        updatedAt: DateTime.now(),
      );
      
      // Update title if this is the first user message and the title is still the default
      if (message.isUser && conversation.title == 'New Chat' && messages.where((m) => m.isUser).length == 1) {
        final newTitle = Conversation.generateTitle(messages);
        _cachedConversations[index] = updatedConversation.copyWith(title: newTitle);
      } else {
        _cachedConversations[index] = updatedConversation;
      }
      
      // Update notifiers
      conversationsNotifier.value = List.from(_cachedConversations);
      if (activeConversationNotifier.value?.id == conversationId) {
        activeConversationNotifier.value = _cachedConversations[index];
      }
      
      // Save changes
      await _saveToLocalStorage();
    } catch (e) {
      debugPrint('Error adding message to conversation: $e');
    }
  }
  
  // Update a conversation
  Future<void> updateConversation(Conversation updatedConversation) async {
    try {
      final index = _cachedConversations.indexWhere((c) => c.id == updatedConversation.id);
      if (index == -1) return;
      
      _cachedConversations[index] = updatedConversation.copyWith(
        updatedAt: DateTime.now(),
      );
      
      // Update notifiers
      conversationsNotifier.value = List.from(_cachedConversations);
      if (activeConversationNotifier.value?.id == updatedConversation.id) {
        activeConversationNotifier.value = _cachedConversations[index];
      }
      
      // Save changes
      await _saveToLocalStorage();
    } catch (e) {
      debugPrint('Error updating conversation: $e');
    }
  }
  
  // Update a conversation's title
  Future<void> updateConversationTitle(String conversationId, String newTitle) async {
    try {
      final index = _cachedConversations.indexWhere((c) => c.id == conversationId);
      if (index == -1) return;
      
      _cachedConversations[index] = _cachedConversations[index].copyWith(
        title: newTitle,
        updatedAt: DateTime.now(),
      );
      
      // Update notifiers
      conversationsNotifier.value = List.from(_cachedConversations);
      if (activeConversationNotifier.value?.id == conversationId) {
        activeConversationNotifier.value = _cachedConversations[index];
      }
      
      // Save changes
      await _saveToLocalStorage();
    } catch (e) {
      debugPrint('Error updating conversation title: $e');
    }
  }
  
  // Delete a conversation
  Future<void> deleteConversation(String conversationId) async {
    try {
      _cachedConversations.removeWhere((c) => c.id == conversationId);
      conversationsNotifier.value = List.from(_cachedConversations);
      
      // If this was the active conversation, clear it
      if (activeConversationNotifier.value?.id == conversationId) {
        activeConversationNotifier.value = null;
      }
      
      // Save changes
      await _saveToLocalStorage();
    } catch (e) {
      debugPrint('Error deleting conversation: $e');
    }
  }
  
  // Clear all conversations
  Future<void> clearAllConversations() async {
    try {
      _cachedConversations.clear();
      conversationsNotifier.value = [];
      activeConversationNotifier.value = null;
      
      // Save changes
      await _saveToLocalStorage();
    } catch (e) {
      debugPrint('Error clearing conversations: $e');
    }
  }
} 