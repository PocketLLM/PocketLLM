import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../services/chat_history_service.dart';
import '../../services/theme_service.dart';
import '../models.dart';

class ChatHistory extends StatefulWidget {
  final Function(String conversationId)? onConversationSelected;
  
  const ChatHistory({Key? key, this.onConversationSelected}) : super(key: key);

  @override
  _ChatHistoryState createState() => _ChatHistoryState();
}

class _ChatHistoryState extends State<ChatHistory>
    with SingleTickerProviderStateMixin {
  final ChatHistoryService _chatHistoryService = ChatHistoryService();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  List<Conversation> _conversations = [];
  List<Conversation> _filteredConversations = [];
  final List<String> _recentQueries = [];

  bool _isLoading = true;
  bool _showNoResults = false;
  String? _selectedConversationId;

  late final AnimationController _pageAnimationController;
  late final Animation<double> _pageOpacity;

  @override
  void initState() {
    super.initState();
    _pageAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _pageOpacity = CurvedAnimation(
      parent: _pageAnimationController,
      curve: Curves.easeInOut,
    );

    _searchController.addListener(_onSearchChanged);
    _searchFocusNode.addListener(_onSearchFocusChanged);
    _chatHistoryService.conversationsNotifier.addListener(_handleConversationUpdates);
    _chatHistoryService.activeConversationNotifier.addListener(_handleActiveConversationUpdates);
    _loadConversations();
  }

  @override
  void dispose() {
    _chatHistoryService.conversationsNotifier.removeListener(_handleConversationUpdates);
    _chatHistoryService.activeConversationNotifier.removeListener(_handleActiveConversationUpdates);
    _searchController.removeListener(_onSearchChanged);
    _searchFocusNode.removeListener(_onSearchFocusChanged);
    _searchController.dispose();
    _searchFocusNode.dispose();
    _pageAnimationController.dispose();
    super.dispose();
  }

  void _handleConversationUpdates() {
    final conversations = _chatHistoryService.conversationsNotifier.value;
    setState(() {
      _conversations = conversations;
      _isLoading = false;
    });
    _applyFilters();
  }

  void _handleActiveConversationUpdates() {
    final activeConversation = _chatHistoryService.activeConversationNotifier.value;
    if (!mounted) return;
    setState(() {
      _selectedConversationId = activeConversation?.id;
    });
  }

  Future<void> _loadConversations() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final conversations = await _chatHistoryService.loadConversations();
      if (!mounted) return;
      setState(() {
        _conversations = conversations;
        _isLoading = false;
        _selectedConversationId =
            _chatHistoryService.activeConversationNotifier.value?.id;
      });
      _applyFilters(shouldAnimate: true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load chat history: $e')),
      );
    }
  }

  void _onSearchChanged() {
    _applyFilters();
  }

  void _onSearchFocusChanged() {
    if (mounted) setState(() {});
  }

  void _applyFilters({bool shouldAnimate = false}) {
    final query = _searchController.text.trim().toLowerCase();

    List<Conversation> filtered;
    if (query.isEmpty) {
      filtered = List.from(_conversations);
    } else {
      filtered = _conversations.where((conversation) {
        final titleMatch = conversation.title.toLowerCase().contains(query);
        final messageMatch = conversation.messages.any(
          (message) => message.content.toLowerCase().contains(query),
        );
        return titleMatch || messageMatch;
      }).toList();
    }

    setState(() {
      _filteredConversations = filtered;
      _showNoResults = query.isNotEmpty && filtered.isEmpty;
    });

    if (shouldAnimate) {
      _pageAnimationController.forward(from: 0.0);
    }
  }

  void _addRecentQuery(String query) {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return;
    setState(() {
      _recentQueries.remove(trimmed);
      _recentQueries.insert(0, trimmed);
      if (_recentQueries.length > 6) {
        _recentQueries.removeRange(6, _recentQueries.length);
      }
    });
  }

  Future<void> _deleteConversation(String conversationId) async {
    try {
      await _chatHistoryService.deleteConversation(conversationId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Conversation deleted')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete conversation: $e')),
      );
    }
  }

  Future<void> _clearAllConversations() async {
    final themeColors = ThemeService().colorScheme;
    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Container(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
            decoration: BoxDecoration(
              color: themeColors.surface,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: themeColors.shadow.withOpacity(0.12),
                  blurRadius: 30,
                  offset: const Offset(0, 24),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: themeColors.primary.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(
                        Icons.delete_sweep_rounded,
                        color: themeColors.primary,
                        size: 26,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            'Clear All History',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(height: 6),
                          Text(
                            'Are you sure you want to remove every conversation from your history? This action cannot be undone.',
                            style: TextStyle(fontSize: 14, height: 1.3),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context, false),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: themeColors.onSurface,
                          side: BorderSide(color: themeColors.divider.withOpacity(0.6)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context, true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: themeColors.primary,
                          foregroundColor: themeColors.onPrimary,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Text('Yes, Clear All'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );

    if (confirmed == true) {
      try {
        await _chatHistoryService.clearAllConversations();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Chat history cleared')),
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to clear conversations: $e')),
        );
      }
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today, ${DateFormat.jm().format(date)}';
    } else if (difference.inDays == 1) {
      return 'Yesterday, ${DateFormat.jm().format(date)}';
    } else if (difference.inDays < 7) {
      return DateFormat('EEEE, h:mm a').format(date);
    } else {
      return DateFormat('MMM d, y').format(date);
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeColors = ThemeService().colorScheme;

    return Scaffold(
      backgroundColor: themeColors.background,
      body: SafeArea(
        child: FadeTransition(
          opacity: _pageOpacity,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(
                        Icons.arrow_back_rounded,
                        color: themeColors.onSurface,
                      ),
                      tooltip: 'Back',
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'History',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                              color: themeColors.onSurface,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _conversations.isEmpty
                                ? 'You haven\'t started a conversation yet'
                                : '${_conversations.length} conversation${_conversations.length == 1 ? '' : 's'} saved',
                            style: TextStyle(
                              fontSize: 13,
                              color: themeColors.onSurface.withOpacity(0.6),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (_conversations.isNotEmpty)
                      TextButton.icon(
                        onPressed: _clearAllConversations,
                        style: TextButton.styleFrom(
                          foregroundColor: themeColors.primary,
                          textStyle: const TextStyle(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        icon: const Icon(Icons.auto_delete_rounded, size: 18),
                        label: const Text('Clear All'),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  decoration: BoxDecoration(
                    color: themeColors.surface,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: themeColors.shadow.withOpacity(0.08),
                        blurRadius: 18,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _searchController,
                    focusNode: _searchFocusNode,
                    textInputAction: TextInputAction.search,
                    onSubmitted: _addRecentQuery,
                    decoration: InputDecoration(
                      hintText: 'Search your history',
                      hintStyle: TextStyle(
                        color: themeColors.hint,
                        fontSize: 15,
                      ),
                      prefixIcon: Icon(
                        Icons.search_rounded,
                        color: themeColors.onSurface.withOpacity(0.55),
                      ),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: Icon(
                                Icons.close_rounded,
                                color: themeColors.onSurface.withOpacity(0.45),
                              ),
                              onPressed: () {
                                _searchController.clear();
                                _applyFilters();
                              },
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 16,
                        horizontal: 12,
                      ),
                    ),
                  ),
                ),
              ),
              if (_searchFocusNode.hasFocus &&
                  _recentQueries.isNotEmpty &&
                  _searchController.text.isEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: themeColors.surface,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
                          child: Text(
                            'Previous search',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: themeColors.onSurface.withOpacity(0.7),
                            ),
                          ),
                        ),
                        ..._recentQueries.map(
                          (query) => ListTile(
                            contentPadding:
                                const EdgeInsets.symmetric(horizontal: 20),
                            title: Text(
                              query,
                              style: TextStyle(
                                fontSize: 15,
                                color: themeColors.onSurface,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            leading: Icon(
                              Icons.history_rounded,
                              color: themeColors.onSurface.withOpacity(0.5),
                            ),
                            trailing: IconButton(
                              icon: Icon(
                                Icons.close_rounded,
                                size: 18,
                                color: themeColors.onSurface.withOpacity(0.35),
                              ),
                              onPressed: () {
                                setState(() {
                                  _recentQueries.remove(query);
                                });
                              },
                            ),
                            onTap: () {
                              _searchController.text = query;
                              _searchController.selection = TextSelection.fromPosition(
                                TextPosition(offset: query.length),
                              );
                              FocusScope.of(context).unfocus();
                              _applyFilters();
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 12),
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  switchInCurve: Curves.easeOut,
                  switchOutCurve: Curves.easeIn,
                  child: _isLoading
                      ? const Center(
                          child: CircularProgressIndicator(strokeWidth: 3),
                        )
                      : _conversations.isEmpty
                          ? _buildEmptyHistory(themeColors)
                          : _showNoResults
                              ? _buildNotFound(themeColors)
                              : RefreshIndicator(
                                  onRefresh: _loadConversations,
                                  color: themeColors.primary,
                                  child: ListView.separated(
                                    padding: const EdgeInsets.fromLTRB(
                                      20,
                                      8,
                                      20,
                                      32,
                                    ),
                                    physics:
                                        const AlwaysScrollableScrollPhysics(),
                                    itemCount: _filteredConversations.length,
                                    separatorBuilder: (_, __) => const SizedBox(
                                      height: 12,
                                    ),
                                    itemBuilder: (context, index) {
                                      final conversation =
                                          _filteredConversations[index];
                                      return _buildHistoryTile(
                                        context,
                                        conversation,
                                        themeColors,
                                      );
                                    },
                                  ),
                                ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHistoryTile(
    BuildContext context,
    Conversation conversation,
    AppColorScheme themeColors,
  ) {
    final lastMessage =
        conversation.messages.isNotEmpty ? conversation.messages.last : null;
    final isSelected = conversation.id == _selectedConversationId;

    return Dismissible(
      key: ValueKey(conversation.id),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) => _showDeleteConfirmation(conversation, themeColors),
      background: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: Colors.redAccent,
          borderRadius: BorderRadius.circular(22),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.delete_forever_rounded, color: Colors.white, size: 26),
            SizedBox(width: 6),
            Text(
              'Delete',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedConversationId = conversation.id;
          });
          _addRecentQuery(conversation.title);
          if (widget.onConversationSelected != null) {
            widget.onConversationSelected!(conversation.id);
          }
          Navigator.pop(context);
        },
        borderRadius: BorderRadius.circular(22),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
          decoration: BoxDecoration(
            color: isSelected
                ? themeColors.primary.withOpacity(0.08)
                : themeColors.surface,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: isSelected
                  ? themeColors.primary.withOpacity(0.4)
                  : themeColors.cardBorder.withOpacity(0.4),
            ),
            boxShadow: [
              BoxShadow(
                color: themeColors.shadow.withOpacity(0.06),
                blurRadius: 16,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: themeColors.primary.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  Icons.chat_bubble_outline_rounded,
                  color: themeColors.primary,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      conversation.title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: themeColors.onSurface,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (lastMessage != null && lastMessage.content.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          lastMessage.content,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13,
                            height: 1.4,
                            color: themeColors.onSurface.withOpacity(0.65),
                          ),
                        ),
                      ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Icon(
                          Icons.schedule_rounded,
                          size: 16,
                          color: themeColors.onSurface.withOpacity(0.45),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _formatDate(conversation.updatedAt),
                          style: TextStyle(
                            fontSize: 12,
                            color: themeColors.onSurface.withOpacity(0.5),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Icon(
                Icons.chevron_right_rounded,
                color: themeColors.onSurface.withOpacity(0.35),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<bool?> _showDeleteConfirmation(
    Conversation conversation,
    AppColorScheme themeColors,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Delete conversation?'),
          content: Text(
            'Remove "${conversation.title}" from your history? This cannot be undone.',
            style: const TextStyle(height: 1.3),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: themeColors.primary,
                foregroundColor: themeColors.onPrimary,
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      await _deleteConversation(conversation.id);
      return true;
    }
    return false;
  }

  Widget _buildEmptyHistory(AppColorScheme themeColors) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 36),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: themeColors.primary.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.hourglass_empty_rounded,
                size: 54,
                color: themeColors.primary,
              ),
            ),
            const SizedBox(height: 28),
            Text(
              'No conversations yet',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: themeColors.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              'Start a new chat to see it appear here. Your recent prompts and replies will show up for quick access.',
              style: TextStyle(
                fontSize: 14,
                height: 1.5,
                color: themeColors.onSurface.withOpacity(0.6),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotFound(AppColorScheme themeColors) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(32),
                color: themeColors.primary.withOpacity(0.1),
              ),
              child: Icon(
                Icons.sentiment_dissatisfied_rounded,
                size: 72,
                color: themeColors.primary,
              ),
            ),
            const SizedBox(height: 26),
            Text(
              'Not found',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: themeColors.onSurface,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              "We couldn't find any conversations that match your search. Try a different keyword.",
              style: TextStyle(
                fontSize: 14,
                height: 1.5,
                color: themeColors.onSurface.withOpacity(0.6),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}