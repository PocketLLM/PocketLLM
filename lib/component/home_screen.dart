import 'package:flutter/material.dart';
import 'custom_app_bar.dart';
import 'chat_interface.dart';
import 'sidebar.dart';
import '../pages/settings_page.dart';
import '../services/chat_history_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Reference to the ChatInterface
  final GlobalKey<ChatInterfaceState> _chatInterfaceKey = GlobalKey();
  final ChatHistoryService _chatHistoryService = ChatHistoryService();

  void _openSettings(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SettingsPage()),
    );
  }
  
  void _onConversationSelected(String conversationId) {
    // This function will be called when a conversation is selected from the sidebar
    if (_chatInterfaceKey.currentState != null) {
      // Use the ChatInterface's method to switch to the selected conversation
      _chatInterfaceKey.currentState!.switchChat(conversationId);
    } else {
      // Fallback if state is not available
      _chatHistoryService.setActiveConversation(conversationId);
    }
    
    // Close the drawer if it's open and Navigator can pop
    if (Navigator.canPop(context)) {
      Navigator.of(context).pop();
    }
  }

  // Method to create a new chat
  void _createNewChat() {
    if (_chatInterfaceKey.currentState != null) {
      _chatInterfaceKey.currentState!.createNewChat();
    } else {
      // Fallback if state is not available
      _chatHistoryService.createConversation();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        appName: 'PocketLLM',
        onSettingsPressed: () => _openSettings(context),
        onNewChatPressed: _createNewChat,
      ),
      drawer: Sidebar(
        onConversationSelected: _onConversationSelected,
      ),
      body: ChatInterface(key: _chatInterfaceKey),
    );
  }
}
