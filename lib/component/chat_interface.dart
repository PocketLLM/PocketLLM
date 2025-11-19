/// File Overview:
/// - Purpose: Core chat UI handling message rendering, attachments, and direct
///   calls to various model/search services.
/// - Backend Migration: Substantially refactor; remove embedded API keys,
///   switch to backend chat/search endpoints, and simplify local state.
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:clipboard/clipboard.dart';
import 'models.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import '../services/model_state.dart';
import '../services/theme_service.dart';
import '../services/chat_history_service.dart';
import 'appbar/chat_history.dart';
import '../services/error_service.dart';
import '../services/search_service.dart';
import '../pages/search_settings_page.dart';
import '../theme/app_colors.dart';

part 'chat_interface_input.dart';

class ChatInterface extends StatefulWidget {
  const ChatInterface({Key? key}) : super(key: key);

  @override
  ChatInterfaceState createState() => ChatInterfaceState();
}

class ChatInterfaceState extends State<ChatInterface> {
  bool _showAttachmentOptions = false;
  final double _maxInputHeight = 120.0;
  final TextEditingController _messageController = TextEditingController();
  final FocusNode _composerFocusNode = FocusNode();
  List<Message> get _messages => _chatHistoryService.activeConversationNotifier.value?.messages ?? [];
  
  bool _isLoading = false;
  final ScrollController _scrollController = ScrollController();
  
  // Enhanced model management
  final ModelState _modelState = ModelState();
  final ChatHistoryService _chatHistoryService = ChatHistoryService();
  final ErrorService _errorService = ErrorService();
  
  // Model change tracking
  String? _lastUsedModelId;
  String? _conversationModelId;
  bool _showingModelChangeNotification = false;
  

  @override
  void initState() {
    super.initState();
    _initializeChat();
    _initializeModelTracking();
    
    // Add listener to update send button state
    _messageController.addListener(() {
      setState(() {}); // Trigger rebuild when text changes
    });
    
    // Listen for changes to the active conversation
    _chatHistoryService.activeConversationNotifier.addListener(_onActiveConversationChanged);
    
    // Listen for model changes with enhanced handling
    _modelState.selectedModelId.addListener(_onModelChanged);
    _modelState.addListener(_onModelStateChanged);
  }
  
  @override
  void dispose() {
    _chatHistoryService.activeConversationNotifier.removeListener(_onActiveConversationChanged);
    _modelState.selectedModelId.removeListener(_onModelChanged);
    _modelState.removeListener(_onModelStateChanged);
    _messageController.dispose();
    _composerFocusNode.dispose();
    super.dispose();
  }
  
  Future<void> _initializeModelTracking() async {
    // Initialize model tracking for the current conversation
    final activeConversation = _chatHistoryService.activeConversationNotifier.value;
    if (activeConversation != null) {
      _conversationModelId = activeConversation.modelId;
    }
    _lastUsedModelId = _modelState.selectedModelId.value;
  }
  
  void _onModelChanged() {
    final newModelId = _modelState.selectedModelId.value;
    final oldModelId = _lastUsedModelId;
    
    if (newModelId != oldModelId && mounted) {
      _handleModelChange(oldModelId, newModelId);
    }
    
    _lastUsedModelId = newModelId;
  }
  
  void _onModelStateChanged() {
    if (mounted) {
      setState(() {});
    }
  }
  
  void _onActiveConversationChanged() {
    // When the active conversation changes, update model tracking
    final activeConversation = _chatHistoryService.activeConversationNotifier.value;
    if (activeConversation != null) {
      _conversationModelId = activeConversation.modelId;
      
      // Check if conversation model differs from selected model
      final selectedModelId = _modelState.selectedModelId.value;
      if (_conversationModelId != null && 
          _conversationModelId != selectedModelId && 
          _messages.isNotEmpty) {
        _showModelMismatchNotification();
      }
    }
    
    setState(() {});
    _scrollToBottom();
  }
  
  Future<void> _handleModelChange(String? oldModelId, String? newModelId) async {
    if (newModelId == null) return;
    
    try {
      // Get model information
      final models = _modelState.availableModels.value;
      final newModel = models.firstWhere(
        (model) => model.id == newModelId,
        orElse: () => throw Exception('Model not found: $newModelId'),
      );
      
      // Check if there's an active conversation with messages
      final activeConversation = _chatHistoryService.activeConversationNotifier.value;
      final hasMessages = _messages.isNotEmpty;
      
      // Only show confirmation if there are messages and the model actually changed
      if (hasMessages && activeConversation != null && oldModelId != null && oldModelId != newModelId) {
        // Show confirmation dialog for active conversations
        final shouldContinue = await _showModelChangeConfirmation(oldModelId, newModel);
        if (!shouldContinue) {
          // Revert model selection
          if (oldModelId != null) {
            await _modelState.setSelectedModel(oldModelId);
          }
          return;
        }
        
        // Update conversation model tracking
        await _updateConversationModel(activeConversation.id, newModelId);
      }
      
      // Show model change notification (but not when selecting the same model)
      if (oldModelId != newModelId) {
        _displayModelChangeNotification(newModel);
      }
      
      // Log model change
      await _errorService.logError(
        'Model changed from ${oldModelId ?? 'none'} to $newModelId',
        null,
        type: ErrorType.unknown,
        severity: ErrorSeverity.low,
        context: 'ChatInterface._handleModelChange',
      );
      
    } catch (e, stackTrace) {
      await _errorService.logError(
        'Failed to handle model change: $e',
        stackTrace,
        type: ErrorType.unknown,
        context: 'ChatInterface._handleModelChange',
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to change model: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }
  
  Future<bool> _showModelChangeConfirmation(String? oldModelId, ModelConfig newModel) async {
    final models = _modelState.availableModels.value;
    final oldModel = oldModelId != null 
        ? models.firstWhere(
            (model) => model.id == oldModelId,
            orElse: () => ModelConfig(
              id: oldModelId,
              name: 'Unknown Model',
              provider: ModelProvider.openAI,
              model: 'unknown',
              baseUrl: '',
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            ),
          )
        : null;
    
    return await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: ThemeService().colorScheme.surface,
        title: Row(
          children: [
            Icon(
              Icons.swap_horiz,
              color: ThemeService().colorScheme.primary,
            ),
            const SizedBox(width: 8),
            Text(
              'Change Model?',
              style: TextStyle(color: ThemeService().colorScheme.onSurface),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'You have an active conversation with messages. Changing the model will affect future responses.',
              style: TextStyle(color: ThemeService().colorScheme.onSurface),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: ThemeService().colorScheme.cardBackground,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: ThemeService().colorScheme.cardBorder),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Text(
                        'From: ',
                        style: TextStyle(
                          color: ThemeService().colorScheme.onSurface.withOpacity(0.7),
                          fontSize: 12,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          oldModel?.name ?? 'No model',
                          style: TextStyle(
                            color: ThemeService().colorScheme.onSurface,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        'To: ',
                        style: TextStyle(
                          color: ThemeService().colorScheme.onSurface.withOpacity(0.7),
                          fontSize: 12,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          newModel.name,
                          style: TextStyle(
                            color: ThemeService().colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Note: Previous messages will remain unchanged, but new responses will use the selected model.',
              style: TextStyle(
                color: ThemeService().colorScheme.onSurface.withOpacity(0.6),
                fontSize: 12,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              'Cancel',
              style: TextStyle(color: ThemeService().colorScheme.onSurface.withOpacity(0.7)),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: ThemeService().colorScheme.primary,
              foregroundColor: ThemeService().colorScheme.onPrimary,
            ),
            child: const Text('Change Model'),
          ),
        ],
      ),
    ) ?? false;
  }
  
  void _displayModelChangeNotification(ModelConfig model) {
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              Icons.check_circle,
              color: ThemeService().colorScheme.onPrimary,
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Now using ${model.name}',
                style: TextStyle(color: ThemeService().colorScheme.onPrimary),
              ),
            ),
          ],
        ),
        backgroundColor: ThemeService().colorScheme.primary,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: 'View Health',
          textColor: ThemeService().colorScheme.onPrimary,
          onPressed: () => _showModelHealthDialog(model),
        ),
      ),
    );
  }
  
  void _showModelMismatchNotification() {
    if (!mounted || _showingModelChangeNotification) return;
    
    _showingModelChangeNotification = true;
    
    final models = _modelState.availableModels.value;
    final conversationModel = models.firstWhere(
      (model) => model.id == _conversationModelId,
      orElse: () => ModelConfig(
        id: _conversationModelId ?? '',
        name: 'Unknown Model',
        provider: ModelProvider.openAI,
        model: 'unknown',
        baseUrl: '',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    );
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Conversation model mismatch detected',
              style: TextStyle(
                color: ThemeService().colorScheme.onPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'This conversation was created with "${conversationModel.name}". '
              'Current model is "${models.firstWhere((m) => m.id == _modelState.selectedModelId.value, orElse: () => models.first).name}".',
              style: TextStyle(
                color: ThemeService().colorScheme.onPrimary,
                fontSize: 12,
              ),
            ),
          ],
        ),
        backgroundColor: ThemeService().colorScheme.primary,
        duration: const Duration(seconds: 5),
        action: SnackBarAction(
          label: 'Switch',
          textColor: ThemeService().colorScheme.onPrimary,
          onPressed: () {
            if (_conversationModelId != null) {
              _modelState.setSelectedModel(_conversationModelId!);
            }
          },
        ),
      ),
    );
    
    // Reset the flag after the notification duration
    Future.delayed(const Duration(seconds: 5), () {
      _showingModelChangeNotification = false;
    });
  }
  
  Future<void> _updateConversationModel(String conversationId, String modelId) async {
    try {
      await _chatHistoryService.updateConversationModel(conversationId, modelId);
      _conversationModelId = modelId;
    } catch (e, stackTrace) {
      await _errorService.logError(
        'Failed to update conversation model: $e',
        stackTrace,
        type: ErrorType.unknown,
        context: 'ChatInterface._updateConversationModel',
      );
    }
  }
  
  void _showModelHealthDialog(ModelConfig model) {
    // Implementation would show detailed model health information
  }
  
  Future<void> _initializeChat() async {
    try {
      await _chatHistoryService.loadConversations();
      var activeConversation = _chatHistoryService.activeConversationNotifier.value;
      if (activeConversation == null) {
        activeConversation = await _chatHistoryService.createConversation(
          modelId: _modelState.selectedModelId.value,
        );
      }
      _conversationModelId = activeConversation?.modelId;
    } catch (e, stackTrace) {
      await _errorService.logError(
        'Failed to initialize chat: $e',
        stackTrace,
        type: ErrorType.initialization,
        context: 'ChatInterface._initializeChat',
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to initialize chat: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
    }
  }
  
  void _scrollToBottom({bool animate = false}) {
    if (_scrollController.hasClients) {
      if (animate) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      } else {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
    }
  }
  
  Widget _buildHealthStatusRow(String label, String value, Color valueColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: TextStyle(
                color: ThemeService().colorScheme.onSurface.withOpacity(0.7),
                fontSize: 12,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: valueColor,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  String _getHealthStatusText(ModelHealthStatus status) {
    switch (status) {
      case ModelHealthStatus.healthy:
        return 'Healthy';
      case ModelHealthStatus.unhealthy:
        return 'Unhealthy';
      case ModelHealthStatus.testing:
        return 'Testing...';
      case ModelHealthStatus.unknown:
        return 'Unknown';
    }
  }
  
  Color _getHealthStatusColor(ModelHealthStatus status) {
    switch (status) {
      case ModelHealthStatus.healthy:
        return Colors.green;
      case ModelHealthStatus.unhealthy:
        return Colors.red;
      case ModelHealthStatus.testing:
        return Colors.orange;
      case ModelHealthStatus.unknown:
        return ThemeService().colorScheme.onSurface.withOpacity(0.5);
    }
  }
  
  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _isLoading) return;

    var activeConversation = _chatHistoryService.activeConversationNotifier.value;
    if (activeConversation == null) {
      try {
        activeConversation = await _chatHistoryService.createConversation(
          modelId: _modelState.selectedModelId.value,
        );
      } catch (error) {
        debugPrint('Error creating conversation: $error');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error creating conversation: $error')),
          );
        }
        return;
      }
    }

    final conversationId = activeConversation.id;
    final userMessage = Message(
      id: 'local-user-${DateTime.now().millisecondsSinceEpoch}',
      content: text,
      isUser: true,
      timestamp: DateTime.now(),
    );
    await _chatHistoryService.addMessageToConversation(conversationId, userMessage);

    setState(() {
      _messageController.clear();
      _isLoading = true;
    });

    final thinkingMessage = Message(
      id: 'thinking-${DateTime.now().millisecondsSinceEpoch}',
      content: 'Thinking...',
      isUser: false,
      timestamp: DateTime.now(),
      isThinking: true,
    );
    await _chatHistoryService.addMessageToConversation(conversationId, thinkingMessage);
    _scrollToBottom();

    try {
      final selectedModelId = _modelState.selectedModelId.value;
      if (selectedModelId == null) {
        throw Exception('Select a model in Settings before sending messages.');
      }

      if (_conversationModelId != selectedModelId) {
        await _updateConversationModel(conversationId, selectedModelId);
      }

      await _chatHistoryService.sendMessage(conversationId, text);
    } catch (error, stackTrace) {
      await _errorService.logError(
        'Failed to send message: $error',
        stackTrace,
        type: ErrorType.unknown,
        context: 'ChatInterface._sendMessage',
      );

      final friendlyMessage = _getErrorMessageFromException(error);
      final errorBubble = Message(
        id: 'error-${DateTime.now().millisecondsSinceEpoch}',
        content: friendlyMessage,
        isUser: false,
        timestamp: DateTime.now(),
        isError: true,
      );
      await _chatHistoryService.addMessageToConversation(conversationId, errorBubble);
    } finally {
      await _chatHistoryService.refreshConversation(conversationId);
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
      _scrollToBottom();
    }
  }
  
  // Add a method to get user-friendly error messages
  String _getErrorMessageFromException(dynamic exception) {
    final message = exception.toString();
    if (message.contains('No model selected')) {
      return 'Please select a model in Settings before sending messages.';
    } else if (message.contains('network') || message.contains('connect')) {
      return 'Network error. Please check your internet connection and try again.';
    } else if (message.contains('timeout')) {
      return 'The request timed out. Please try again.';
    } else if (message.contains('authenticate') || message.contains('auth')) {
      return 'Authentication error. Please check your API key in Settings.';
    } else {
      return 'An error occurred. Please try again later.\n\nTechnical details: ${message.replaceAll('Exception: ', '')}';
    }
  }
  
  // Change this method from private to public
  void switchChat(String? conversationId) {
    if (conversationId == null) {
      createNewChat();
      return;
    }
    _chatHistoryService.setActiveConversation(conversationId).then((_) async {
      final active = _chatHistoryService.activeConversationNotifier.value;
      if (mounted) {
        setState(() {
          _conversationModelId = active?.modelId;
        });
      }
      await Future<void>.delayed(const Duration(milliseconds: 100));
      _scrollToBottom();
    });
  }

  // Create a new chat
  Future<void> createNewChat() async {
    try {
      final conversation = await _chatHistoryService.createConversation(
        modelId: _modelState.selectedModelId.value,
      );
      if (!mounted) return;
      setState(() {
        _messageController.clear();
        _isLoading = false;
        _conversationModelId = conversation.modelId;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('New chat created')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error creating new chat: $error')),
      );
    }
  }

  // Add method to clear current chat
  Future<void> _clearCurrentChat() async {
    final activeConversation = _chatHistoryService.activeConversationNotifier.value;
    if (activeConversation == null) return;
    
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Chat'),
        content: const Text('Are you sure you want to clear this conversation? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
    
    if (confirmed == true) {
      await _chatHistoryService.deleteConversation(activeConversation.id);
      await createNewChat();
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeService = ThemeService();
    final colorScheme = themeService.colorScheme;
    final messages = _messages; // Get a local reference
    
    return Scaffold(
      backgroundColor: colorScheme.background,
      body: Column(
        children: [
          _buildModelIndicator(),
          Expanded(
            child: messages.isEmpty
              ? _buildWelcomeScreen()
              : _buildChatMessages(),
          ),
          _buildInputArea(),
        ],
      ),
    );
  }
  
  Widget _buildModelIndicator() {
    return ValueListenableBuilder<String?>(
      valueListenable: _modelState.selectedModelId,
      builder: (context, selectedId, child) {
        if (selectedId == null || _messages.isEmpty) {
          return const SizedBox.shrink();
        }
        
        return ValueListenableBuilder<List<ModelConfig>>(
          valueListenable: _modelState.availableModels,
          builder: (context, models, child) {
            final selectedModel = models.firstWhere(
              (model) => model.id == selectedId,
              orElse: () => ModelConfig(
                id: selectedId,
                name: 'Unknown Model',
                provider: ModelProvider.openAI,
                model: 'unknown',
                baseUrl: '',
                createdAt: DateTime.now(),
                updatedAt: DateTime.now(),
              ),
            );
            
            final colorScheme = ThemeService().colorScheme;
            final isModelMismatch = _conversationModelId != null && 
                                  _conversationModelId != selectedId;
            
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isModelMismatch 
                    ? Colors.orange.withOpacity(0.1)
                    : colorScheme.cardBackground,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isModelMismatch 
                      ? Colors.orange.withOpacity(0.3)
                      : colorScheme.cardBorder,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Model health indicator
                  ValueListenableBuilder<Map<String, ModelHealthInfo>>(
                    valueListenable: _modelState.modelHealthStatus,
                    builder: (context, healthStatus, child) {
                      final health = healthStatus[selectedId];
                      Color indicatorColor = colorScheme.onSurface.withOpacity(0.5);
                      
                      if (health != null) {
                        switch (health.status) {
                          case ModelHealthStatus.healthy:
                            indicatorColor = Colors.green;
                            break;
                          case ModelHealthStatus.unhealthy:
                            indicatorColor = Colors.red;
                            break;
                          case ModelHealthStatus.testing:
                            indicatorColor = Colors.orange;
                            break;
                          case ModelHealthStatus.unknown:
                            indicatorColor = colorScheme.onSurface.withOpacity(0.5);
                            break;
                        }
                      }
                      
                      return Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: indicatorColor,
                          shape: BoxShape.circle,
                        ),
                      );
                    },
                  ),
                  const SizedBox(width: 8),
                  // Model name
                  Text(
                    isModelMismatch 
                        ? 'Using ${selectedModel.name} (conversation started with different model)'
                        : 'Using ${selectedModel.name}',
                    style: TextStyle(
                      color: isModelMismatch 
                          ? Colors.orange
                          : colorScheme.onSurface.withOpacity(0.7),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (isModelMismatch) ...[
                    const SizedBox(width: 8),
                    InkWell(
                      onTap: () async {
                        if (_conversationModelId != null) {
                          await _modelState.setSelectedModel(_conversationModelId!);
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'Switch Back',
                          style: TextStyle(
                            color: Colors.orange,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildWelcomeScreen() {
    final colorScheme = ThemeService().colorScheme;
    
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const SizedBox(height: 16),
        Expanded(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                InkWell(
                  onTap: () => createNewChat(),
                  child: Icon(
                    Icons.chat_bubble_outline,
                    size: 64,
                    color: colorScheme.disabled,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Start a new conversation',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onBackground.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: 100),
          child: Column(
            children: [
              _buildSuggestionCard(
                "Create a cartoon",
                "illustration of my pet",
                Icons.brush_outlined,
              ),
              const SizedBox(height: 12),
              _buildSuggestionCard(
                "What can PocketLLM do",
                "and how to get started",
                Icons.help_outline,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildChatMessages() {
    return ListView.builder(
      controller: _scrollController,
      itemCount: _messages.length,
      padding: const EdgeInsets.only(bottom: 20),
      itemBuilder: (context, index) {
        return _buildMessageBubble(_messages[index]);
      },
    );
  }

  Widget _buildSuggestionCard(String title, String subtitle, IconData icon) {
    final colorScheme = ThemeService().colorScheme;
    
    return InkWell(
      onTap: () {
        _messageController.text = "$title: $subtitle";
        _sendMessage();
      },
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colorScheme.cardBackground,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: colorScheme.cardBorder),
          boxShadow: [
            BoxShadow(
              color: colorScheme.shadow,
              blurRadius: 2,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 16,
                color: colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageBubble(Message message) {
    final formattedTime = '${message.timestamp.hour}:${message.timestamp.minute.toString().padLeft(2, '0')}';
    final themeService = ThemeService();
    final colorScheme = themeService.colorScheme;
    final messageRadius = themeService.messageCornerRadius;
    final tailRadius = const Radius.circular(8);
    final userBorderRadius = BorderRadius.only(
      topLeft: Radius.circular(messageRadius),
      topRight: Radius.circular(messageRadius),
      bottomLeft: tailRadius,
      bottomRight: Radius.circular(messageRadius),
    );
    final assistantBorderRadius = BorderRadius.only(
      topLeft: Radius.circular(messageRadius),
      topRight: Radius.circular(messageRadius),
      bottomLeft: Radius.circular(messageRadius),
      bottomRight: tailRadius,
    );

    return Column(
      crossAxisAlignment: message.isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 16.0, left: 16.0, right: 16.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: message.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
            children: [
              if (!message.isUser)
                Padding(
                  padding: const EdgeInsets.only(right: 8.0, top: 4.0),
                  child: CircleAvatar(
                    backgroundColor: message.isError ? colorScheme.error : colorScheme.surface,
                    radius: 16,
                    child: message.isError
                        ? Icon(Icons.error_outline, color: colorScheme.onError, size: 18)
                        : ClipOval(
                            child: Image.asset(
                              'assets/icons/logo.png',
                              width: 32,
                              height: 32,
                              fit: BoxFit.cover,
                            ),
                    ),
                  ),
                ),
              Flexible(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: message.isUser
                        ? colorScheme.userMessageBackground
                        : message.isThinking 
                            ? colorScheme.assistantMessageBackground.withOpacity(0.7)
                            : message.isError
                                ? colorScheme.error.withOpacity(0.1)
                                : colorScheme.assistantMessageBackground,
                    borderRadius: message.isUser ? userBorderRadius : assistantBorderRadius,
                    border: !message.isUser && !message.isThinking
                        ? Border.all(color: colorScheme.messageBorder)
                        : null,
                    boxShadow: [
                      BoxShadow(
                        color: colorScheme.shadow,
                        blurRadius: 3,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: message.isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                    children: [
                      if (message.isThinking)
                        _buildThinkingIndicator()
                      else if (!message.isUser && message.isStreaming)
                        Row(
                          children: [
                            Expanded(
                              child: MarkdownBody(
                                data: message.content,
                                styleSheet: MarkdownStyleSheet(
                                  p: TextStyle(
                                    color: message.isUser ? colorScheme.onPrimary : colorScheme.messageText,
                                    fontSize: 16,
                                    height: 1.5,
                                  ),
                                  code: TextStyle(
                                    backgroundColor: colorScheme.surface,
                                    color: colorScheme.messageText,
                                    fontFamily: 'monospace',
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            SizedBox(
                              height: 16,
                              width: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  ThemeService().colorScheme.primary,
                                ),
                              ),
                            ),
                          ],
                        )
                      else if (!message.isUser && (message.content.contains("**Thought:**") || 
                              message.content.contains("<think>")))
                        _buildReasoningContent(message.content)
                      else if (!message.isUser)
                        MarkdownBody(
                          data: message.content,
                          styleSheet: MarkdownStyleSheet(
                            p: TextStyle(
                              color: colorScheme.messageText,
                              fontSize: 16,
                              height: 1.5,
                            ),
                            code: TextStyle(
                              backgroundColor: colorScheme.surface,
                              color: colorScheme.messageText,
                              fontFamily: 'monospace',
                              fontSize: 14,
                            ),
                            codeblockDecoration: BoxDecoration(
                              color: colorScheme.surface,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: colorScheme.messageBorder),
                            ),
                          ),
                          selectable: true,
                        )
                      else
                        SelectableText(
                          message.content,
                          style: TextStyle(
                            color: colorScheme.onPrimary,
                            fontSize: 16,
                            height: 1.5,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              if (message.isUser)
                Padding(
                  padding: const EdgeInsets.only(left: 8.0, top: 4.0),
                  child: CircleAvatar(
                    backgroundColor: colorScheme.primary,
                    radius: 16,
                    child: Icon(Icons.person, color: colorScheme.onPrimary, size: 18),
                  ),
                ),
            ],
          ),
        ),
        Container(
          margin: EdgeInsets.only(
            left: message.isUser ? 0 : 48,
            right: message.isUser ? 48 : 0,
            bottom: 8,
            top: 4,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: message.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                formattedTime,
                style: TextStyle(
                  color: colorScheme.onSurface.withOpacity(0.6),
                  fontSize: 12,
                ),
              ),
              const SizedBox(width: 8),
              InkWell(
                onTap: () => _showMessageOptions(context, message),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  child: Icon(
                    Icons.more_horiz,
                    size: 16,
                    color: colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildReasoningContent(String content) {
    // Check for different reasoning formats
    
    // Format 1: Thought and Response sections
    if (content.contains("**Thought:**") && content.contains("**Response:**")) {
      final parts = content.split("**Response:**");
      final thoughtPart = parts[0].replaceAll("**Thought:**", "").trim();
      final responsePart = parts.length > 1 ? parts[1].trim() : "";

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ExpansionTile(
            initiallyExpanded: false,
            tilePadding: EdgeInsets.zero,
            title: const Text(
              "Reasoning Process",
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Color(0xFF8B5CF6),
                fontSize: 14,
              ),
            ),
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                child: Text(
                  thoughtPart,
                  style: const TextStyle(
                    color: Color(0xFF4B5563),
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          MarkdownBody(
            data: responsePart,
            styleSheet: MarkdownStyleSheet(
              p: const TextStyle(
                color: Color(0xFF1F2937),
                fontSize: 16,
                height: 1.5,
              ),
              code: TextStyle(
                backgroundColor: Colors.grey[100],
                color: const Color(0xFF1F2937),
                fontFamily: 'monospace',
                fontSize: 14,
              ),
              codeblockDecoration: BoxDecoration(
                color: const Color(0xFFF9FAFB),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
            ),
            selectable: true,
          ),
        ],
      );
    }
    
    // Format 2: <think></think> tags (Deepseek format)
    else if (content.contains("<think>") && content.contains("</think>")) {
      final thinkRegex = RegExp(r'<think>(.*?)<\/think>', dotAll: true);
      final match = thinkRegex.firstMatch(content);
      
      String thoughtPart = "";
      String responsePart = content;
      
      if (match != null) {
        thoughtPart = match.group(1)?.trim() ?? "";
        responsePart = content.replaceAll(match.group(0) ?? "", "").trim();
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ExpansionTile(
            initiallyExpanded: false,
            tilePadding: EdgeInsets.zero,
            title: const Text(
              "Reasoning Process",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Color(0xFF8B5CF6),
              ),
            ),
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  thoughtPart,
                  style: const TextStyle(
                    color: Colors.black87,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          MarkdownBody(
            data: responsePart,
            styleSheet: MarkdownStyleSheet(
              p: const TextStyle(
                color: Colors.black87,
                fontSize: 16,
              ),
              code: TextStyle(
                backgroundColor: Colors.grey[200],
                color: Colors.black87,
                fontFamily: 'monospace',
                fontSize: 14,
              ),
              codeblockDecoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            selectable: true,
          ),
        ],
      );
    }
    
    // Default: Just show the content as markdown
    return MarkdownBody(
      data: content,
      styleSheet: MarkdownStyleSheet(
        p: const TextStyle(
          color: Colors.black87,
          fontSize: 16,
        ),
        code: TextStyle(
          backgroundColor: Colors.grey[200],
          color: Colors.black87,
          fontFamily: 'monospace',
          fontSize: 14,
        ),
        codeblockDecoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      selectable: true,
    );
  }

  Widget _buildThinkingIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            "Thinking",
            style: TextStyle(
              color: Colors.grey[800],
              fontWeight: FontWeight.w500,
              fontSize: 14,
            ),
          ),
          const SizedBox(width: 8),
          // Three static dots with different opacities
          Container(
            width: 6,
            height: 6,
            margin: const EdgeInsets.only(right: 3),
            decoration: BoxDecoration(
              color: const Color(0xFF8B5CF6),
              shape: BoxShape.circle,
            ),
          ),
          Container(
            width: 6,
            height: 6,
            margin: const EdgeInsets.only(right: 3),
            decoration: BoxDecoration(
              color: const Color(0xFF8B5CF6).withOpacity(0.7),
              shape: BoxShape.circle,
            ),
          ),
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: const Color(0xFF8B5CF6).withOpacity(0.4),
              shape: BoxShape.circle,
            ),
          ),
        ],
      ),
    );
  }

  void _showMessageOptions(BuildContext context, Message message) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.symmetric(vertical: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text(
                "Message Options",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const Divider(),
            _buildMessageOption(
              icon: Icons.copy,
              label: 'Copy to clipboard',
              onTap: () {
                FlutterClipboard.copy(message.content);
                Navigator.pop(context);
                _showCustomSnackBar(
                  context: context, 
                  message: 'Message copied to clipboard',
                  icon: Icons.check_circle,
                );
              },
            ),
            if (message.isUser) ...[
              _buildMessageOption(
                icon: Icons.edit,
                label: 'Edit message',
                onTap: () {
                  Navigator.pop(context);
                  _messageController.text = message.content;
                  // Remove the old message
                  setState(() {
                    _messages.remove(message);
                  });
                  _showCustomSnackBar(
                    context: context, 
                    message: 'Editing message...',
                    icon: Icons.edit,
                  );
                },
              ),
              _buildMessageOption(
                icon: Icons.thumb_down,
                label: 'Report bad response',
                onTap: () {
                  Navigator.pop(context);
                  _showCustomSnackBar(
                    context: context, 
                    message: 'Response reported. Thank you for your feedback!',
                    icon: Icons.thumb_down,
                  );
                },
              ),
              _buildMessageOption(
                icon: Icons.volume_up,
                label: 'Read aloud',
                onTap: () {
                  Navigator.pop(context);
                  _showCustomSnackBar(
                    context: context, 
                    message: 'Reading aloud...',
                    icon: Icons.volume_up,
                  );
                  // Implement text-to-speech functionality
                },
              ),
            ],
            _buildMessageOption(
              icon: Icons.auto_awesome,
              label: 'Change model',
              trailing: Text(
                _modelState.selectedModel?.name ?? 'Select Model',
                style: TextStyle(color: Colors.grey[600]),
              ),
              onTap: () {
                Navigator.pop(context);
                _showModelSelectionSheet();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showCustomSnackBar({
    required BuildContext context,
    required String message,
    required IconData icon,
    Duration duration = const Duration(seconds: 2),
  }) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        backgroundColor: const Color(0xFF8B5CF6),
        duration: duration,
      ),
    );
  }

  Widget _buildMessageOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Widget? trailing,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color(0xFFEEF2FF),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: const Color(0xFF8B5CF6)),
      ),
      title: Text(
        label,
        style: const TextStyle(
          fontWeight: FontWeight.w500,
        ),
      ),
      trailing: trailing,
      onTap: onTap,
    );
  }

  Future<void> _showModelSelectionSheet() async {
    final configs = _modelState.availableModels.value;
    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.symmetric(vertical: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Select Model',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: configs.length,
                itemBuilder: (context, index) {
                  final config = configs[index];
                  final isSelected = config.id == _modelState.selectedModelId.value;
                  
                  return InkWell(
                    onTap: () async {
                      await ModelState().setSelectedModel(config.id); // Update global state
                      Navigator.pop(context);
                      _showCustomSnackBar(
                        context: context,
                        message: 'Model changed to ${config.name}',
                        icon: Icons.check_circle,
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: isSelected ? const Color(0xFFF3F4F6) : Colors.transparent,
                        border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF8B5CF6).withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              _getProviderIcon(config.provider),
                              color: const Color(0xFF8B5CF6),
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  config.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black87,
                                  ),
                                ),
                                Text(
                                  config.provider.toString().split('.').last,
                                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                          if (isSelected)
                            const Icon(Icons.check_circle, color: Color(0xFF8B5CF6)),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  // Helper method to get provider icon
  IconData _getProviderIcon([ModelProvider? provider]) {
    if (provider == null && _modelState.selectedModel == null) return Icons.psychology;
    
    final providerToCheck = provider ?? _modelState.selectedModel!.provider;
    switch (providerToCheck) {
      case ModelProvider.ollama:
        return Icons.terminal;
      case ModelProvider.openAI:
        return Icons.auto_awesome;
      case ModelProvider.groq:
        return Icons.flash_on;
      case ModelProvider.anthropic:
        return Icons.psychology;
      case ModelProvider.lmStudio:
        return Icons.science;
      default:
        return Icons.psychology;
    }
  }

  Widget _buildChatActionsMenu() {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert),
      onSelected: (value) async {
        switch (value) {
          case 'new':
            createNewChat();
            break;
          case 'clear':
            await _clearCurrentChat();
            break;
          case 'history':
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ChatHistory(
                  onConversationSelected: (id) {
                    switchChat(id);
                  },
                ),
              ),
            );
            break;
        }
      },
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: 'new',
          child: Row(
            children: [
              Icon(Icons.add, size: 20),
              SizedBox(width: 8),
              Text('New Chat'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'clear',
          child: Row(
            children: [
              Icon(Icons.delete_outline, size: 20),
              SizedBox(width: 8),
              Text('Clear Chat'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'history',
          child: Row(
            children: [
              Icon(Icons.history, size: 20),
              SizedBox(width: 8),
              Text('Chat History'),
            ],
          ),
        ),
      ],
    );
  }

  Future<bool> _isWebSearchConfigured() async {
    try {
      final selectedConfig = await SearchService.getSelectedSearchConfig();
      return selectedConfig != null;
    } catch (e) {
      debugPrint('Error checking web search configuration: $e');
      return false;
    }
  }

  Future<void> _toggleWebSearch() async {
    bool isConfigured = await _isWebSearchConfigured();
    
    if (!isConfigured) {
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Web search is not configured. Configure it in Settings > Search Configuration."),
          action: SnackBarAction(
            label: "Settings",
            onPressed: () {
              Navigator.push(
                context, 
                MaterialPageRoute(builder: (context) => SearchConfigPage()),
              );
            },
          ),
        ),
      );
      return;
    }
    
    // If web search is configured, toggle the mode
    setState(() {
      // Add your logic to toggle web search mode
      // For now, just show a message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Web search is enabled')),
      );
    });
  }
}
