import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'models.dart';

class ChatHistoryManager {
  static const String _chatHistoryKey = 'chat_history';

  // Save chat history to device storage
  Future<void> saveChatHistory(List<Message> messages) async {
    final prefs = await SharedPreferences.getInstance();
    final encodedMessages = messages.map((message) => message.toJson()).toList();
    await prefs.setString(_chatHistoryKey, jsonEncode(encodedMessages));
  }

  // Load chat history from device storage
  Future<List<Message>> loadChatHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final savedData = prefs.getString(_chatHistoryKey);
    if (savedData == null) return [];
    final decodedMessages = List<Map<String, dynamic>>.from(jsonDecode(savedData));
    return decodedMessages.map((json) => Message.fromJson(json)).toList();
  }

  // Clear chat history
  Future<void> clearChatHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_chatHistoryKey);
  }
}