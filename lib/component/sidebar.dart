/// File Overview:
/// - Purpose: Drawer navigation housing chat history shortcuts and links to
///   other pages.
/// - Backend Migration: Keep but update data sources (history, docs) to use
///   backend services.
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../component/appbar/about.dart';
import '../component/appbar/chat_history.dart';
import '../component/models.dart';
import '../pages/config_page.dart';
import '../pages/docs_page.dart';
import '../pages/library_page.dart';
import '../pages/settings_page.dart';
import '../services/chat_history_service.dart';
import '../services/theme_service.dart';
import '../theme/app_colors.dart';

class Sidebar extends StatefulWidget {
  final Function(String conversationId)? onConversationSelected;

  const Sidebar({Key? key, this.onConversationSelected}) : super(key: key);

  @override
  _SidebarState createState() => _SidebarState();
}

class _SidebarState extends State<Sidebar> {
  bool isHistoryExpanded = false;
  final ChatHistoryService _chatHistoryService = ChatHistoryService();
  final TextEditingController _searchController = TextEditingController();
  List<Conversation> _recentConversations = [];
  bool _isLoading = true;
  String? _selectedConversationId;
  String _searchQuery = '';

  List<Conversation> get _filteredConversations {
    final query = _searchQuery.trim().toLowerCase();
    if (query.isEmpty) {
      return _recentConversations;
    }

    return _recentConversations
        .where((conversation) => conversation.title.toLowerCase().contains(query))
        .toList();
  }

  @override
  void initState() {
    super.initState();
    _loadConversations();

    _chatHistoryService.conversationsNotifier.addListener(_onConversationsChanged);
    _chatHistoryService.activeConversationNotifier.addListener(_onActiveConversationChanged);
  }

  @override
  void dispose() {
    _chatHistoryService.conversationsNotifier.removeListener(_onConversationsChanged);
    _chatHistoryService.activeConversationNotifier.removeListener(_onActiveConversationChanged);
    _searchController.dispose();
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

  void _dismissKeyboard() {
    FocusScope.of(context).unfocus();
  }

  void _showComingSoonMessage() {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text('Dark mode will be available in a future update.'),
        ),
      );
  }

  void _closeDrawer() {
    _dismissKeyboard();
    final navigator = Navigator.of(context);
    if (navigator.canPop()) {
      navigator.pop();
    }
  }

  void _openPage(Widget page) {
    _pushAfterDrawerClose(
      MaterialPageRoute(builder: (context) => page),
    );
  }

  void _openChatHistoryPage() {
    _pushAfterDrawerClose(
      MaterialPageRoute(
        builder: (context) => ChatHistory(
          onConversationSelected: (id) {
            _selectConversation(id);
          },
        ),
      ),
    );
  }

  void _pushAfterDrawerClose(Route route) {
    _dismissKeyboard();
    final navigator = Navigator.of(context);
    final rootNavigator = Navigator.of(context, rootNavigator: true);

    if (navigator.canPop()) {
      navigator.pop();
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      rootNavigator.push(route);
    });
  }

  void _selectConversation(String conversationId) {
    try {
      final conversation = _chatHistoryService.getConversation(conversationId);
      if (conversation == null) {
        debugPrint('Error: Conversation not found with ID: $conversationId');
        return;
      }

      _dismissKeyboard();

      setState(() {
        _selectedConversationId = conversationId;
      });

      if (widget.onConversationSelected != null) {
        widget.onConversationSelected!(conversationId);
      } else {
        _chatHistoryService.setActiveConversation(conversationId);
      }

      if (Navigator.canPop(context)) {
        Future.delayed(const Duration(milliseconds: 50), () {
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

      if (_selectedConversationId == conversationId) {
        setState(() {
          _selectedConversationId = null;
        });
      }
    }
  }

  String _formatConversationTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.isNegative || difference.inMinutes < 1) {
      return 'Just now';
    }
    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    }
    if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    }
    if (difference.inDays == 1) {
      return 'Yesterday';
    }
    if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    }

    const monthNames = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    final month = monthNames[timestamp.month - 1];
    final day = timestamp.day;

    if (timestamp.year == now.year) {
      return '$month $day';
    }

    return '$month $day, ${timestamp.year}';
  }

  Widget _buildHeader(AppColorScheme colorScheme) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 56,
                width: 56,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      colorScheme.primary.withOpacity(0.85),
                      colorScheme.primaryVariant.withOpacity(0.8),
                    ],
                  ),
                ),
                child: CircleAvatar(
                  backgroundColor: Colors.transparent,
                  child: Icon(
                    Icons.person_outline,
                    color: colorScheme.onPrimary,
                    size: 28,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hello,',
                      style: TextStyle(
                        color: colorScheme.onSurface.withOpacity(0.7),
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'PocketLLM',
                      style: TextStyle(
                        color: colorScheme.onSurface,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Curate, manage, and revisit your AI chats.',
                      style: TextStyle(
                        color: colorScheme.onSurface.withOpacity(0.6),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        IconButton(
          tooltip: 'App information',
          icon: Icon(Icons.info_outline, color: colorScheme.onSurface.withOpacity(0.6)),
          onPressed: () => _openPage(About()),
        ),
        const SizedBox(width: 4),
        IconButton(
          tooltip: 'Close sidebar',
          icon: Icon(Icons.close_rounded, color: colorScheme.onSurface.withOpacity(0.6)),
          onPressed: _closeDrawer,
        ),
      ],
    );
  }

  Widget _buildThemeToggle(ThemeService themeService, AppColorScheme colorScheme) {
    final isDark = themeService.isDarkMode;

    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colorScheme.cardBorder.withOpacity(0.6)),
      ),
      child: Row(
        children: [
          _ThemeToggleButton(
            label: 'Light',
            icon: Icons.light_mode,
            selected: !isDark,
            colorScheme: colorScheme,
            onTap: () {
              themeService.setThemeMode(AppThemeMode.light);
            },
          ),
          const SizedBox(width: 8),
          _ThemeToggleButton(
            label: 'Dark',
            icon: Icons.dark_mode,
            selected: isDark,
            colorScheme: colorScheme,
            onTap: _showComingSoonMessage,
          ),
        ],
      ),
    );
  }

  Widget _buildSearchField(AppColorScheme colorScheme) {
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colorScheme.cardBorder.withOpacity(0.6)),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow,
            blurRadius: 22,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (value) {
          setState(() {
            _searchQuery = value;
          });
        },
        style: TextStyle(color: colorScheme.inputText, fontSize: 15),
        decoration: InputDecoration(
          hintText: 'Search conversations',
          hintStyle: TextStyle(color: colorScheme.hint),
          prefixIcon: Icon(Icons.search, color: colorScheme.onSurface.withOpacity(0.6)),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  tooltip: 'Clear search',
                  icon: Icon(Icons.close, color: colorScheme.onSurface.withOpacity(0.5)),
                  onPressed: () {
                    _searchController.clear();
                    setState(() {
                      _searchQuery = '';
                    });
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        ),
      ),
    );
  }

  Widget _buildNavigationSection(AppColorScheme colorScheme) {
    final navigationItems = [
      _NavigationItem(
        icon: Icons.home_outlined,
        label: 'Home',
        subtitle: 'Return to your main workspace',
        onTap: _closeDrawer,
      ),
      _NavigationItem(
        icon: Icons.chat_bubble_outline,
        label: 'Chat History',
        subtitle: 'Browse all previous conversations',
        onTap: _openChatHistoryPage,
      ),
      _NavigationItem(
        icon: Icons.store_outlined,
        label: 'Library',
        subtitle: 'Explore bundled model presets',
        onTap: () => _openPage(LibraryPage()),
      ),
      _NavigationItem(
        icon: Icons.settings_outlined,
        label: 'Settings',
        subtitle: 'Adjust providers and preferences',
        onTap: () => _openPage(const SettingsPage()),
      ),
      _NavigationItem(
        icon: Icons.description_outlined,
        label: 'Documentation',
        subtitle: 'Read integration and API guides',
        onTap: () => _openPage(const DocsPage()),
      ),
      _NavigationItem(
        icon: Icons.computer_outlined,
        label: 'System Config',
        subtitle: 'Manage backend and deployment',
        onTap: () => _openPage(ConfigPage(appName: 'PocketLLM')),
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Navigation',
          style: TextStyle(
            color: colorScheme.onSurface,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        ...navigationItems.map(
          (item) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _NavigationTile(item: item, colorScheme: colorScheme),
          ),
        ),
      ],
    );
  }

  Widget _buildChatHistorySection(AppColorScheme colorScheme) {
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colorScheme.cardBorder.withOpacity(0.6)),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(Icons.chat_bubble_outline, color: colorScheme.primary, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: _openChatHistoryPage,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Chat history',
                            style: TextStyle(
                              color: colorScheme.onSurface,
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Review previous conversations in detail.',
                            style: TextStyle(
                              color: colorScheme.onSurface.withOpacity(0.6),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              IconButton(
                tooltip: isHistoryExpanded ? 'Hide recent chats' : 'Show recent chats',
                icon: Icon(
                  isHistoryExpanded ? Icons.expand_less : Icons.expand_more,
                  color: colorScheme.onSurface.withOpacity(0.6),
                ),
                onPressed: () {
                  setState(() {
                    isHistoryExpanded = !isHistoryExpanded;
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          AnimatedCrossFade(
            crossFadeState: isHistoryExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 200),
            sizeCurve: Curves.easeInOut,
            firstChild: const SizedBox.shrink(),
            secondChild: _buildConversationList(colorScheme),
          ),
        ],
      ),
    );
  }

  Widget _buildConversationList(AppColorScheme colorScheme) {
    if (_isLoading) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
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
      );
    }

    final conversations = _filteredConversations;
    if (conversations.isEmpty) {
      return _buildEmptyState(colorScheme);
    }

    final visibleConversations = conversations.take(5).toList();

    return Column(
      children: [
        ...visibleConversations.map((conversation) => _buildConversationTile(conversation, colorScheme)),
        if (conversations.length > visibleConversations.length)
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: _openChatHistoryPage,
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                foregroundColor: colorScheme.primary,
                textStyle: const TextStyle(fontWeight: FontWeight.w600),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('View full history'),
                  const SizedBox(width: 4),
                  Icon(Icons.arrow_forward_rounded, size: 16, color: colorScheme.primary),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildConversationTile(Conversation conversation, AppColorScheme colorScheme) {
    final isSelected = conversation.id == _selectedConversationId;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _selectConversation(conversation.id),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: isSelected
                  ? colorScheme.primary.withOpacity(0.12)
                  : colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected
                    ? colorScheme.primary.withOpacity(0.6)
                    : colorScheme.cardBorder.withOpacity(0.6),
              ),
            ),
            child: Row(
              children: [
                Container(
                  height: 38,
                  width: 38,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: isSelected
                        ? colorScheme.primary.withOpacity(0.18)
                        : colorScheme.primary.withOpacity(0.08),
                  ),
                  child: Icon(
                    Icons.forum_outlined,
                    color: isSelected ? colorScheme.primary : colorScheme.onSurface.withOpacity(0.7),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        conversation.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: isSelected ? colorScheme.primary : colorScheme.onSurface,
                          fontSize: 14.5,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatConversationTimestamp(conversation.updatedAt),
                        style: TextStyle(
                          color: colorScheme.onSurface.withOpacity(0.6),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Delete conversation',
                  splashRadius: 18,
                  padding: EdgeInsets.zero,
                  icon: Icon(
                    Icons.delete_outline,
                    size: 18,
                    color: isSelected
                        ? colorScheme.primary
                        : colorScheme.onSurface.withOpacity(0.6),
                  ),
                  onPressed: () => _deleteConversation(conversation.id),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(AppColorScheme colorScheme) {
    final hasConversations = _recentConversations.isNotEmpty;
    final message = hasConversations
        ? 'No conversations match "${_searchQuery.trim()}".'
        : 'Start a new conversation to see it listed here.';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.cardBorder.withOpacity(0.6)),
      ),
      child: Text(
        message,
        style: TextStyle(
          color: colorScheme.onSurface.withOpacity(0.6),
          fontSize: 13,
        ),
      ),
    );
  }

  Widget _buildFooter(AppColorScheme colorScheme) {
    final year = DateTime.now().year;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Divider(color: colorScheme.divider, height: 1),
        const SizedBox(height: 16),
        Text(
          'PocketLLM',
          style: TextStyle(
            color: colorScheme.onSurface,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '© $year PocketLLM. All rights reserved.',
          style: TextStyle(
            color: colorScheme.onSurface.withOpacity(0.6),
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: ThemeService(),
      builder: (context, _) {
        final themeService = ThemeService();
        final colorScheme = themeService.colorScheme;
        final isDark = themeService.isDarkMode;
        final mediaQuery = MediaQuery.of(context);

        return Drawer(
          width: mediaQuery.size.width,
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final availableWidth = constraints.maxWidth;
                final horizontalMargin = math.max(availableWidth * 0.04, 16.0);
                final contentWidth = availableWidth - (horizontalMargin * 2);
                final drawerContentWidth = contentWidth > 0 ? contentWidth : availableWidth;

                return Align(
                  alignment: Alignment.center,
                  child: SizedBox(
                    width: drawerContentWidth,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16.0),
                      child: Container(
                        decoration: BoxDecoration(
                          color: colorScheme.surface,
                          borderRadius: BorderRadius.circular(28),
                          border: Border.all(
                            color: colorScheme.cardBorder.withOpacity(isDark ? 0.5 : 0.3),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: colorScheme.shadow.withOpacity(isDark ? 0.35 : 0.18),
                              blurRadius: 38,
                              offset: const Offset(0, 18),
                            ),
                          ],
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildHeader(colorScheme),
                                  const SizedBox(height: 24),
                                  _buildThemeToggle(themeService, colorScheme),
                                ],
                              ),
                            ),
                            const SizedBox(height: 24),
                            Expanded(
                              child: SingleChildScrollView(
                                physics: const BouncingScrollPhysics(),
                                padding: const EdgeInsets.symmetric(horizontal: 24),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildSearchField(colorScheme),
                                    const SizedBox(height: 24),
                                    _buildNavigationSection(colorScheme),
                                    const SizedBox(height: 24),
                                    // _buildChatHistorySection(colorScheme), // Removed duplicate chat history section
                                  ],
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                              child: _buildFooter(colorScheme),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }
}

class _NavigationItem {
  const _NavigationItem({
    required this.icon,
    required this.label,
    this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String? subtitle;
  final VoidCallback onTap;
}

class _NavigationTile extends StatelessWidget {
  const _NavigationTile({required this.item, required this.colorScheme});

  final _NavigationItem item;
  final AppColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: item.onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: colorScheme.cardBorder.withOpacity(0.6)),
          ),
          child: Row(
            children: [
              Container(
                height: 44,
                width: 44,
                decoration: BoxDecoration(
                  color: colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(item.icon, color: colorScheme.primary, size: 22),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.label,
                      style: TextStyle(
                        color: colorScheme.onSurface,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (item.subtitle != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        item.subtitle!,
                        style: TextStyle(
                          color: colorScheme.onSurface.withOpacity(0.6),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: colorScheme.onSurface.withOpacity(0.4)),
            ],
          ),
        ),
      ),
    );
  }
}

class _ThemeToggleButton extends StatelessWidget {
  const _ThemeToggleButton({
    required this.label,
    required this.icon,
    required this.selected,
    required this.colorScheme,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final AppColorScheme colorScheme;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: selected ? null : onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: selected ? colorScheme.primary.withOpacity(0.12) : Colors.transparent,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: selected
                    ? colorScheme.primary.withOpacity(0.6)
                    : colorScheme.cardBorder.withOpacity(0.6),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 18,
                  color: selected ? colorScheme.primary : colorScheme.onSurface.withOpacity(0.6),
                ),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: TextStyle(
                    color: selected ? colorScheme.primary : colorScheme.onSurface.withOpacity(0.7),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

