import 'dart:ui';
import 'package:flutter/material.dart';
import '../pages/config_page.dart';
import '../pages/library_page.dart';
import '../pages/settings_page.dart';
import '../services/model_service.dart';
import '../services/auth_service.dart';
import '../component/models.dart';
import '../pages/auth/auth_page.dart';

class CustomAppBar extends StatefulWidget implements PreferredSizeWidget {
  final String appName;
  final VoidCallback onSettingsPressed;
  final VoidCallback? onNewChatPressed;

  const CustomAppBar({
    required this.appName,
    required this.onSettingsPressed,
    this.onNewChatPressed,
    Key? key,
  }) : super(key: key);

  @override
  _CustomAppBarState createState() => _CustomAppBarState();

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

class _CustomAppBarState extends State<CustomAppBar> {
  List<ModelConfig> _modelConfigs = [];
  String? _selectedModelId;
  bool _isLoading = false;
  final _authService = AuthService();
  final _modelService = ModelService();

  @override
  void initState() {
    super.initState();
    _loadModelConfigs();
  }

  Future<void> _loadModelConfigs() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final configs = await _modelService.getFilteredModelConfigs();
      final selectedId = await _modelService.getDefaultModelId();

      if (configs.isEmpty) {
        print('No configs returned from ModelService.getFilteredModelConfigs()');
      } else {
        print('Loaded ${configs.length} model configs: ${configs.map((c) => c.name).toList()}');
      }

      setState(() {
        _modelConfigs = configs;
        _selectedModelId = selectedId ?? (configs.isNotEmpty ? configs.first.id : null);
        _isLoading = false;
      });
    } catch (e) {
      print('Failed to load model configurations: $e');
      setState(() {
        _modelConfigs = [];
        _selectedModelId = null;
        _isLoading = false;
      });
    }
  }

  Future<void> _selectModel(String id) async {
    final selectedConfig = _modelConfigs.firstWhere((c) => c.id == id);
    
    try {
      await _modelService.setDefaultModel(id);
      setState(() {
        _selectedModelId = id;
      });
      await _loadModelConfigs(); // Reload to ensure consistency
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Active model updated'),
          backgroundColor: const Color(0xFF8B5CF6),
          behavior: SnackBarBehavior.floating,
          action: SnackBarAction(
            label: 'OK',
            textColor: Colors.white,
            onPressed: () {},
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update model: ${e.toString()}'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedModel = _modelConfigs.isNotEmpty && _selectedModelId != null
        ? _modelConfigs.firstWhere(
            (model) => model.id == _selectedModelId,
            orElse: () => _modelConfigs.first,
          )
        : null;

    return PreferredSize(
      preferredSize: const Size.fromHeight(kToolbarHeight),
      child: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.8),
              border: Border(
                bottom: BorderSide(
                  color: Colors.grey.withOpacity(0.2),
                  width: 0.5,
                ),
              ),
            ),
            child: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              title: InkWell(
                onTap: () {
                  _showModelSelector(context);
                },
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Flexible(
                              child: Text(
                                selectedModel != null ? selectedModel.name : 'PocketLLM',
                                style: const TextStyle(
                                  color: Colors.black87,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 18,
                                ),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            ),
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.arrow_drop_down,
                        color: Colors.black54,
                        size: 20,
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.add, color: Colors.black87),
                  onPressed: widget.onNewChatPressed ?? () {
                    print('New Chat pressed but no callback provided');
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.settings_outlined, color: Colors.black87),
                  onPressed: widget.onSettingsPressed,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showModelSelector(BuildContext context) {
    if (_modelConfigs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('No models configured. Add models in Settings.'),
          action: SnackBarAction(
            label: 'Settings',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsPage()),
              );
            },
          ),
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      constraints: const BoxConstraints(maxHeight: 400), // Limit maximum height
      builder: (context) {
        return ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5), // Reduced blur for better visibility
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.95), // Increased opacity for better visibility
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                border: Border.all(
                  color: Colors.grey.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: SafeArea(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Handle for the bottom sheet
                    Container(
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    // Title
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        'Select Model',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87, // Updated for better contrast
                        ),
                      ),
                    ),
                    const Divider(
                      color: Colors.black12, // Updated divider color
                      height: 1,
                    ),
                    // Model list
                    Flexible(
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: _modelConfigs.length,
                        itemBuilder: (context, index) {
                          final model = _modelConfigs[index];
                          final isSelected = model.id == _selectedModelId;
                          return ListTile(
                            leading: _getProviderIcon(model.provider),
                            title: Text(
                              model.name,
                              style: TextStyle(
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                color: Colors.black87,
                              ),
                            ),
                            subtitle: Text(
                              model.provider.displayName,
                              style: TextStyle(
                                color: Colors.black54, // Changed from white to dark for better visibility
                              ),
                            ),
                            trailing: isSelected
                                ? const Icon(
                                    Icons.check_circle,
                                    color: Color(0xFF8B5CF6),
                                  )
                                : null,
                            onTap: () {
                              _selectModel(model.id);
                              Navigator.pop(context);
                            },
                            tileColor: Colors.transparent, // Keep tile background transparent
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 4,
                            ),
                          );
                        },
                      ),
                    ),
                    const Divider(
                      color: Colors.black12, // Updated divider color
                      height: 1,
                    ),
                    // Add New Model option
                    ListTile(
                      leading: const Icon(
                        Icons.add_circle_outline,
                        color: Color(0xFF8B5CF6),
                      ),
                      title: Text(
                        'Add New Model',
                        style: TextStyle(
                          color: Colors.black87, // Changed from white to dark for better visibility
                        ),
                      ),
                      onTap: () {
                        Navigator.pop(context);
                        widget.onSettingsPressed();
                      },
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _getProviderIcon(ModelProvider provider) {
    IconData iconData;
    Color iconColor;
    
    switch (provider) {
      case ModelProvider.ollama:
        iconData = Icons.terminal;
        iconColor = Colors.green;
        break;
      case ModelProvider.openAI:
        iconData = Icons.auto_awesome;
        iconColor = Colors.blue;
        break;
      case ModelProvider.anthropic:
        iconData = Icons.psychology;
        iconColor = Colors.purple;
        break;
      case ModelProvider.lmStudio:
        iconData = Icons.science;
        iconColor = Colors.orange;
        break;
      case ModelProvider.pocketLLM:
        iconData = Icons.smart_toy;
        iconColor = Color(0xFF8B5CF6);
        break;
      case ModelProvider.mistral:
        iconData = Icons.air;
        iconColor = Colors.teal;
        break;
      case ModelProvider.deepseek:
        iconData = Icons.search;
        iconColor = Colors.amber;
        break;
    }
    
    return Container(
      padding: EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: iconColor.withOpacity(0.2), // Slightly more opaque for visibility
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(iconData, color: iconColor),
    );
  }

  void _selectedMenuItem(BuildContext context, int item) {
    switch (item) {
      case 0:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const LibraryPage(),
          ),
        );
        break;
      case 1:
        print('Chat History selected');
        break;
      case 2:
        print('Docs selected');
        break;
      case 3:
        print('About selected');
        break;
      case 4:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ConfigPage(appName: widget.appName),
          ),
        );
        break;
    }
  }
}