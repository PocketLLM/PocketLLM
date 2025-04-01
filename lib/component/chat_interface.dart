import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:clipboard/clipboard.dart';
import 'models.dart';
import 'tavily_service.dart';
import 'chat_history_manager.dart';
import '../services/chat_service.dart';
import '../services/model_service.dart' as service;
import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:convert';
import 'dart:math';
import 'dart:async';
import '../services/model_state.dart';
import '../services/theme_service.dart'; // Add this import

class ChatInterface extends StatefulWidget {
  const ChatInterface({Key? key}) : super(key: key);

  @override
  _ChatInterfaceState createState() => _ChatInterfaceState();
}

class _ChatInterfaceState extends State<ChatInterface> {
  bool _showAttachmentOptions = false;
  final double _inputHeight = 56.0;
  final double _maxInputHeight = 120.0;
  final TextEditingController _messageController = TextEditingController();
  final List<Message> _messages = [];
  
  // Getter for messages
  List<Message> get messages => List.unmodifiable(_messages);
  
  bool _isLoading = false;
  final ScrollController _scrollController = ScrollController();
  String? _selectedModelId;
  service.ModelConfig? _selectedModelConfig;
  List<service.ModelConfig> _modelConfigs = [];
  bool _isStreaming = false;
  String _currentStreamingResponse = '';
  String _currentThought = '';
  bool _isTyping = false;
  
  // Restore missing variables
  final String apiKey = 'ddc-m4qlvrgpt1W1E4ZXc4bvm5T5Z6CRFLeXRCx9AbRuQOcGpFFrX2';
  final String apiUrl = 'https://api.sree.shop/v1/chat/completions';
  final TavilyService _tavilyService = TavilyService();
  bool _isOnline = false;
  final ChatHistoryManager _chatHistoryManager = ChatHistoryManager();

  // Suggested messages (dynamic)
  final List<String> _suggestedMessages = [
    "🤔 What's the meaning of life?",
    "🌍 How can we protect the environment?",
    "🤖 What are the latest AI trends?"
  ];

  @override
  void initState() {
    super.initState();
    _loadSelectedModel();
    _loadChatHistory();
    // Add listener to update send button state
    _messageController.addListener(() {
      setState(() {}); // Trigger rebuild when text changes
    });
  }

  Future<void> _loadSelectedModel() async {
    try {
      final selectedId = await service.ModelService.getSelectedModel();
      if (selectedId != null) {
        final configs = await service.ModelService.getModelConfigs();
        final config = configs.firstWhere(
          (config) => config.id == selectedId,
          orElse: () => throw Exception('Selected model not found'),
        );
        
        setState(() {
          _selectedModelId = selectedId;
          _selectedModelConfig = config;
        });
      }
    } catch (e) {
      print('Error loading selected model: $e');
    }
  }

  Future<void> _loadChatHistory() async {
    final savedMessages = await _chatHistoryManager.loadChatHistory();
    setState(() {
      _messages.addAll(savedMessages);
    });
    _scrollToBottom();
  }

  Future<void> _loadModelConfigs() async {
    try {
      final configs = await service.ModelService.getModelConfigs();
      setState(() {
        _modelConfigs = configs;
        _selectedModelId = ModelState().selectedModelId.value;
        _updateSelectedConfig();
      });
      ModelState().selectedModelId.addListener(_onModelChanged);
    } catch (e) {
      print('Error loading model configs: $e');
    }
  }

  void _onModelChanged() {
    setState(() {
      _selectedModelId = ModelState().selectedModelId.value;
      _updateSelectedConfig();
    });
  }

  void _updateSelectedConfig() {
    if (_selectedModelId != null && _modelConfigs.isNotEmpty) {
      _selectedModelConfig = _modelConfigs.firstWhere(
        (config) => config.id == _selectedModelId,
        orElse: () => _modelConfigs.first,
      );
    } else {
      _selectedModelConfig = null;
    }
  }

    @override
  void dispose() {
    ModelState().selectedModelId.removeListener(_onModelChanged);
    super.dispose();
  }


  Future<void> _sendMessage() async {
    final message = _messageController.text.trim();
    if (message.isEmpty || _isLoading) return;

    setState(() {
      _messages.add(Message(
        content: message,
        isUser: true,
        timestamp: DateTime.now(),
      ));
      _messageController.clear();
      _isLoading = true;
      _currentStreamingResponse = '';
    });

    // Add a temporary "Thinking..." message
    final thinkingMessage = Message(
      content: "Thinking...",
      isUser: false,
      timestamp: DateTime.now(),
      isThinking: true
    );
    setState(() {
      _messages.add(thinkingMessage);
    });
    _scrollToBottom();

    try {
      if (_selectedModelConfig == null) {
        throw Exception('No model selected. Please configure a model in Settings.');
      }

      final response = await ChatService.getModelResponse(
        message,
        stream: false,
      );

      if (!mounted) return;

      setState(() {
        _isLoading = false;
        // Remove thinking message
        _messages.removeWhere((msg) => msg.isThinking);
        // Add AI response
        _messages.add(Message(
          content: _cleanUpResponse(response),
          isUser: false,
          timestamp: DateTime.now(),
        ));
      });
      _scrollToBottom();
      _saveChatHistory();
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _messages.removeWhere((msg) => msg.isThinking);
        _messages.add(Message(
          content: 'Error: ${e.toString()}',
          isUser: false,
          timestamp: DateTime.now(),
          isError: true,
        ));
      });
      _scrollToBottom();
    }
  }

  String _cleanUpResponse(String response) {
    return response.replaceAll(RegExp(r"In\s*\$\~{3}\$.*?\$\~{3}\$"), '').trim();
  }

  Future<void> _saveChatHistory() async {
    await _chatHistoryManager.saveChatHistory(_messages);
  }

  Future<String> _getAIResponse(String userMessage) async {
    try {
      // Use the ChatService to get a response from the selected model
      return await ChatService.getModelResponse(userMessage);
    } catch (e) {
      print('Error getting AI response: $e');
      throw Exception('Failed to get AI response: $e');
    }
  }

  // Perform web search using the TavilyService
  Future<Map<String, dynamic>> _performWebSearch(String query) async {
    try {
      // Get the active search configuration from shared preferences
      final prefs = await SharedPreferences.getInstance();
      final searchConfigJson = prefs.getString('activeSearchConfig');
      
      if (searchConfigJson == null) {
        throw Exception('No active search configuration found. Please configure search settings first.');
      }
      
      final searchConfig = json.decode(searchConfigJson);
      final searchProvider = searchConfig['provider'] ?? 'tavily';
      
      if (searchProvider == 'tavily') {
        // Use TavilyService for search
        final results = await _tavilyService.search(query);
        return results;
      } else {
        throw Exception('Unsupported search provider: $searchProvider');
      }
    } catch (e) {
      print('Search error: $e');
      throw e;
    }
  }

  void _scrollToBottom() {
    // Add a small delay to ensure the UI has updated before scrolling
    Future.delayed(const Duration(milliseconds: 50), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeService().isDarkMode;
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : Colors.white,
      body: Column(
        children: [
          Expanded(
            child: _messages.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    controller: _scrollController,
                    itemCount: _messages.length,
                    padding: const EdgeInsets.only(bottom: 20),
                    itemBuilder: (context, index) {
                      return _buildMessageBubble(_messages[index]);
                    },
                  ),
          ),
          _buildInputArea(),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFEEF2FF),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Get Plus',
                      style: TextStyle(
                        color: Color(0xFF6366F1),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Icon(Icons.add, color: Color(0xFF6366F1)),
                  ],
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: Center(
            child: Image.asset(
              'assets/icons/icon.jpg', // Make sure to add this image
              width: 48,
              height: 48,
              color: Colors.grey[300],
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
  Widget _buildSuggestionCard(String title, String subtitle, IconData icon) {
    return InkWell(
      onTap: () {
        _messageController.text = "$title: $subtitle";
        _sendMessage();
      },
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: ThemeService().isDarkMode ? const Color(0xFF2D2D2D) : Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: ThemeService().isDarkMode ? Colors.grey[800]! : Colors.grey[200]!),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }
  Widget _buildInputArea() {
    return Container(
      decoration: BoxDecoration(
        color: ThemeService().isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
        boxShadow: [BoxShadow(
          color: Colors.black.withOpacity(0.05),
          blurRadius: 5,
          offset: const Offset(0, -2),
        )],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_showAttachmentOptions)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              margin: const EdgeInsets.only(bottom: 4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 5,
                  offset: const Offset(0, 2),
                )],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildAttachmentOption(Icons.image, 'Image', _pickImage),
                  _buildAttachmentOption(Icons.attach_file, 'File', _pickFile),
                  _buildAttachmentOption(Icons.camera_alt, 'Camera', _takePhoto),
                ],
              ),
            ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                IconButton(
                  icon: Icon(
                    _showAttachmentOptions ? Icons.close : Icons.add,
                    color: Colors.grey[600],
                  ),
                  onPressed: () {
                    setState(() {
                      _showAttachmentOptions = !_showAttachmentOptions;
                    });
                  },
                ),
                Expanded(
                  child: Container(
                    constraints: BoxConstraints(
                      maxHeight: _maxInputHeight,
                    ),
                    child: SingleChildScrollView(
                      child: TextField(
                        controller: _messageController,
                        maxLines: null,
                        decoration: InputDecoration(
                          hintText: 'Type a message...',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(25),
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor: Colors.grey[100],
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 10,
                          ),
                        ),
                        onSubmitted: (_) => _sendMessage(),
                      ),
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(
                    Icons.send,
                    color: _messageController.text.trim().isEmpty
                        ? Colors.grey[400]
                        : const Color(0xFF8B5CF6),
                  ),
                  onPressed: _messageController.text.trim().isEmpty
                      ? null
                      : _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    try {
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        // Handle the selected image
        final File imageFile = File(image.path);
        // Add image handling logic here
      }
    } catch (e) {
      print('Error picking image: $e');
    }
  }

  Future<void> _pickFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles();
      if (result != null) {
        File file = File(result.files.single.path!);
        // Add file handling logic here
      }
    } catch (e) {
      print('Error picking file: $e');
    }
  }

  Future<void> _takePhoto() async {
    final ImagePicker picker = ImagePicker();
    try {
      final XFile? photo = await picker.pickImage(source: ImageSource.camera);
      if (photo != null) {
        // Handle the captured photo
        final File photoFile = File(photo.path);
        // Add photo handling logic here
      }
    } catch (e) {
      print('Error taking photo: $e');
    }
  }
  Widget _buildAttachmentOption(IconData icon, String label, VoidCallback? onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 100,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        margin: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 24, color: const Color(0xFF8B5CF6)),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black87,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
  Widget _buildQuickAction(IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: Colors.grey[700],
              size: 20,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: Colors.grey[700],
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageBubble(Message message) {
    final formattedTime = '${message.timestamp.hour}:${message.timestamp.minute.toString().padLeft(2, '0')}';
    final theme = Theme.of(context);
    final isDark = ThemeService().isDarkMode;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
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
                    backgroundColor: message.isError ? Colors.red : const Color.fromARGB(255, 255, 255, 255),
                    radius: 16,
                    child: message.isError
                        ? const Icon(Icons.error_outline, color: Colors.white, size: 18)
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
                        ? const Color(0xFF8B5CF6) 
                        : message.isThinking 
                            ? (isDark ? Colors.grey[800] : const Color(0xFFF3F4F6))
                            : message.isError
                                ? (isDark ? Colors.red[900] : Colors.red[50])
                                : (isDark ? Colors.grey[900] : Colors.white),
                    borderRadius: BorderRadius.circular(16),
                    border: !message.isUser && !message.isThinking
                        ? Border.all(color: isDark ? Colors.grey[700]! : const Color(0xFFE5E7EB))
                        : null,
                    boxShadow: [
                      BoxShadow(
                        color: (ThemeService().isDarkMode ? Colors.black : Colors.black.withOpacity(0.05)),
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
                                    color: message.isUser ? Colors.white : const Color(0xFF1F2937),
                                    fontSize: 16,
                                    height: 1.5,
                                  ),
                                  code: TextStyle(
                                    backgroundColor: Colors.grey[100],
                                    color: const Color(0xFF1F2937),
                                    fontFamily: 'monospace',
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            const SizedBox(
                              height: 16,
                              width: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Color(0xFF8B5CF6),
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
                              color: isDark ? Colors.grey[200] : const Color(0xFF1F2937),
                              fontSize: 16,
                              height: 1.5,
                            ),
                            code: TextStyle(
                              backgroundColor: ThemeService().isDarkMode ? Colors.grey[800] : Colors.grey[100],
                              color: isDark ? Colors.grey[200] : const Color(0xFF1F2937),
                              fontFamily: 'monospace',
                              fontSize: 14,
                            ),
                            codeblockDecoration: BoxDecoration(
                              color: ThemeService().isDarkMode ? Colors.grey[900] : const Color(0xFFF9FAFB),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: ThemeService().isDarkMode ? Colors.grey[700]! : const Color(0xFFE5E7EB)),
                            ),
                          ),
                          selectable: true,
                        )
                      else
                        SelectableText(
                          message.content,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            height: 1.5,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              if (message.isUser)
                const Padding(
                  padding: EdgeInsets.only(left: 8.0, top: 4.0),
                  child: CircleAvatar(
                    backgroundColor: Colors.green,
                    radius: 16,
                    child: Icon(Icons.person, color: Colors.white, size: 18),
                  ),
                ),
            ],
          ),
        ),
        Padding(
          padding: EdgeInsets.only(
            left: message.isUser ? 0 : 48,
            right: message.isUser ? 48 : 0,
            bottom: 8,
            top: 4,
          ),
          child: Row(
            mainAxisAlignment: message.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
            children: [
              Text(
                formattedTime,
                style: TextStyle(
                  color: Colors.grey[600],
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
                    size: 20,
                    color: Colors.grey[600],
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
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Text(
                  "Thinking",
                  style: TextStyle(
                    color: Colors.grey[800],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 8),
                AnimatedTextKit(
                  animatedTexts: [
                    TypewriterAnimatedText(
                      '...',
                      speed: const Duration(milliseconds: 300),
                      textStyle: TextStyle(
                        color: Colors.grey[800],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                  totalRepeatCount: 100,
                  displayFullTextOnTap: false,
                  stopPauseOnTap: false,
                ),
              ],
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
            ] else ...[
              _buildMessageOption(
                icon: Icons.refresh,
                label: 'Regenerate response',
                onTap: () {
                  Navigator.pop(context);
                  // Find the last user message before this AI message
                  int aiIndex = _messages.indexOf(message);
                  String? userMessage;
                  
                  for (int i = aiIndex - 1; i >= 0; i--) {
                    if (_messages[i].isUser) {
                      userMessage = _messages[i].content;
                      break;
                    }
                  }
                  
                  if (userMessage != null) {
                    // Remove this AI message
                    setState(() {
                      _messages.remove(message);
                      _isLoading = true;
                    });
                    
                    // Create a new AI message
                    final aiMessage = Message(
                      content: '',
                      isUser: false,
                      timestamp: DateTime.now(),
                      isThinking: true,
                    );
                    
                    setState(() {
                      _messages.add(aiMessage);
                    });
                    _scrollToBottom();
                    
                    // Get a new response
                    _getAIResponse(userMessage).then((response) {
                      String cleanedResponse = _cleanUpResponse(response);
                      
                      setState(() {
                        aiMessage.content = cleanedResponse;
                        aiMessage.isThinking = false;
                        _isLoading = false;
                      });
                      
                      _saveChatHistory();
                      _scrollToBottom();
                    }).catchError((e) {
                      setState(() {
                        aiMessage.content = 'Error: $e';
                        aiMessage.isThinking = false;
                        _isLoading = false;
                      });
                      
                      _saveChatHistory();
                      _scrollToBottom();
                    });
                  }
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
                _selectedModelConfig?.name ?? 'Select Model',
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
    final configs = await service.ModelService.getModelConfigs();
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
                  final isSelected = config.id == _selectedModelId;
                  
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
                              _getProviderIcon(),
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
  IconData _getProviderIcon() {
    if (_selectedModelConfig == null) return Icons.psychology;
    
    switch (_selectedModelConfig!.provider) {
      case service.ModelProvider.ollama:
        return Icons.terminal;
      case service.ModelProvider.openAI:
        return Icons.auto_awesome;
      case service.ModelProvider.anthropic:
        return Icons.psychology;
      case service.ModelProvider.lmStudio:
        return Icons.science;
      default:
        return Icons.psychology;
    }
  }
}