import 'package:flutter/material.dart';
import '../services/model_service.dart';
import 'model_config_dialog.dart';

class ModelListItem extends StatelessWidget {
  final ModelConfig model;
  final VoidCallback onDelete;
  final Function(ModelConfig) onEdit;
  final bool isSelected;
  final VoidCallback onSelect;

  const ModelListItem({
    Key? key,
    required this.model,
    required this.onDelete,
    required this.onEdit,
    this.isSelected = false,
    required this.onSelect,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isSelected ? Color(0xFFEEF2FF) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected ? Color(0xFF8B5CF6) : Colors.grey[200]!,
          width: isSelected ? 2 : 1,
        ),
      ),
      child: ExpansionTile(
        leading: _getProviderIcon(),
        title: Text(
          model.name,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        subtitle: Text(
          model.provider.displayName,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isSelected)
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Color(0xFF8B5CF6),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Active',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            IconButton(
              icon: Icon(Icons.more_vert, color: Colors.grey[600]),
              onPressed: () {
                _showOptionsMenu(context);
              },
            ),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoRow('Model ID', model.id),
                SizedBox(height: 8),
                _buildInfoRow('Base URL', model.baseUrl),
                if (model.apiKey != null) ...[
                  SizedBox(height: 8),
                  _buildApiKeyRow(context),
                ],
                SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (!isSelected)
                      OutlinedButton.icon(
                        onPressed: onSelect,
                        icon: Icon(Icons.check, size: 18),
                        label: Text('Use This Model'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Color(0xFF8B5CF6),
                          side: BorderSide(color: Color(0xFF8B5CF6)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _getProviderIcon() {
    IconData iconData;
    Color iconColor;

    switch (model.provider) {
      case ModelProvider.ollama:
        iconData = Icons.terminal;
        iconColor = Colors.orange;
        break;
      case ModelProvider.openAI:
        iconData = Icons.auto_awesome;
        iconColor = Colors.green;
        break;
      case ModelProvider.anthropic:
        iconData = Icons.psychology;
        iconColor = Colors.purple;
        break;
      case ModelProvider.lmStudio:
        iconData = Icons.science;
        iconColor = Colors.blue;
        break;
      case ModelProvider.pocketLLM:
        iconData = Icons.smart_toy;
        iconColor = Color(0xFF8B5CF6);
        break;
      case ModelProvider.mistral:
        iconData = Icons.cloud;
        iconColor = Colors.blue;
        break;
      case ModelProvider.deepseek:
        iconData = Icons.search;
        iconColor = Colors.teal;
        break;
    }

    return Container(
      padding: EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: iconColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(iconData, color: iconColor),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 14,
              color: Colors.black87,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildApiKeyRow(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(
            'API Key',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          child: Row(
            children: [
              Text(
                '••••••••••••••••',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.black87,
                ),
              ),
              IconButton(
                icon: Icon(Icons.visibility, size: 16),
                padding: EdgeInsets.zero,
                constraints: BoxConstraints(),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('API Key: ${model.apiKey}'),
                      action: SnackBarAction(
                        label: 'Copy',
                        onPressed: () {
                          // Copy to clipboard functionality
                        },
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showOptionsMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(Icons.edit, color: Colors.blue),
                title: Text('Edit'),
                onTap: () {
                  Navigator.pop(context);
                  _showEditDialog(context);
                },
              ),
              ListTile(
                leading: Icon(Icons.delete, color: Colors.red),
                title: Text('Delete'),
                onTap: () {
                  Navigator.pop(context);
                  _showDeleteConfirmation(context);
                },
              ),
              if (!isSelected)
                ListTile(
                  leading: Icon(Icons.check_circle, color: Color(0xFF8B5CF6)),
                  title: Text('Set as Active'),
                  onTap: () {
                    Navigator.pop(context);
                    onSelect();
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  void _showEditDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => ModelConfigDialog(
        existingConfig: model,
        onSave: onEdit,
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Model'),
        content: Text('Are you sure you want to delete ${model.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              onDelete();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text('Delete'),
          ),
        ],
      ),
    );
  }
} 