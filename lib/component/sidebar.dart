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
    final colorScheme = ThemeService().colorScheme;
    return Column(
      children: [
        ListTile(
          leading: Icon(
            Icons.chat_bubble_outline,
            color: colorScheme.onSurface.withOpacity(0.7),
            size: 22,
          ),
          title: Text(
            'Chat History',
            style: TextStyle(
              color: colorScheme.onSurface,
              fontSize: 15,
              fontWeight: FontWeight.w400,
            ),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: Icon(
                  Icons.add,
                  color: colorScheme.onSurface.withOpacity(0.7),
                  size: 22,
                ),
                onPressed: _createNewChat,
                tooltip: 'New Chat',
              ),
              IconButton(
                icon: Icon(
                  isHistoryExpanded ? Icons.expand_less : Icons.expand_more,
                  color: colorScheme.onSurface.withOpacity(0.7),
                  size: 22,
                ),
                onPressed: () {
                  setState(() {
                    isHistoryExpanded = !isHistoryExpanded;
                  });
                },
                tooltip: isHistoryExpanded ? 'Hide recent chats' : 'Show recent chats',
              ),
            ],
          ),
          contentPadding: EdgeInsets.symmetric(horizontal: 24),
          dense: true,
          onTap: _openChatHistoryPage,
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
                        color: colorScheme.primary,
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
                          color: colorScheme.onSurface.withOpacity(0.5),
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
                                  color: colorScheme.onSurface,
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
                              selectedTileColor: colorScheme.primary.withOpacity(0.1),
                              onTap: () {
                                _selectConversation(conversation.id);
                              },
                              trailing: IconButton(
                                icon: Icon(
                                  Icons.delete_outline,
                                  size: 18,
                                  color: colorScheme.onSurface.withOpacity(0.6),
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
                                color: colorScheme.primary,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            dense: true,
                            onTap: _openChatHistoryPage,
                            trailing: Icon(Icons.chevron_right, color: colorScheme.primary),
                          ),
                      ],
                    ),
      ],
    );
  }

  void _openChatHistoryPage() {
    final navigator = Navigator.of(context);
    if (navigator.canPop()) {
      navigator.pop();
    }
    Future.microtask(() {
      navigator.push(
        MaterialPageRoute(
          builder: (context) => ChatHistory(
            onConversationSelected: (id) {
              _selectConversation(id);
            },
          ),
        ),
      );
    });
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
      
      // Update the local selection state first
      setState(() {
        _selectedConversationId = conversationId;
      });
      
      // Call the callback if provided
      if (widget.onConversationSelected != null) {
        widget.onConversationSelected!(conversationId);
      } else {
        // If no callback, set the active conversation directly
        _chatHistoryService.setActiveConversation(conversationId);
      }
      
      // Only pop the navigator if the context is still mounted and drawer is open
      if (Navigator.canPop(context)) {
        // Use a short delay to allow the state to update before closing the drawer
        Future.delayed(Duration(milliseconds: 50), () {
          if (context.mounted && Navigator.canPop(context)) {
            Navigator.of(context).pop();
          }
        });
      }
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
        final colorScheme = ThemeService().colorScheme;
        return Drawer(
          backgroundColor: colorScheme.surface,
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
                          color: colorScheme.primary,
                        ),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: colorScheme.inputBorder),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: TextField(
                          decoration: InputDecoration(
                            hintText: 'Search...',
                            hintStyle: TextStyle(color: colorScheme.hint),
                            prefixIcon: Icon(Icons.search, color: colorScheme.onSurface.withOpacity(0.6)),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          ),
                          style: TextStyle(color: colorScheme.inputText),
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
                    color: colorScheme.cardBackground,
                    border: Border.all(color: colorScheme.cardBorder),
                  ),
                  child: ListTile(
                    leading: Icon(
                      ThemeService().isDarkMode ? Icons.light_mode : Icons.dark_mode_outlined,
                      color: colorScheme.onSurface,
                      size: 20,
                    ),
                    title: Text(
                      'Dark Mode',
                      style: TextStyle(
                        color: colorScheme.onSurface,
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
    final colorScheme = ThemeService().colorScheme;
    return ListTile(
      leading: Icon(
        icon,
        color: colorScheme.onSurface.withOpacity(0.7),
        size: 22,
      ),
      title: Text(
        title,
        style: TextStyle(
          color: colorScheme.onSurface,
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