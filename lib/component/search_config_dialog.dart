import 'package:flutter/material.dart';
import '../services/search_service.dart';

class SearchConfigDialog extends StatefulWidget {
  final SearchConfig? existingConfig;
  final Function(SearchConfig) onSave;

  const SearchConfigDialog({
    Key? key,
    this.existingConfig,
    required this.onSave,
  }) : super(key: key);

  @override
  _SearchConfigDialogState createState() => _SearchConfigDialogState();
}

class _SearchConfigDialogState extends State<SearchConfigDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _apiKeyController;
  late TextEditingController _baseUrlController;
  
  SearchProvider _selectedProvider = SearchProvider.tavily;
  bool _isLoading = false;
  bool _isTestingConnection = false;
  bool _connectionSuccess = false;

  @override
  void initState() {
    super.initState();
    
    // Initialize with existing config if provided
    if (widget.existingConfig != null) {
      _nameController = TextEditingController(text: widget.existingConfig!.name);
      _apiKeyController = TextEditingController(text: widget.existingConfig!.apiKey ?? '');
      _baseUrlController = TextEditingController(text: widget.existingConfig!.baseUrl);
      _selectedProvider = widget.existingConfig!.provider;
    } else {
      _nameController = TextEditingController();
      _apiKeyController = TextEditingController();
      _baseUrlController = TextEditingController(text: SearchService.getDefaultUrlForProvider(SearchProvider.tavily));
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _apiKeyController.dispose();
    _baseUrlController.dispose();
    super.dispose();
  }

  // Test connection to the search provider
  Future<void> _testConnection() async {
    setState(() {
      _isTestingConnection = true;
      _connectionSuccess = false;
    });
    
    try {
      final config = SearchConfig(
        id: _selectedProvider.toString().split('.').last,
        name: _nameController.text,
        provider: _selectedProvider,
        baseUrl: _baseUrlController.text,
        apiKey: _apiKeyController.text,
      );
      
      final success = await SearchService.testConnection(config);
      
      setState(() {
        _isTestingConnection = false;
        _connectionSuccess = success;
      });
      
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
          content: Text('Connection test failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Save the search configuration
  void _saveConfig() {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });
      
      final config = SearchConfig(
        id: _selectedProvider.toString().split('.').last,
        name: _nameController.text,
        provider: _selectedProvider,
        baseUrl: _baseUrlController.text,
        apiKey: _apiKeyController.text,
      );
      
      widget.onSave(config);
      
      setState(() {
        _isLoading = false;
      });
      
      Navigator.of(context).pop();
    }
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
                        widget.existingConfig != null ? 'Edit Search Provider' : 'Add Search Provider',
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
                    child: DropdownButton<SearchProvider>(
                      isExpanded: true,
                      value: _selectedProvider,
                      items: SearchProvider.values.map((provider) {
                        return DropdownMenuItem<SearchProvider>(
                          value: provider,
                          child: Text(provider.displayName),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _selectedProvider = value;
                            _baseUrlController.text = SearchService.getDefaultUrlForProvider(value);
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
                
                // API Key field
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
                    if (value == null || value.isEmpty) {
                      return 'Please enter an API key';
                    }
                    return null;
                  },
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
                        onPressed: _isLoading ? null : _saveConfig,
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