import 'package:flutter/material.dart';

/// Represents a model that can be previewed/selected in the onboarding flow.
class ModelOption {
  const ModelOption({
    required this.id,
    required this.name,
    required this.providerId,
    required this.description,
    required this.healthLabel,
    required this.icon,
  });

  final String id;
  final String name;
  final String providerId;
  final String description;
  final String healthLabel;
  final IconData icon;
}

class ModelSelection extends StatelessWidget {
  const ModelSelection({
    required this.models,
    required this.selectedModelId,
    required this.onSelectModel,
    this.onPreview,
    Key? key,
  }) : super(key: key);

  final List<ModelOption> models;
  final String? selectedModelId;
  final ValueChanged<ModelOption> onSelectModel;
  final ValueChanged<ModelOption>? onPreview;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 16,
      runSpacing: 16,
      children: models
          .map(
            (model) => _ModelTile(
              option: model,
              isSelected: model.id == selectedModelId,
              onTap: () => onSelectModel(model),
              onPreview: () => onPreview?.call(model),
            ),
          )
          .toList(),
    );
  }
}

class _ModelTile extends StatelessWidget {
  const _ModelTile({
    required this.option,
    required this.isSelected,
    required this.onTap,
    required this.onPreview,
  });

  final ModelOption option;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onPreview;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      width: 240,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isSelected
            ? theme.colorScheme.primaryContainer
            : theme.colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isSelected
              ? theme.colorScheme.primary
              : theme.colorScheme.outlineVariant,
          width: isSelected ? 2 : 1,
        ),
        boxShadow: isSelected
            ? [
                BoxShadow(
                  color: theme.colorScheme.primary.withOpacity(0.12),
                  blurRadius: 24,
                  offset: const Offset(0, 12),
                ),
              ]
            : null,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: theme.colorScheme.primary.withOpacity(0.15),
            child: Icon(option.icon, color: theme.colorScheme.primary),
          ),
          const SizedBox(height: 16),
          Text(
            option.name,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            option.description,
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Chip(
                label: Text(option.healthLabel),
                avatar: const Icon(Icons.health_and_safety, size: 16),
              ),
              IconButton(
                tooltip: 'Preview model',
                onPressed: onPreview,
                icon: const Icon(Icons.visibility),
              ),
            ],
          ),
          const SizedBox(height: 12),
          FilledButton.tonal(
            onPressed: onTap,
            child: Text(isSelected ? 'Selected' : 'Use this model'),
          ),
        ],
      ),
    );
  }
}
