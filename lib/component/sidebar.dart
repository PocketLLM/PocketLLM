import 'package:flutter/material.dart';
import '../pages/library_page.dart';
import '../pages/config_page.dart';
import '../pages/settings_page.dart';
import '../pages/docs_page.dart';
import '../component/appbar/about.dart';
import '../component/appbar/chat_history.dart';
import '../services/theme_service.dart';
import '../services/chat_history_service.dart';
import '../component/models.dart';

class Sidebar extends StatefulWidget {
  final Function(String conversationId)? onConversationSelected;
  
  const Sidebar({Key? key, this.onConversationSelected}) : super(key: key);
  
  @override
  _SidebarState createState() => _SidebarState();
}

class _SidebarState extends State<Sidebar> {
  bool isHistoryExpanded = false;
  final ChatHistoryService _chatHistoryService = ChatHistoryService();
  List<Conversation> _recentConversations = [];
  bool _isLoading = true;
  String? _selectedConversationId;

  @override
  void initState() {
    super.initState();
    _loadConversations();
    
    // Listen for changes to the conversations list
    _chatHistoryService.conversationsNotifier.addListener(_onConversationsChanged);
    
    // Listen for changes to the active conversation
    _chatHistoryService.activeConversationNotifier.addListener(_onActiveConversationChanged);
  }
  
  @override
  void dispose() {
    _chatHistoryService.conversationsNotifier.removeListener(_onConversationsChanged);
    _chatHistoryService.activeConversationNotifier.removeListener(_onActiveConversationChanged);
    super.dispose();
  }
  
  void _onConversationsChanged() {
    setState(() {
      _recentConversations = _chatHistoryService.conversationsNotifier.value;
      _isLoading = false;
    });
  }
  
  void _onActiveConversationChanged() {
    final activeConversation = _chatHistoryService.activeConversationNotifier.value;
    setState(() {
      _selectedConversationId = activeConversation?.id;
    });
  }

  Future<void> _loadConversations() async {
    try {
      final conversations = await _chatHistoryService.loadConversations();
      setState(() {
        _recentConversations = conversations;
        _isLoading = false;
      });
      
      // Get the currently active conversation
      final activeConversation = _chatHistoryService.activeConversationNotifier.value;
      if (activeConversation != null) {
        setState(() {
          _selectedConversationId = activeConversation.id;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Widget _buildChatHistorySection() {
    final isDark = ThemeService().isDarkMode;
    return Column(
      children: [
        ListTile(
          leading: Icon(
            Icons.chat_bubble_outline,
            color: isDark ? Colors.white70 : Colors.grey[600],
            size: 22,
          ),
          title: Text(
            'Chat History',
            style: TextStyle(
              color: isDark ? Colors.white70 : Colors.grey[800],
              fontSize: 15,
              fontWeight: FontWeight.w400,
            ),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Add new chat button
              IconButton(
                icon: Icon(
                  Icons.add,
                  color: isDark ? Colors.white70 : Colors.grey[600],
                  size: 22,
                ),
                onPressed: _createNewChat,
                tooltip: 'New Chat',
              ),
              Icon(
                isHistoryExpanded ? Icons.expand_less : Icons.expand_more,
                color: isDark ? Colors.white70 : Colors.grey[600],
              ),
            ],
          ),
          contentPadding: EdgeInsets.symmetric(horizontal: 24),
          dense: true,
          onTap: () {
            setState(() {
              isHistoryExpanded = !isHistoryExpanded;
            });
          },
        ),
        if (isHistoryExpanded)
          _isLoading
              ? Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Center(
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.deepPurple,
                      ),
                    ),
                  ),
                )
              : _recentConversations.isEmpty
                  ? Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text(
                        'No recent chats',
                        style: TextStyle(
                          color: Colors.grey[500],
                          fontSize: 14,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    )
                  : Column(
                      children: [
                        ..._recentConversations.take(5).map((conversation) => ListTile(
                              contentPadding: EdgeInsets.only(left: 56, right: 24),
                              title: Text(
                                conversation.title,
                                style: TextStyle(
                                  color: isDark ? Colors.white70 : Colors.grey[800],
                                  fontSize: 14,
                                  fontWeight: _selectedConversationId == conversation.id
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              dense: true,
                              selected: _selectedConversationId == conversation.id,
                              selectedTileColor: Colors.deepPurple.withOpacity(0.1),
                              onTap: () {
                                _selectConversation(conversation.id);
                              },
                              trailing: IconButton(
                                icon: Icon(
                                  Icons.delete_outline,
                                  size: 18,
                                  color: isDark ? Colors.white60 : Colors.grey[600],
                                ),
                                onPressed: () => _deleteConversation(conversation.id),
                              ),
                            )),
                        if (_recentConversations.length > 5)
                          ListTile(
                            contentPadding: EdgeInsets.only(left: 56, right: 24),
                            title: Text(
                              'View All Chats',
                              style: TextStyle(
                                color: Colors.deepPurple,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            dense: true,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ChatHistory(
                                    onConversationSelected: (id) {
                                      _selectConversation(id);
                                    },
                                  ),
                                ),
                              );
                            },
                            trailing: Icon(Icons.chevron_right, color: Colors.deepPurple),
                          ),
                      ],
                    ),
      ],
    );
  }
  
  void _createNewChat() async {
    // Create a new conversation
    final conversation = await _chatHistoryService.createConversation();
    
    // Select the new conversation
    _selectConversation(conversation.id);
  }
  
  void _selectConversation(String conversationId) {
    try {
      // Get the conversation from the service
      final conversation = _chatHistoryService.getConversation(conversationId);
      if (conversation == null) {
        debugPrint('Error: Conversation not found with ID: $conversationId');
        return;
      }
      
      // Set the active conversation in the service
      _chatHistoryService.setActiveConversation(conversationId);
      
      // Update the local selection state
      setState(() {
        _selectedConversationId = conversationId;
      });
      
      // Call the callback if provided
      if (widget.onConversationSelected != null) {
        widget.onConversationSelected!(conversationId);
      }
      
      // Close the drawer
      Navigator.of(context).pop();
    } catch (e) {
      debugPrint('Error selecting conversation: $e');
    }
  }
  
  Future<void> _deleteConversation(String conversationId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Conversation'),
        content: const Text('Are you sure you want to delete this conversation?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    
    if (confirmed == true) {
      await _chatHistoryService.deleteConversation(conversationId);
      
      // If the deleted conversation was selected, clear the selection
      if (_selectedConversationId == conversationId) {
        setState(() {
          _selectedConversationId = null;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Replace ValueListenableBuilder with AnimatedBuilder which works with ChangeNotifier
    return AnimatedBuilder(
      animation: ThemeService(),  // ThemeService extends ChangeNotifier so it works here
      builder: (context, _) {
        final isDark = ThemeService().isDarkMode;
        return Drawer(
          backgroundColor: isDark ? Colors.grey[900] : Colors.white,
          child: Column(
            children: [
              Expanded(
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: <Widget>[
                    Container(
                      padding: EdgeInsets.only(top: 50, bottom: 20, left: 20),
                      child: Text(
                        'PocketLLM',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF6B4EFF),
                        ),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.blue.shade100),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: TextField(
                          decoration: InputDecoration(
                            hintText: 'Search...',
                            prefixIcon: Icon(Icons.search, color: isDark ? Colors.grey[400] : Colors.grey),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          ),
                          style: TextStyle(color: isDark ? Colors.white : Colors.black),
                        ),
                      ),
                    ),
                    _buildChatHistorySection(),
                    _buildMenuItem(Icons.store_outlined, 'Library',
                        onTap: () => Navigator.push(context,
                            MaterialPageRoute(builder: (context) => LibraryPage()))),
                    _buildMenuItem(Icons.settings_outlined, 'Settings',
                        onTap: () => Navigator.push(context,
                            MaterialPageRoute(builder: (context) => SettingsPage()))),
                    _buildMenuItem(Icons.description_outlined, 'Documentation',
                        onTap: () => Navigator.push(
                            context, MaterialPageRoute(builder: (context) => const DocsPage()))),
                    _buildMenuItem(Icons.computer_outlined, 'System Config',
                        onTap: () => Navigator.push(context,
                            MaterialPageRoute(builder: (context) => ConfigPage(appName: 'PocketLLM')))),
                    _buildMenuItem(Icons.info_outline, 'Info',
                        onTap: () => Navigator.push(
                            context, MaterialPageRoute(builder: (context) => About()))),
                  ],
                ),
              ),
              SizedBox(height: 8),
              Padding(
                padding: EdgeInsets.only(bottom: 45),
                child: Container(
                  margin: EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: isDark ? Colors.grey[800] : Colors.grey[100],
                  ),
                  child: ListTile(
                    leading: Icon(
                      isDark ? Icons.light_mode : Icons.dark_mode_outlined,
                      color: isDark ? Colors.white : Colors.grey[700],
                      size: 20,
                    ),
                    title: Text(
                      'Dark Mode',
                      style: TextStyle(
                        color: isDark ? Colors.white : Colors.grey[700],
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    dense: true,
                    visualDensity: VisualDensity.compact,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    onTap: () async {
                      await ThemeService().toggleDarkMode();
                      // No need to call setState here as ValueListenableBuilder will rebuild
                    },
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMenuItem(IconData icon, String title, {VoidCallback? onTap}) {
    final isDark = ThemeService().isDarkMode;
    return ListTile(
      leading: Icon(
        icon,
        color: isDark ? Colors.white70 : Colors.grey[600],
        size: 22,
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isDark ? Colors.white70 : Colors.grey[800],
          fontSize: 15,
          fontWeight: FontWeight.w400,
        ),
      ),
      contentPadding: EdgeInsets.symmetric(horizontal: 24),
      dense: true,
      onTap: onTap,
    );
  }
}