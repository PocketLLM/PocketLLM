import 'package:flutter/material.dart';
import '../services/model_service.dart';
import '../component/models.dart';
import '../component/model_config_dialog.dart';
import '../component/model_list_item.dart';
import '../services/auth_service.dart';
import '../services/pocket_llm_service.dart';
import 'auth/auth_page.dart';

class ModelSettingsPage extends StatefulWidget {
  const ModelSettingsPage({Key? key}) : super(key: key);

  @override
  _ModelSettingsPageState createState() => _ModelSettingsPageState();
}

class _ModelSettingsPageState extends State<ModelSettingsPage> {
  List<ModelConfig> _modelConfigs = [];
  bool _isLoading = true;
  String? _selectedModelId;
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
      final configs = await _modelService.getSavedModels();
      final selectedId = await _modelService.getDefaultModelId();

      // Always fetch PocketLLM models regardless of login status
      final pocketLLMModels = await _fetchPocketLLMModels();
      // Add PocketLLM models if they don't already exist
      for (var model in pocketLLMModels) {
        if (!configs.any((c) => c.id == model.id)) {
          configs.add(model);
          await _modelService.saveModel(model);
        }
      }

      setState(() {
        _modelConfigs = configs;
        _selectedModelId = selectedId;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load models: $e')),
      );
    }
  }

  Future<List<ModelConfig>> _fetchPocketLLMModels() async {
    try {
      final models = await PocketLLMService.getAvailableModels();
      return models.map((model) {
        final modelName = model['display_name'] ?? model['name'] ?? model['id'] ?? 'Unnamed Model';
        final modelId = model['id'] ?? model['name'] ?? modelName;
        return ModelConfig(
          id: modelId,
          name: modelName,
          provider: ModelProvider.pocketLLM,
          baseUrl: PocketLLMService.baseUrl, // Use the actual base URL
          apiKey: '', // Hide sensitive information
          model: modelId,
          temperature: 0.7,
          maxTokens: 2000,
          topP: 1.0,
          frequencyPenalty: 0.0,
          presencePenalty: 0.0,
          stopSequences: [],
          systemPrompt: 'You are a helpful AI assistant.',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
      }).toList();
    } catch (e) {
      print('Error fetching PocketLLM models: $e');
      return [];
    }
  }

  void _addNewModel() {
    showDialog(
      context: context,
      builder: (context) => ModelConfigDialog(
        onSave: (config) async {
          await _modelService.saveModel(config);
          if (_modelConfigs.isEmpty) {
            await _modelService.setDefaultModel(config.id);
          }
          _loadModelConfigs();
        },
      ),
    );
  }

  void _editModel(ModelConfig config) async {
    await _modelService.saveModel(config);
    _loadModelConfigs();
  }

  void _deleteModel(String id) async {
    await _modelService.deleteModel(id);
    if (_selectedModelId == id && _modelConfigs.isNotEmpty) {
      final remainingConfigs = _modelConfigs.where((c) => c.id != id).toList();
      if (remainingConfigs.isNotEmpty) {
        await _modelService.setDefaultModel(remainingConfigs.first.id);
      } else {
        await _modelService.setDefaultModel('');
      }
    }
    _loadModelConfigs();
  }

  void _selectModel(String id) async {
    await _modelService.setDefaultModel(id);
    setState(() {
      _selectedModelId = id;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.grey[50],
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black, size: 28),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Model Settings',
          style: TextStyle(
            color: Colors.black,
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.add, color: Color(0xFF8B5CF6), size: 28),
            onPressed: _addNewModel,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator())
                : _modelConfigs.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        padding: EdgeInsets.all(16),
                        itemCount: _modelConfigs.length,
                        itemBuilder: (context, index) {
                          final model = _modelConfigs[index];
                          return ModelListItem(
                            model: model,
                            isSelected: model.id == _selectedModelId,
                            onDelete: () => _deleteModel(model.id),
                            onEdit: _editModel,
                            onSelect: () => _selectModel(model.id),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.psychology_outlined,
            size: 80,
            color: Colors.grey[400],
          ),
          SizedBox(height: 16),
          Text(
            'No Models Configured',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Add a model to get started',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _addNewModel,
            icon: Icon(Icons.add, color: Colors.white),
            label: Text(
              'Add Model',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF8B5CF6),
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}