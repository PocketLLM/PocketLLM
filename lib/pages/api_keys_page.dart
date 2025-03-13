import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/model_service.dart';

class ApiKeysPage extends StatefulWidget {
  const ApiKeysPage({Key? key}) : super(key: key);

  @override
  _ApiKeysPageState createState() => _ApiKeysPageState();
}

class _ApiKeysPageState extends State<ApiKeysPage> {
  List<ModelConfig> _modelConfigs = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadApiKeys();
  }

  Future<void> _loadApiKeys() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final configs = await ModelService.getModelConfigs();
      
      // Filter configs to only include those with API keys
      final configsWithKeys = configs.where((config) => config.apiKey != null && config.apiKey!.isNotEmpty).toList();
      
      setState(() {
        _modelConfigs = configsWithKeys;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load API keys: $e')),
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
          'API Keys',
          style: TextStyle(
            color: Colors.black,
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _modelConfigs.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  padding: EdgeInsets.all(16),
                  itemCount: _modelConfigs.length,
                  itemBuilder: (context, index) {
                    final model = _modelConfigs[index];
                    return _buildApiKeyCard(model);
                  },
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.key_off_outlined,
            size: 80,
            color: Colors.grey[400],
          ),
          SizedBox(height: 16),
          Text(
            'No API Keys Found',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Add models with API keys in Model Settings',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildApiKeyCard(ModelConfig model) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: ExpansionTile(
        leading: _getProviderIcon(model.provider),
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
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Divider(),
                SizedBox(height: 8),
                Row(
                  children: [
                    Text(
                      'API Key:',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey[700],
                      ),
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '••••••••••••••••${model.apiKey!.substring(model.apiKey!.length - 4)}',
                        style: TextStyle(
                          fontSize: 14,
                          fontFamily: 'monospace',
                          color: Colors.black87,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton.icon(
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: model.apiKey!));
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('API key copied to clipboard')),
                        );
                      },
                      icon: Icon(Icons.copy, size: 18),
                      label: Text('Copy'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Color(0xFF8B5CF6),
                        side: BorderSide(color: Color(0xFF8B5CF6)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                    SizedBox(width: 8),
                    OutlinedButton.icon(
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: Text('API Key'),
                            content: SelectableText(
                              model.apiKey!,
                              style: TextStyle(fontFamily: 'monospace'),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: Text('Close'),
                              ),
                            ],
                          ),
                        );
                      },
                      icon: Icon(Icons.visibility, size: 18),
                      label: Text('View'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.grey[700],
                        side: BorderSide(color: Colors.grey[400]!),
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

  Widget _getProviderIcon(ModelProvider provider) {
    IconData iconData;
    Color iconColor;

    switch (provider) {
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
        // TODO: Handle this case.
        throw UnimplementedError();
      case ModelProvider.mistral:
        // TODO: Handle this case.
        throw UnimplementedError();
      case ModelProvider.deepseek:
        // TODO: Handle this case.
        throw UnimplementedError();
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
} 