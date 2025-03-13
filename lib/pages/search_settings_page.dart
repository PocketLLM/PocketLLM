 import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'dart:convert';

class SearchConfig {
  final String id;
  final String name;
  final String provider;
  final String apiKey;
  bool isDefault;

  SearchConfig({
    required this.id,
    required this.name,
    required this.provider,
    required this.apiKey,
    this.isDefault = false,
  });

  factory SearchConfig.fromJson(Map<String, dynamic> json) {
    return SearchConfig(
      id: json['id'] as String,
      name: json['name'] as String,
      provider: json['provider'] as String,
      apiKey: json['apiKey'] as String,
      isDefault: json['isDefault'] as bool,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'provider': provider,
      'apiKey': apiKey,
      'isDefault': isDefault,
    };
  }
}

class SearchConfigPage extends StatefulWidget {
  const SearchConfigPage({Key? key}) : super(key: key);

  @override
  State<SearchConfigPage> createState() => _SearchConfigPageState();
}

class _SearchConfigPageState extends State<SearchConfigPage> {
  final _formKey = GlobalKey<FormState>();
  List<SearchConfig> _searchConfigs = [];
  bool _isLoading = false;
  String? _selectedConfigId;

  // Controllers for the add/edit config dialog
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _apiKeyController = TextEditingController();
  String _selectedProvider = 'tavily';

  @override
  void initState() {
    super.initState();
    _loadConfigs();
  }

  Future<void> _loadConfigs() async {
    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final configsJson = prefs.getStringList('search_configs') ?? [];
      
      if (configsJson.isEmpty) {
        // Create a default config if none exists
        final defaultConfig = SearchConfig(
          id: const Uuid().v4(),
          name: 'Default Tavily Search',
          provider: 'tavily',
          apiKey: '',
          isDefault: true,
        );
        _searchConfigs = [defaultConfig];
        await _saveConfigs();
      } else {
        _searchConfigs = configsJson
            .map((json) => SearchConfig.fromJson(
                jsonDecode(json) as Map<String, dynamic>))
            .toList();
      }
      
      // Get the default config
      final defaultConfig = _searchConfigs.firstWhere(
        (config) => config.isDefault,
        orElse: () => _searchConfigs.first,
      );
      _selectedConfigId = defaultConfig.id;
      
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading configurations: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveConfigs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final configsJson = _searchConfigs
          .map((config) => jsonEncode(config.toJson()))
          .toList()
          .cast<String>();
      await prefs.setStringList('search_configs', configsJson);
      
      // Also save the active config for easy access
      if (_selectedConfigId != null) {
        final activeConfig = _searchConfigs.firstWhere(
          (config) => config.id == _selectedConfigId,
        );
        await prefs.setString('activeSearchConfig', jsonEncode(activeConfig.toJson()));
        await prefs.setString('search_provider', activeConfig.provider);
        await prefs.setString('search_api_key', activeConfig.apiKey);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving configurations: $e')),
      );
    }
  }

  void _setDefaultConfig(String id) async {
    setState(() {
      for (var config in _searchConfigs) {
        config.isDefault = config.id == id;
      }
      _selectedConfigId = id;
    });
    await _saveConfigs();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Default search configuration updated')),
    );
  }

  void _showAddConfigDialog({SearchConfig? configToEdit}) {
    // Reset or set the form values
    if (configToEdit != null) {
      _nameController.text = configToEdit.name;
      _apiKeyController.text = configToEdit.apiKey;
      _selectedProvider = configToEdit.provider;
    } else {
      _nameController.text = '';
      _apiKeyController.text = '';
      _selectedProvider = 'tavily';
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(configToEdit != null ? 'Edit Search Configuration' : 'Add Search Configuration'),
        content: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: 'Configuration Name',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a name';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 16),
                Text(
                  'Search Provider',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[700],
                  ),
                ),
                SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[400]!),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      RadioListTile<String>(
                        title: Text('Tavily'),
                        value: 'tavily',
                        groupValue: _selectedProvider,
                        onChanged: (value) {
                          setState(() {
                            _selectedProvider = value!;
                          });
                        },
                      ),
                      Divider(height: 1),
                      RadioListTile<String>(
                        title: Text('Serper (Coming Soon)'),
                        value: 'serper',
                        groupValue: _selectedProvider,
                        onChanged: null, // Disabled for now
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 16),
                TextFormField(
                  controller: _apiKeyController,
                  decoration: InputDecoration(
                    labelText: 'API Key',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter an API key';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (_formKey.currentState!.validate()) {
                if (configToEdit != null) {
                  // Update existing config
                  final index = _searchConfigs.indexWhere((c) => c.id == configToEdit.id);
                  if (index != -1) {
                    setState(() {
                      _searchConfigs[index] = SearchConfig(
                        id: configToEdit.id,
                        name: _nameController.text,
                        provider: _selectedProvider,
                        apiKey: _apiKeyController.text,
                        isDefault: configToEdit.isDefault,
                      );
                    });
                  }
                } else {
                  // Add new config
                  final newConfig = SearchConfig(
                    id: const Uuid().v4(),
                    name: _nameController.text,
                    provider: _selectedProvider,
                    apiKey: _apiKeyController.text,
                    isDefault: _searchConfigs.isEmpty,
                  );
                  
                  setState(() {
                    _searchConfigs.add(newConfig);
                    if (_searchConfigs.length == 1) {
                      _selectedConfigId = newConfig.id;
                    }
                  });
                }
                
                await _saveConfigs();
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Search configuration saved')),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF8B5CF6),
            ),
            child: Text('Save'),
          ),
        ],
      ),
    );
  }

  void _deleteConfig(String id) async {
    // Don't allow deleting the last config
    if (_searchConfigs.length <= 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Cannot delete the only configuration')),
      );
      return;
    }

    // Show confirmation dialog
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Configuration'),
        content: Text('Are you sure you want to delete this search configuration?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: Text('Delete'),
          ),
        ],
      ),
    );

    if (shouldDelete == true) {
      final isDefault = _searchConfigs.firstWhere((c) => c.id == id).isDefault;
      
      setState(() {
        _searchConfigs.removeWhere((c) => c.id == id);
        
        // If we deleted the default, set a new default
        if (isDefault && _searchConfigs.isNotEmpty) {
          _searchConfigs.first.isDefault = true;
          _selectedConfigId = _searchConfigs.first.id;
        }
      });
      
      await _saveConfigs();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Search configuration deleted')),
      );
    }
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
          'Search Configuration',
          style: TextStyle(
            color: Colors.black,
            fontSize: 32,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddConfigDialog(),
        backgroundColor: Color(0xFF8B5CF6),
        child: Icon(Icons.add),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _searchConfigs.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.search_off,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                      SizedBox(height: 16),
                      Text(
                        'No search configurations',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[700],
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Add a new configuration to get started',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                      ),
                      SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: () => _showAddConfigDialog(),
                        icon: Icon(Icons.add),
                        label: Text('Add Configuration'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFF8B5CF6),
                          padding: EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              : ListView(
                  padding: EdgeInsets.all(16),
                  children: [
                    Text(
                      'Your Search Configurations',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Configure different search providers to use with your AI assistant',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                      ),
                    ),
                    SizedBox(height: 24),
                    ..._searchConfigs.map((config) => _buildConfigCard(config)),
                    SizedBox(height: 80), // Space for FAB
                  ],
                ),
    );
  }

  Widget _buildConfigCard(SearchConfig config) {
    final isSelected = config.id == _selectedConfigId;
    
    return Card(
      elevation: 0,
      margin: EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isSelected ? Color(0xFF8B5CF6) : Colors.grey[200]!,
          width: isSelected ? 2 : 1,
        ),
      ),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        config.name,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: config.provider == 'tavily'
                                  ? Colors.blue[50]
                                  : Colors.green[50],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              config.provider.toUpperCase(),
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: config.provider == 'tavily'
                                    ? Colors.blue[700]
                                    : Colors.green[700],
                              ),
                            ),
                          ),
                          SizedBox(width: 8),
                          if (config.isDefault)
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Color(0xFF8B5CF6).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                'DEFAULT',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFF8B5CF6),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.edit, color: Colors.grey[600]),
                      onPressed: () => _showAddConfigDialog(configToEdit: config),
                    ),
                    IconButton(
                      icon: Icon(Icons.delete, color: Colors.grey[600]),
                      onPressed: () => _deleteConfig(config.id),
                    ),
                  ],
                ),
              ],
            ),
            SizedBox(height: 16),
            Text(
              'API Key: ${config.apiKey.isNotEmpty ? '${config.apiKey.substring(0, 4)}...${config.apiKey.substring(config.apiKey.length - 4)}' : 'Not set'}',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[700],
                fontFamily: 'monospace',
              ),
            ),
            SizedBox(height: 16),
            if (!config.isDefault)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => _setDefaultConfig(config.id),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF8B5CF6),
                    padding: EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text('Set as Default'),
                ),
              ),
          ],
        ),
      ),
    );
  }
}