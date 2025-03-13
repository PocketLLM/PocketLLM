import 'package:flutter/material.dart';
import '../services/model_service.dart';
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
  String? _selectedModelId;
  bool _isLoading = true;
  final _authService = AuthService();

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
      // Use filtered model configs based on authentication status
      final configs = await ModelService.getFilteredModelConfigs();
      final selectedId = await ModelService.getSelectedModel();

      // If user is logged in, fetch PocketLLM models
      if (_authService.isLoggedIn) {
        final pocketLLMModels = await _fetchPocketLLMModels();
        // Add PocketLLM models if they don't already exist
        for (var model in pocketLLMModels) {
          if (!configs.any((c) => c.id == model.id)) {
            configs.add(model);
            await ModelService.saveModelConfig(model);
          }
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
        SnackBar(content: Text('Failed to load model configurations: $e')),
      );
    }
  }

  Future<List<ModelConfig>> _fetchPocketLLMModels() async {
    try {
      final models = await PocketLLMService.getAvailableModels();
      return models.map((model) {
        final modelName = model['display_name'] ?? model['name'] ?? 'Unnamed Model';
        final modelId = model['id'] ?? model['name'] ?? modelName;
        return ModelConfig(
          id: modelId,
          name: modelName,
          provider: ModelProvider.pocketLLM,
          baseUrl: '',  // Hide sensitive information
          apiKey: '',   // Hide sensitive information
          additionalParams: {
            'temperature': 0.7,
            'systemPrompt': 'You are a helpful AI assistant.',
          },
        );
      }).toList();
    } catch (e) {
      print('Error fetching PocketLLM models: $e');
      return [];
    }
  }

  void _addNewModel() {
    if (!_authService.isLoggedIn && _modelConfigs.every((c) => c.provider != ModelProvider.pocketLLM)) {
      _showSignInPrompt();
      return;
    }
    showDialog(
      context: context,
      builder: (context) => ModelConfigDialog(
        onSave: (config) async {
          await ModelService.saveModelConfig(config);
          if (_modelConfigs.isEmpty) {
            await ModelService.setSelectedModel(config.id);
          }
          _loadModelConfigs();
        },
      ),
    );
  }

  void _editModel(ModelConfig config) async {
    await ModelService.saveModelConfig(config);
    _loadModelConfigs();
  }

  void _deleteModel(String id) async {
    await ModelService.deleteModelConfig(id);
    if (_selectedModelId == id && _modelConfigs.isNotEmpty) {
      final remainingConfigs = _modelConfigs.where((c) => c.id != id).toList();
      if (remainingConfigs.isNotEmpty) {
        await ModelService.setSelectedModel(remainingConfigs.first.id);
      } else {
        await ModelService.clearSelectedModel();
      }
    }
    _loadModelConfigs();
  }

  void _selectModel(String id) async {
    final selectedConfig = _modelConfigs.firstWhere((c) => c.id == id);
    if (selectedConfig.provider == ModelProvider.pocketLLM && !_authService.isLoggedIn) {
      _showSignInPrompt();
      return;
    }
    await ModelService.setSelectedModel(id);
    setState(() {
      _selectedModelId = id;
    });
  }

  void _showSignInPrompt() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Sign in to access PocketLLM models'),
        action: SnackBarAction(
          label: 'Sign In',
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => AuthPage(
                  onLoginSuccess: (email) {
                    _loadModelConfigs();
                    Navigator.pop(context);
                  },
                ),
              ),
            );
          },
        ),
      ),
    );
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
          if (!_authService.isLoggedIn)
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              color: Color(0xFFFEF3C7),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Color(0xFFD97706)),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Sign in to access PocketLLM models',
                      style: TextStyle(color: Color(0xFFB45309)),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AuthPage(
                            onLoginSuccess: (email) {
                              _loadModelConfigs();
                              Navigator.pop(context);
                            },
                          ),
                        ),
                      );
                    },
                    child: Text(
                      'Sign In',
                      style: TextStyle(
                        color: Color(0xFF8B5CF6),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
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