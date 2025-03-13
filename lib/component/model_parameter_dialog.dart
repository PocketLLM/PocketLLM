import 'package:flutter/material.dart';
import 'ollama_model.dart';

class ModelParameterDialog extends StatefulWidget {
  final OllamaModel model;
  final Function(String, String) onInstall;

  const ModelParameterDialog({
    Key? key,
    required this.model,
    required this.onInstall,
  }) : super(key: key);

  @override
  _ModelParameterDialogState createState() => _ModelParameterDialogState();
}

class _ModelParameterDialogState extends State<ModelParameterDialog> {
  late String _selectedSize;

  @override
  void initState() {
    super.initState();
    _selectedSize = widget.model.getDefaultSize();
  }

  @override
  Widget build(BuildContext context) {
    final sizes = widget.model.getParameterSizes();
    final features = widget.model.getParameterFeatures();
    final theme = Theme.of(context);
    final width = MediaQuery.of(context).size.width;
    
    // Fix: Calculate maxWidth properly to avoid constraint issues
final maxWidth = width * 0.4 > 300 ? width * 0.4 : 300.0;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: maxWidth,
          minWidth: 300, // Minimum width to prevent overflow
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      widget.model.getCategoryIcon(),
                      color: widget.model.getCategoryColor(),
                      size: 28,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Configure ${widget.model.name}',
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            widget.model.category,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurface.withOpacity(0.6),
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                      style: IconButton.styleFrom(
                        padding: EdgeInsets.zero,
                      ),
                    ),
                  ],
                ),
                if (widget.model.description.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text(
                    widget.model.description,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.8),
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                if (sizes.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  Text(
                    'Model Size',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: theme.colorScheme.outline.withOpacity(0.2),
                      ),
                    ),
                    child: DropdownButtonFormField<String>(
                      value: _selectedSize,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        filled: true,
                        fillColor: theme.colorScheme.surface,
                      ),
                      items: sizes.map((size) => DropdownMenuItem(
                        value: size,
                        child: Text(
                          size.toUpperCase(),
                          style: theme.textTheme.bodyLarge,
                        ),
                      )).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _selectedSize = value);
                        }
                      },
                    ),
                  ),
                ],
                if (features.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  Text(
                    'Features',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: features.map((feature) => Chip(
                      label: Text(
                        feature,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      backgroundColor: theme.colorScheme.surfaceVariant,
                      side: BorderSide.none,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    )).toList(),
                  ),
                ],
                const SizedBox(height: 32),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  alignment: WrapAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('Cancel'),
                    ),
                    FilledButton(
                      onPressed: () {
                        final modelName = widget.model.name;
                        final fullModelName = widget.model.getFullModelName(_selectedSize);
                        widget.onInstall(modelName, fullModelName);
                        Navigator.pop(context);
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: widget.model.getCategoryColor(),
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        'Install Model',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
