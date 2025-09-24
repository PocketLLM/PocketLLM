import 'dart:ui';
import 'package:flutter/material.dart';
import '../pages/config_page.dart';
import '../pages/library_page.dart';
import '../pages/settings_page.dart';
import '../services/model_service.dart';
import '../services/theme_service.dart';
import '../services/model_state.dart';
import '../component/models.dart';
import '../component/model_selector.dart';
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
  final _modelState = ModelState();

  @override
  void initState() {
    super.initState();
    _modelState.addListener(_onModelStateChanged);
  }

  @override
  void dispose() {
    _modelState.removeListener(_onModelStateChanged);
    super.dispose();
  }

  void _onModelStateChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  void _onModelChanged() {
    // Model change is handled by ModelState and ModelSelector
    // This callback is for any additional app bar specific logic
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = ThemeService().colorScheme;

    return PreferredSize(
      preferredSize: const Size.fromHeight(kToolbarHeight),
      child: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: BoxDecoration(
              color: colorScheme.surface.withOpacity(0.8),
              border: Border(
                bottom: BorderSide(
                  color: colorScheme.divider,
                  width: 0.5,
                ),
              ),
            ),
            child: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              title: ValueListenableBuilder<String?>(
                valueListenable: _modelState.selectedModelId,
                builder: (context, selectedId, child) {
                  return ValueListenableBuilder<List<ModelConfig>>(
                    valueListenable: _modelState.availableModels,
                    builder: (context, models, child) {
                      ModelConfig? selectedModel;
                      if (models.isNotEmpty && selectedId != null) {
                        try {
                          selectedModel = models.firstWhere((model) => model.id == selectedId);
                        } catch (e) {
                          selectedModel = models.isNotEmpty ? models.first : null;
                        }
                      }

                      return InkWell(
                        onTap: () => _showModelSelector(context),
                        borderRadius: BorderRadius.circular(8),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Model health indicator
                              ValueListenableBuilder<Map<String, ModelHealthInfo>>(
                                valueListenable: _modelState.modelHealthStatus,
                                builder: (context, healthStatus, child) {
                                  if (selectedId != null) {
                                    final health = healthStatus[selectedId];
                                    if (health != null) {
                                      Color indicatorColor;
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
                                        default:
                                          indicatorColor = colorScheme.onSurface.withOpacity(0.5);
                                          break;
                                      }
                                      return Container(
                                        width: 8,
                                        height: 8,
                                        margin: const EdgeInsets.only(right: 8),
                                        decoration: BoxDecoration(
                                          color: indicatorColor,
                                          shape: BoxShape.circle,
                                        ),
                                      );
                                    }
                                  }
                                  return const SizedBox.shrink();
                                },
                              ),
                              // Model name
                              Flexible(
                                child: Text(
                                  selectedModel?.name ?? 'PocketLLM',
                                  style: TextStyle(
                                    color: colorScheme.onSurface,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 18,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Icon(
                                Icons.arrow_drop_down,
                                color: colorScheme.onSurface.withOpacity(0.6),
                                size: 20,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
              actions: [
                IconButton(
                  icon: Icon(Icons.add, color: colorScheme.onSurface),
                  onPressed: widget.onNewChatPressed ?? () {
                    print('New Chat pressed but no callback provided');
                  },
                ),
                IconButton(
                  icon: Icon(Icons.settings_outlined, color: colorScheme.onSurface),
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
    final colorScheme = ThemeService().colorScheme;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      constraints: const BoxConstraints(maxHeight: 500),
      builder: (context) {
        return ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
            child: Container(
              decoration: BoxDecoration(
                color: colorScheme.surface.withOpacity(0.95),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                border: Border.all(
                  color: colorScheme.divider,
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
                        color: colorScheme.onSurface.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    // Enhanced model selector
                    Flexible(
                      child: ModelSelector(
                        style: ModelSelectorStyle.list,
                        title: 'Select Model',
                        showHealthStatus: true,
                        showProviderIcons: true,
                        allowHealthCheck: true,
                        maxHeight: 350,
                        onModelChanged: () {
                          Navigator.pop(context);
                          _onModelChanged();
                        },
                      ),
                    ),
                    Divider(
                      color: colorScheme.divider,
                      height: 1,
                    ),
                    // Add New Model option
                    ListTile(
                      leading: Icon(
                        Icons.add_circle_outline,
                        color: colorScheme.primary,
                      ),
                      title: Text(
                        'Add New Model',
                        style: TextStyle(
                          color: colorScheme.onSurface,
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