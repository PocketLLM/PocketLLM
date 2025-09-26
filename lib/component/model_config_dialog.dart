/// File Overview:
/// - Purpose: Dialog for creating/editing model configurations with provider
///   specific helpers.
/// - Backend Migration: Keep UI but remove direct HTTP calls and rely on
///   backend-administered model import flows.
import 'package:flutter/material.dart';
import '../services/model_service.dart';
import '../component/models.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ModelConfigDialog extends StatefulWidget {
  final ModelConfig? existingConfig;
  final Function(ModelConfig) onSave;

  const ModelConfigDialog({
    Key? key,
    this.existingConfig,
    required this.onSave,
  }) : super(key: key);

  @override
  _ModelConfigDialogState createState() => _ModelConfigDialogState();
}

class _ModelConfigDialogState extends State<ModelConfigDialog> {
  final _formKey = GlobalKey<FormState>();
  final _modelService = ModelService();
  
  late TextEditingController _nameController;
  late TextEditingController _modelIdController;
  late TextEditingController _baseUrlController;
  late TextEditingController _apiKeyController;
  late TextEditingController _systemPromptController;
  late TextEditingController _temperatureController;
  late TextEditingController _apiUrlController;
  late TextEditingController _maxTokensController;
  late TextEditingController _topPController;
  late TextEditingController _frequencyPenaltyController;
  late TextEditingController _presencePenaltyController;
  
  ModelProvider _selectedProvider = ModelProvider.ollama;
  bool _isLoading = false;
  bool _isTestingConnection = false;
  bool _connectionSuccess = false;
  List<String> _availableModels = [];
  bool _isLoadingModels = false;
  bool _isFetchingApiModels = false;
  List<String> _apiModels = [];
  bool _isSaving = false;
  bool _isTesting = false;

  @override
  void initState() {
    super.initState();
    
    // Initialize with existing config if provided
    if (widget.existingConfig != null) {
      _nameController = TextEditingController(text: widget.existingConfig!.name);
      _modelIdController = TextEditingController(text: widget.existingConfig!.model);
      _baseUrlController = TextEditingController(text: widget.existingConfig!.baseUrl);
      _apiKeyController = TextEditingController(text: widget.existingConfig!.apiKey ?? '');
      
      // Initialize additional parameters
      _systemPromptController = TextEditingController(text: widget.existingConfig!.systemPrompt ?? '');
      _temperatureController = TextEditingController(text: widget.existingConfig!.temperature.toString());
      _maxTokensController = TextEditingController(text: (widget.existingConfig!.maxTokens ?? 2048).toString());
      _topPController = TextEditingController(text: (widget.existingConfig!.topP ?? 1.0).toString());
      _frequencyPenaltyController = TextEditingController(text: (widget.existingConfig!.frequencyPenalty ?? 0.0).toString());
      _presencePenaltyController = TextEditingController(text: (widget.existingConfig!.presencePenalty ?? 0.0).toString());
      _apiUrlController = TextEditingController();
      
      _selectedProvider = widget.existingConfig!.provider;
    } else {
      _nameController = TextEditingController();
      _modelIdController = TextEditingController();
      _baseUrlController = TextEditingController(text: ModelProvider.ollama.defaultBaseUrl);
      _apiKeyController = TextEditingController();
      _systemPromptController = TextEditingController(text: 'You are a helpful assistant.');
      _temperatureController = TextEditingController(text: '0.7');
      _maxTokensController = TextEditingController(text: '2048');
      _topPController = TextEditingController(text: '1.0');
      _frequencyPenaltyController = TextEditingController(text: '0.0');
      _presencePenaltyController = TextEditingController(text: '0.0');
      _apiUrlController = TextEditingController();
    }
    
    // If provider is Ollama, load models automatically
    if (_selectedProvider == ModelProvider.ollama) {
      _loadOllamaModels();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _modelIdController.dispose();
    _baseUrlController.dispose();
    _apiKeyController.dispose();
    _systemPromptController.dispose();
    _temperatureController.dispose();
    _apiUrlController.dispose();
    _maxTokensController.dispose();
    _topPController.dispose();
    _frequencyPenaltyController.dispose();
    _presencePenaltyController.dispose();
    super.dispose();
  }

  // Load available models from Ollama
  Future<void> _loadOllamaModels() async {
    if (_selectedProvider != ModelProvider.ollama) return;
    
    setState(() {
      _isLoadingModels = true;
    });
    
    try {
      final models = await _modelService.getOllamaModels(_baseUrlController.text);
      setState(() {
        _availableModels = models;
        _isLoadingModels = false;
      });
    } catch (e) {
      setState(() {
        _availableModels = [];
        _isLoadingModels = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load models: $e')),
      );
    }
  }

  // Fetch models from API URL
  Future<void> _fetchModelsFromApi() async {
    if (_apiUrlController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please enter an API URL')),
      );
      return;
    }
    
    setState(() {
      _isFetchingApiModels = true;
      _apiModels = [];
    });
    
    try {
      final url = _apiUrlController.text.trim();
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
        },
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        List<String> models = [];
        
        // Try to extract models based on common API formats
        if (data['data'] != null && data['data'] is List) {
          // OpenAI-like format
          final modelsList = data['data'] as List;
          models = modelsList
              .map((model) => model['id']?.toString() ?? '')
              .where((id) => id.isNotEmpty)
              .toList();
        } else if (data['models'] != null && data['models'] is List) {
          // Ollama-like format
          final modelsList = data['models'] as List;
          models = modelsList
              .map((model) => model['name']?.toString() ?? model['id']?.toString() ?? '')
              .where((name) => name.isNotEmpty)
              .toList();
        }
        
        setState(() {
          _apiModels = models;
          _isFetchingApiModels = false;
        });
        
        if (models.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('No models found in the API response')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Found ${models.length} models')),
          );
        }
      } else {
        setState(() {
          _isFetchingApiModels = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to fetch models: ${response.statusCode}')),
        );
      }
    } catch (e) {
      setState(() {
        _isFetchingApiModels = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching models: $e')),
      );
    }
  }

  // Test connection to the model provider
  Future<void> _testConnection() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isTestingConnection = true;
        _connectionSuccess = false;
      });
      
      try {
        final config = ModelConfig(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          name: _nameController.text,
          provider: _selectedProvider,
          baseUrl: _baseUrlController.text,
          apiKey: _apiKeyController.text.isNotEmpty ? _apiKeyController.text : null,
          model: _modelIdController.text,
          systemPrompt: _systemPromptController.text,
          temperature: double.tryParse(_temperatureController.text) ?? 0.7,
          maxTokens: int.tryParse(_maxTokensController.text) ?? 2048,
          topP: double.tryParse(_topPController.text) ?? 1.0,
          frequencyPenalty: double.tryParse(_frequencyPenaltyController.text) ?? 0.0,
          presencePenalty: double.tryParse(_presencePenaltyController.text) ?? 0.0,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        
        final success = await _modelService.testConnection(config);
        
        setState(() {
          _isTestingConnection = false;
          _connectionSuccess = success;
        });
        
        if (success && _selectedProvider == ModelProvider.ollama) {
          _loadOllamaModels();
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success ? 'Connection successful!' : 'Connection failed'),
            backgroundColor: success ? Colors.green : Colors.red,
          ),
        );
      } catch (e) {
        setState(() {
          _isTestingConnection = false;
          _connectionSuccess = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error testing connection: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _saveModel() {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    
    final config = ModelConfig(
      id: widget.existingConfig?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      name: _nameController.text,
      provider: _selectedProvider,
      baseUrl: _baseUrlController.text,
      apiKey: _apiKeyController.text.isNotEmpty ? _apiKeyController.text : null,
      model: _modelIdController.text,
      systemPrompt: _systemPromptController.text,
      temperature: double.tryParse(_temperatureController.text) ?? 0.7,
      maxTokens: int.tryParse(_maxTokensController.text) ?? 2048,
      topP: double.tryParse(_topPController.text) ?? 1.0,
      frequencyPenalty: double.tryParse(_frequencyPenaltyController.text) ?? 0.0,
      presencePenalty: double.tryParse(_presencePenaltyController.text) ?? 0.0,
      createdAt: widget.existingConfig?.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
    );
    
    widget.onSave(config);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        widget.existingConfig != null ? 'Edit Model' : 'Add New Model',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close, color: Colors.grey),
                      onPressed: () => Navigator.of(context).pop(),
                      padding: EdgeInsets.zero,
                      constraints: BoxConstraints(),
                    ),
                  ],
                ),
                SizedBox(height: 24),
                
                // Provider dropdown
                Text(
                  'Provider',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
                SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<ModelProvider>(
                      isExpanded: true,
                      value: _selectedProvider,
                      items: ModelProvider.values.map((provider) {
                        return DropdownMenuItem<ModelProvider>(
                          value: provider,
                          child: Text(provider.displayName),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _selectedProvider = value;
                            
                            // Set default URL based on provider
                            if (value == ModelProvider.ollama) {
                              _baseUrlController.text = ModelProvider.ollama.defaultBaseUrl;
                              _loadOllamaModels();
                            } else if (value == ModelProvider.openAI) {
                              _baseUrlController.text = 'https://api.openai.com/v1';
                            } else if (value == ModelProvider.anthropic) {
                              _baseUrlController.text = 'https://api.anthropic.com';
                            } else {
                              _baseUrlController.text = '';
                            }
                          });
                        }
                      },
                    ),
                  ),
                ),
                SizedBox(height: 16),
                
                // Display name field
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: 'Display Name',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a display name';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 16),
                
                // API URL for fetching models
                if (_selectedProvider == ModelProvider.openAI)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'API URL for Models (Optional)',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.black87,
                        ),
                      ),
                      SizedBox(height: 8),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _apiUrlController,
                              decoration: InputDecoration(
                                labelText: 'API URL',
                                hintText: 'https://api.example.com/v1/models',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: _isFetchingApiModels ? null : _fetchModelsFromApi,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Color(0xFF8B5CF6),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                            ),
                            child: _isFetchingApiModels
                                ? SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                    ),
                                  )
                                : Icon(
                                    Icons.refresh,
                                    color: Colors.white,
                                  ),
                          ),
                        ],
                      ),
                      SizedBox(height: 16),
                      
                      // API Models dropdown
                      if (_apiModels.isNotEmpty)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Available API Models',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: Colors.black87,
                              ),
                            ),
                            SizedBox(height: 8),
                            Container(
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey[300]!),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: EdgeInsets.symmetric(horizontal: 12),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  isExpanded: true,
                                  value: _apiModels.contains(_modelIdController.text) 
                                      ? _modelIdController.text 
                                      : null,
                                  hint: Text('Select a model'),
                                  items: _apiModels.map((model) {
                                    return DropdownMenuItem<String>(
                                      value: model,
                                      child: Text(model),
                                    );
                                  }).toList(),
                                  onChanged: (value) {
                                    if (value != null) {
                                      setState(() {
                                        _modelIdController.text = value;
                                        if (_nameController.text.isEmpty) {
                                          _nameController.text = value;
                                        }
                                      });
                                    }
                                  },
                                ),
                              ),
                            ),
                            SizedBox(height: 16),
                          ],
                        ),
                    ],
                  ),
                
                // Model ID field
                if (_selectedProvider == ModelProvider.ollama && _availableModels.isNotEmpty)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Model ID',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.black87,
                        ),
                      ),
                      SizedBox(height: 8),
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey[300]!),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: EdgeInsets.symmetric(horizontal: 12),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            isExpanded: true,
                            value: _availableModels.contains(_modelIdController.text) 
                                ? _modelIdController.text 
                                : null,
                            hint: Text('Select a model'),
                            items: _availableModels.map((model) {
                              return DropdownMenuItem<String>(
                                value: model,
                                child: Text(model),
                              );
                            }).toList(),
                            onChanged: (value) {
                              if (value != null) {
                                setState(() {
                                  _modelIdController.text = value;
                                  if (_nameController.text.isEmpty) {
                                    _nameController.text = value;
                                  }
                                });
                              }
                            },
                          ),
                        ),
                      ),
                    ],
                  )
                else
                  TextFormField(
                    controller: _modelIdController,
                    decoration: InputDecoration(
                      labelText: 'Model ID',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a model ID';
                      }
                      return null;
                    },
                  ),
                SizedBox(height: 16),
                
                // Base URL field
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _baseUrlController,
                        decoration: InputDecoration(
                          labelText: 'Base URL',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          hintText: _selectedProvider == ModelProvider.ollama 
                              ? ModelProvider.ollama.defaultBaseUrl 
                              : 'Enter API URL',
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter a base URL';
                          }
                          return null;
                        },
                      ),
                    ),
                    SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: _isTestingConnection ? null : _testConnection,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _connectionSuccess ? Colors.green : Color(0xFF8B5CF6),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      ),
                      child: _isTestingConnection
                          ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : Icon(
                              _connectionSuccess ? Icons.check : Icons.refresh,
                              color: Colors.white,
                            ),
                    ),
                  ],
                ),
                SizedBox(height: 16),
                
                // API Key field (if needed)
                if (_selectedProvider != ModelProvider.ollama)
                  Column(
                    children: [
                      TextFormField(
                        controller: _apiKeyController,
                        decoration: InputDecoration(
                          labelText: 'API Key',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        obscureText: true,
                        validator: (value) {
                          if (_selectedProvider != ModelProvider.ollama && 
                              (value == null || value.isEmpty)) {
                            return 'Please enter an API key';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 16),
                    ],
                  ),
                
                // System Prompt field
                TextFormField(
                  controller: _systemPromptController,
                  decoration: InputDecoration(
                    labelText: 'System Prompt (Optional)',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    hintText: 'You are a helpful assistant...',
                  ),
                  maxLines: 3,
                ),
                SizedBox(height: 16),
                
                // Temperature field
                TextFormField(
                  controller: _temperatureController,
                  decoration: InputDecoration(
                    labelText: 'Temperature',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    hintText: '0.7',
                  ),
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a temperature value';
                    }
                    final temp = double.tryParse(value);
                    if (temp == null) {
                      return 'Please enter a valid number';
                    }
                    if (temp < 0 || temp > 2) {
                      return 'Temperature should be between 0 and 2';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 16),
                
                // Loading models indicator
                if (_isLoadingModels)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16.0),
                      child: Column(
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 8),
                          Text('Loading available models...'),
                        ],
                      ),
                    ),
                  ),
                
                SizedBox(height: 24),
                
                // Action buttons
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          backgroundColor: Colors.grey[100],
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'Cancel',
                          style: TextStyle(
                            color: Colors.black87,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _saveModel,
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          backgroundColor: Color(0xFF8B5CF6),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isLoading
                            ? SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : Text(
                                'Save',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.white,
                                ),
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