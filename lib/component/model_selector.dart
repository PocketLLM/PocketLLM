import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'models.dart';
import '../services/model_state.dart';
import '../services/theme_service.dart';
import '../services/error_service.dart';

enum ModelSelectorStyle {
  dropdown,
  list,
  grid,
  compact,
}

class ModelSelector extends StatefulWidget {
  final ModelSelectorStyle style;
  final bool showHealthStatus;
  final bool showProviderIcons;
  final bool allowHealthCheck;
  final VoidCallback? onModelChanged;
  final String? title;
  final EdgeInsets? padding;
  final double? maxHeight;
  final bool enabled;

  const ModelSelector({
    Key? key,
    this.style = ModelSelectorStyle.dropdown,
    this.showHealthStatus = true,
    this.showProviderIcons = true,
    this.allowHealthCheck = true,
    this.onModelChanged,
    this.title,
    this.padding,
    this.maxHeight,
    this.enabled = true,
  }) : super(key: key);

  @override
  State<ModelSelector> createState() => _ModelSelectorState();
}

class _ModelSelectorState extends State<ModelSelector> {
  final ModelState _modelState = ModelState();
  final ErrorService _errorService = ErrorService();
  bool _isLoading = false;

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

  @override
  Widget build(BuildContext context) {
    final colorScheme = ThemeService().colorScheme;
    
    return Container(
      padding: widget.padding ?? const EdgeInsets.all(8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.title != null) ...[
            Text(
              widget.title!,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
          ],
          _buildSelector(colorScheme),
        ],
      ),
    );
  }

  Widget _buildSelector(dynamic colorScheme) {
    switch (widget.style) {
      case ModelSelectorStyle.dropdown:
        return _buildDropdownSelector(colorScheme);
      case ModelSelectorStyle.list:
        return _buildListSelector(colorScheme);
      case ModelSelectorStyle.grid:
        return _buildGridSelector(colorScheme);
      case ModelSelectorStyle.compact:
        return _buildCompactSelector(colorScheme);
    }
  }

  Widget _buildDropdownSelector(dynamic colorScheme) {
    return ValueListenableBuilder<List<ModelConfig>>(
      valueListenable: _modelState.availableModels,
      builder: (context, models, child) {
        return ValueListenableBuilder<String?>(
          valueListenable: _modelState.selectedModelId,
          builder: (context, selectedId, child) {
            final selectedModel = models.firstWhere(
              (model) => model.id == selectedId,
              orElse: () => models.isNotEmpty ? models.first : _createEmptyModel(),
            );

            return Container(
              decoration: BoxDecoration(
                color: colorScheme.cardBackground,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: colorScheme.cardBorder),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: selectedId,
                  isExpanded: true,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  dropdownColor: colorScheme.surface,
                  style: TextStyle(color: colorScheme.onSurface),
                  icon: _isLoading
                      ? SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
                          ),
                        )
                      : Icon(Icons.arrow_drop_down, color: colorScheme.onSurface),
                  hint: Text(
                    'Select a model',
                    style: TextStyle(color: colorScheme.hint),
                  ),
                  items: models.map((model) => _buildDropdownItem(model, colorScheme)).toList(),
                  onChanged: widget.enabled ? _onModelSelected : null,
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildListSelector(dynamic colorScheme) {
    return ValueListenableBuilder<List<ModelConfig>>(
      valueListenable: _modelState.availableModels,
      builder: (context, models, child) {
        return ValueListenableBuilder<String?>(
          valueListenable: _modelState.selectedModelId,
          builder: (context, selectedId, child) {
            return Container(
              constraints: BoxConstraints(
                maxHeight: widget.maxHeight ?? 300,
              ),
              decoration: BoxDecoration(
                color: colorScheme.cardBackground,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: colorScheme.cardBorder),
              ),
              child: models.isEmpty
                  ? _buildEmptyState(colorScheme)
                  : ListView.separated(
                      shrinkWrap: true,
                      itemCount: models.length,
                      separatorBuilder: (context, index) => Divider(
                        height: 1,
                        color: colorScheme.divider,
                      ),
                      itemBuilder: (context, index) {
                        final model = models[index];
                        final isSelected = model.id == selectedId;
                        return _buildListItem(model, isSelected, colorScheme);
                      },
                    ),
            );
          },
        );
      },
    );
  }

  Widget _buildGridSelector(dynamic colorScheme) {
    return ValueListenableBuilder<List<ModelConfig>>(
      valueListenable: _modelState.availableModels,
      builder: (context, models, child) {
        return ValueListenableBuilder<String?>(
          valueListenable: _modelState.selectedModelId,
          builder: (context, selectedId, child) {
            if (models.isEmpty) {
              return _buildEmptyState(colorScheme);
            }

            return Container(
              constraints: BoxConstraints(
                maxHeight: widget.maxHeight ?? 400,
              ),
              child: GridView.builder(
                shrinkWrap: true,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 3,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                itemCount: models.length,
                itemBuilder: (context, index) {
                  final model = models[index];
                  final isSelected = model.id == selectedId;
                  return _buildGridItem(model, isSelected, colorScheme);
                },
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildCompactSelector(dynamic colorScheme) {
    return ValueListenableBuilder<List<ModelConfig>>(
      valueListenable: _modelState.availableModels,
      builder: (context, models, child) {
        return ValueListenableBuilder<String?>(
          valueListenable: _modelState.selectedModelId,
          builder: (context, selectedId, child) {
            final selectedModel = models.firstWhere(
              (model) => model.id == selectedId,
              orElse: () => models.isNotEmpty ? models.first : _createEmptyModel(),
            );

            return InkWell(
              onTap: widget.enabled ? () => _showModelSelectionDialog(colorScheme) : null,
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: colorScheme.cardBackground,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: colorScheme.cardBorder),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (widget.showProviderIcons)
                      _getProviderIcon(selectedModel.provider, size: 16),
                    if (widget.showProviderIcons) const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        selectedModel.name,
                        style: TextStyle(
                          color: colorScheme.onSurface,
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 4),
                    if (widget.showHealthStatus)
                      _buildHealthIndicator(selectedModel.id, colorScheme, size: 12),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.arrow_drop_down,
                      color: colorScheme.onSurface.withOpacity(0.6),
                      size: 16,
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  DropdownMenuItem<String> _buildDropdownItem(ModelConfig model, dynamic colorScheme) {
    return DropdownMenuItem<String>(
      value: model.id,
      child: Row(
        children: [
          if (widget.showProviderIcons) ...[
            _getProviderIcon(model.provider),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  model.name,
                  style: TextStyle(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  model.provider.displayName,
                  style: TextStyle(
                    color: colorScheme.onSurface.withOpacity(0.7),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          if (widget.showHealthStatus) ...[
            const SizedBox(width: 8),
            _buildHealthIndicator(model.id, colorScheme),
          ],
          if (widget.allowHealthCheck) ...[
            const SizedBox(width: 8),
            _buildHealthCheckButton(model.id, colorScheme),
          ],
        ],
      ),
    );
  }

  Widget _buildListItem(ModelConfig model, bool isSelected, dynamic colorScheme) {
    return ListTile(
      selected: isSelected,
      selectedTileColor: colorScheme.primary.withOpacity(0.1),
      leading: widget.showProviderIcons ? _getProviderIcon(model.provider) : null,
      title: Text(
        model.name,
        style: TextStyle(
          color: colorScheme.onSurface,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      subtitle: Text(
        model.provider.displayName,
        style: TextStyle(
          color: colorScheme.onSurface.withOpacity(0.7),
        ),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.showHealthStatus)
            _buildHealthIndicator(model.id, colorScheme),
          if (widget.allowHealthCheck) ...[
            const SizedBox(width: 8),
            _buildHealthCheckButton(model.id, colorScheme),
          ],
          if (isSelected) ...[
            const SizedBox(width: 8),
            Icon(
              Icons.check_circle,
              color: colorScheme.primary,
              size: 20,
            ),
          ],
        ],
      ),
      onTap: widget.enabled ? () => _onModelSelected(model.id) : null,
    );
  }

  Widget _buildGridItem(ModelConfig model, bool isSelected, dynamic colorScheme) {
    return InkWell(
      onTap: widget.enabled ? () => _onModelSelected(model.id) : null,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected 
              ? colorScheme.primary.withOpacity(0.1)
              : colorScheme.cardBackground,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? colorScheme.primary : colorScheme.cardBorder,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (widget.showProviderIcons) ...[
                  _getProviderIcon(model.provider, size: 16),
                  const SizedBox(width: 8),
                ],
                Expanded(
                  child: Text(
                    model.name,
                    style: TextStyle(
                      color: colorScheme.onSurface,
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (widget.showHealthStatus)
                  _buildHealthIndicator(model.id, colorScheme, size: 12),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              model.provider.displayName,
              style: TextStyle(
                color: colorScheme.onSurface.withOpacity(0.7),
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHealthIndicator(String modelId, dynamic colorScheme, {double size = 16}) {
    return ValueListenableBuilder<Map<String, ModelHealthInfo>>(
      valueListenable: _modelState.modelHealthStatus,
      builder: (context, healthStatus, child) {
        final health = healthStatus[modelId];
        if (health == null) {
          return Icon(
            Icons.help_outline,
            color: colorScheme.onSurface.withOpacity(0.5),
            size: size,
          );
        }

        Color color;
        IconData icon;
        String tooltip;

        switch (health.status) {
          case ModelHealthStatus.healthy:
            color = Colors.green;
            icon = Icons.check_circle;
            tooltip = 'Healthy';
            break;
          case ModelHealthStatus.unhealthy:
            color = Colors.red;
            icon = Icons.error;
            tooltip = 'Unhealthy: ${health.error ?? 'Unknown error'}';
            break;
          case ModelHealthStatus.testing:
            color = Colors.orange;
            icon = Icons.refresh;
            tooltip = 'Testing...';
            break;
          case ModelHealthStatus.unknown:
          default:
            color = colorScheme.onSurface.withOpacity(0.5);
            icon = Icons.help_outline;
            tooltip = 'Unknown status';
            break;
        }

        return Tooltip(
          message: tooltip,
          child: Icon(
            icon,
            color: color,
            size: size,
          ),
        );
      },
    );
  }

  Widget _buildHealthCheckButton(String modelId, dynamic colorScheme) {
    return IconButton(
      icon: Icon(
        Icons.refresh,
        color: colorScheme.primary,
        size: 16,
      ),
      onPressed: () => _performHealthCheck(modelId),
      tooltip: 'Check model health',
      constraints: const BoxConstraints(),
      padding: EdgeInsets.zero,
      visualDensity: VisualDensity.compact,
    );
  }

  Widget _buildEmptyState(dynamic colorScheme) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.psychology_outlined,
            size: 48,
            color: colorScheme.onSurface.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'No models configured',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add models in Settings to get started',
            style: TextStyle(
              color: colorScheme.onSurface.withOpacity(0.7),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _getProviderIcon(ModelProvider provider, {double size = 20}) {
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
        iconColor = const Color(0xFF8B5CF6);
        break;
      case ModelProvider.mistral:
        iconData = Icons.air;
        iconColor = Colors.teal;
        break;
      case ModelProvider.deepseek:
        iconData = Icons.search;
        iconColor = Colors.amber;
        break;
      case ModelProvider.googleAI:
        iconData = Icons.g_mobiledata;
        iconColor = const Color(0xFF4285F4);
        break;
    }
    
    return Container(
      padding: EdgeInsets.all(size * 0.3),
      decoration: BoxDecoration(
        color: iconColor.withOpacity(0.2),
        borderRadius: BorderRadius.circular(size * 0.5),
      ),
      child: Icon(iconData, color: iconColor, size: size * 0.7),
    );
  }

  ModelConfig _createEmptyModel() {
    return ModelConfig(
      id: '',
      name: 'No model selected',
      provider: ModelProvider.openAI,
      model: '',
      baseUrl: '',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  void _showModelSelectionDialog(dynamic colorScheme) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: colorScheme.surface,
        title: Text(
          'Select Model',
          style: TextStyle(color: colorScheme.onSurface),
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: ModelSelector(
            style: ModelSelectorStyle.list,
            showHealthStatus: widget.showHealthStatus,
            showProviderIcons: widget.showProviderIcons,
            allowHealthCheck: widget.allowHealthCheck,
            maxHeight: 400,
            onModelChanged: () {
              Navigator.of(context).pop();
              widget.onModelChanged?.call();
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Cancel',
              style: TextStyle(color: colorScheme.onSurface.withOpacity(0.7)),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _onModelSelected(String? modelId) async {
    if (modelId == null || !widget.enabled) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await _modelState.setSelectedModel(modelId);
      
      if (mounted) {
        // Provide haptic feedback
        HapticFeedback.selectionClick();
        
        // Show confirmation
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Model changed successfully'),
            backgroundColor: ThemeService().colorScheme.primary,
            duration: const Duration(seconds: 2),
          ),
        );
        
        widget.onModelChanged?.call();
      }
    } catch (e, stackTrace) {
      await _errorService.logError(
        'Failed to select model: $e',
        stackTrace,
        type: ErrorType.unknown,
        context: 'ModelSelector._onModelSelected',
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
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _performHealthCheck(String modelId) async {
    try {
      await _modelState.forceHealthCheck(modelId: modelId);
      
      if (mounted) {
        HapticFeedback.lightImpact();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Health check completed'),
            backgroundColor: ThemeService().colorScheme.primary,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e, stackTrace) {
      await _errorService.logError(
        'Health check failed: $e',
        stackTrace,
        type: ErrorType.unknown,
        context: 'ModelSelector._performHealthCheck',
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Health check failed: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }
}

// Convenience widgets for common use cases
class ModelDropdown extends StatelessWidget {
  final VoidCallback? onModelChanged;
  final String? title;
  final bool enabled;

  const ModelDropdown({
    Key? key,
    this.onModelChanged,
    this.title,
    this.enabled = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ModelSelector(
      style: ModelSelectorStyle.dropdown,
      onModelChanged: onModelChanged,
      title: title,
      enabled: enabled,
    );
  }
}

class ModelList extends StatelessWidget {
  final VoidCallback? onModelChanged;
  final String? title;
  final double? maxHeight;
  final bool enabled;

  const ModelList({
    Key? key,
    this.onModelChanged,
    this.title,
    this.maxHeight,
    this.enabled = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ModelSelector(
      style: ModelSelectorStyle.list,
      onModelChanged: onModelChanged,
      title: title,
      maxHeight: maxHeight,
      enabled: enabled,
    );
  }
}

class CompactModelSelector extends StatelessWidget {
  final VoidCallback? onModelChanged;
  final bool enabled;

  const CompactModelSelector({
    Key? key,
    this.onModelChanged,
    this.enabled = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ModelSelector(
      style: ModelSelectorStyle.compact,
      onModelChanged: onModelChanged,
      enabled: enabled,
    );
  }
}