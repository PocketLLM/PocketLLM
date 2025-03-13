import 'package:flutter/material.dart';
import '../component/models.dart';
import 'dart:ui';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../services/model_service.dart' as service;
import '../services/termux_service.dart';
import '../component/model_input_dialog.dart';
import '../component/ollama_model.dart';
import '../component/model_parameter_dialog.dart';

class LibraryPage extends StatefulWidget {
  const LibraryPage({Key? key}) : super(key: key);

  @override
  _LibraryPageState createState() => _LibraryPageState();
}

class _LibraryPageState extends State<LibraryPage> with TickerProviderStateMixin {
  String _filterText = '';
  String _selectedCategory = 'All Models';
  final List<String> _categories = ['All Models', 'Text', 'Vision', 'Code', 'Embedding', 'Audio'];
  List<Map<String, dynamic>> _ollamaModels = [];
  List<Map<String, dynamic>> _downloadedModels = [];
  List<OllamaModel> _availableOllamaModels = [];
  Map<String, OllamaModel> _downloadingModels = {};
  bool _isLoading = true;
  String _selectedSort = 'Latest';
  final List<String> _sortOptions = ['Latest', 'Name', 'Size', 'Downloads'];
  TabController? _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      initialIndex: 0,
      length: 2,
      vsync: this,
    );
    _fetchDownloadedModels();
    _loadAvailableOllamaModels();
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  Future<void> _fetchDownloadedModels() async {
    try {
      final response = await http.get(Uri.parse('http://localhost:11434/api/tags'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _downloadedModels = List<Map<String, dynamic>>.from(data['models'] ?? []);
        });
      }
    } catch (e) {
      print('Error fetching downloaded models: $e');
    }
  }

  void _loadAvailableOllamaModels() {
    setState(() {
      _isLoading = true;
      _availableOllamaModels = OllamaModel.getAllModels();
      _isLoading = false;
    });
  }

  void _showFilterOptions() {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Container(
          padding: EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Sort by',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 16),
              Wrap(
                spacing: 8,
                children: _sortOptions.map((sort) => ChoiceChip(
                  label: Text(sort),
                  selected: _selectedSort == sort,
                  onSelected: (selected) {
                    if (selected) {
                      this.setState(() => _selectedSort = sort);
                      Navigator.pop(context);
                    }
                  },
                )).toList(),
              ),
              SizedBox(height: 20),
              Text(
                'Categories',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 16),
              Wrap(
                spacing: 8,
                children: _categories.map((category) => ChoiceChip(
                  label: Text(category),
                  selected: category == _selectedCategory,
                  onSelected: (selected) {
                    if (selected) {
                      this.setState(() => _selectedCategory = category);
                      Navigator.pop(context);
                    }
                  },
                )).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showInstallOptions(OllamaModel model) {
    showDialog(
      context: context,
      builder: (context) => ModelParameterDialog(
        model: model,
        onInstall: (modelName, fullModelName) {
          _installModelWithParameter(model, fullModelName);
        },
      ),
    );
  }

  void _installModelWithParameter(OllamaModel model, String fullModelName) async {
    try {
      setState(() {
        model.isDownloading = true;
        model.downloadProgress = 0.0;
        _downloadingModels[model.name] = model;
      });

      // Start the download process
      await TermuxService.runCommand(
        context,
        'ollama pull $fullModelName',
        onOutput: (output) {
          // Parse download progress from output
          if (output.contains('%')) {
            try {
              final regex = RegExp(r'(\d+)%');
              final match = regex.firstMatch(output);
              if (match != null) {
                final progress = int.parse(match.group(1)!) / 100.0;
                setState(() {
                  model.downloadProgress = progress;
                  _downloadingModels[model.name] = model;
                });
              }
            } catch (e) {
              print('Error parsing progress: $e');
            }
          }
        },
      );

      // When download completes
      setState(() {
        model.isDownloading = false;
        model.isDownloaded = true;
        model.downloadProgress = 1.0;
        _downloadingModels[model.name] = model;
      });

      // Refresh downloaded models list
      _fetchDownloadedModels();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$fullModelName installed successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() {
        model.isDownloading = false;
        model.downloadProgress = 0.0;
        _downloadingModels[model.name] = model;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error installing model: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showDeleteConfirmation(Map<String, dynamic> model) {
    showDialog(
      context: context,
      builder: (context) => PermissionDialog(
        title: 'Delete Model',
        description: 'Are you sure you want to delete ${model['name']}? This action cannot be undone.',
        onContinue: () async {
          Navigator.pop(context);
          try {
            await TermuxService.runCommand(
              context,
              'ollama rm ${model['name']}',
            );
            _fetchDownloadedModels();
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Model deleted successfully')),
              );
            }
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Error deleting model: $e'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          }
        },
        onCancel: () => Navigator.pop(context),
      ),
    );
  }

  void _configureModel(Map<String, dynamic> model) async {
    try {
      final config = service.ModelConfig(
        id: model['name'],
        name: model['name'],
        provider: service.ModelProvider.ollama,
        baseUrl: 'http://localhost:11434',
      );
      await service.ModelService.saveModelConfig(config);
      await service.ModelService.setSelectedModel(config.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Model configured successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error configuring model: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _installModel(String modelName) {
    showDialog(
      context: context,
      builder: (context) => PermissionDialog(
        title: 'Install Model',
        description: 'Do you want to install $modelName?',
        onContinue: () async {
          Navigator.pop(context);
          try {
            await TermuxService.runCommand(
              context,
              'ollama pull $modelName',
            );
            _fetchDownloadedModels();
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Installing $modelName...'),
                  duration: Duration(seconds: 2),
                ),
              );
            }
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Error installing model: $e'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          }
        },
        onCancel: () => Navigator.pop(context),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_tabController == null) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.grey[50],
        elevation: 0,
        title: Text(
          'Model Library',
          style: TextStyle(
            color: Colors.black,
            fontSize: 32,
            fontWeight: FontWeight.bold,
          ),
        ),
        bottom: TabBar(
          controller: _tabController!,
          labelColor: Color(0xFF8B5CF6),
          unselectedLabelColor: Colors.grey[600],
          indicatorColor: Color(0xFF8B5CF6),
          tabs: const [
            Tab(text: 'Downloaded'),
            Tab(text: 'Available'),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: Colors.black),
            onPressed: () {
              _fetchDownloadedModels();
            },
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController!,
        children: [
          _buildDownloadedModelsTab(),
          _buildAvailableModelsTab(),
        ],
      ),
    );
  }

  Widget _buildDownloadedModelsTab() {
    return Column(
      children: [
        Padding(
          padding: EdgeInsets.all(16),
          child: _buildSearchBar(),
        ),
        Expanded(
          child: ListView.builder(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            itemCount: _downloadedModels.length,
            itemBuilder: (context, index) {
              final model = _downloadedModels[index];
              if (_filterText.isNotEmpty &&
                  !model['name'].toString().toLowerCase().contains(_filterText.toLowerCase())) {
                return SizedBox.shrink();
              }
              return _buildDownloadedModelCard(model);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildAvailableModelsTab() {
    // Filter models by category
    List<OllamaModel> filteredModels = _availableOllamaModels;
    if (_selectedCategory != 'All Models') {
      filteredModels = _availableOllamaModels
          .where((model) => model.category == _selectedCategory)
          .toList();
    }

    // Filter models by search text
    if (_filterText.isNotEmpty) {
      filteredModels = filteredModels
          .where((model) => 
              model.name.toLowerCase().contains(_filterText.toLowerCase()) ||
              model.description.toLowerCase().contains(_filterText.toLowerCase()))
          .toList();
    }

    // Sort models
    switch (_selectedSort) {
      case 'Latest':
        // Already sorted by latest in the API
        break;
      case 'Name':
        filteredModels.sort((a, b) => a.name.compareTo(b.name));
        break;
      case 'Size':
        // Sort by parameter size (largest first)
        filteredModels.sort((a, b) {
          if (a.parameters.isEmpty || b.parameters.isEmpty) return 0;
          
          // Extract the largest parameter size for each model
          int getMaxSize(List<String> params) {
            int maxSize = 0;
            for (var param in params) {
              if (param.contains('b')) {
                final sizeStr = param.replaceAll(RegExp(r'[^0-9.]'), '');
                final size = double.tryParse(sizeStr) ?? 0;
                final multiplier = param.toLowerCase().contains('b') ? 1 : 0.001;
                final sizeInB = (size * multiplier).round();
                if (sizeInB > maxSize) maxSize = sizeInB;
              }
            }
            return maxSize;
          }
          
          return getMaxSize(b.parameters).compareTo(getMaxSize(a.parameters));
        });
        break;
      case 'Downloads':
        filteredModels.sort((a, b) => b.pulls.compareTo(a.pulls));
        break;
    }

    return Column(
      children: [
        Padding(
          padding: EdgeInsets.all(16),
          child: _buildSearchBar(),
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: _categories.map((category) {
                return Padding(
                  padding: EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(category),
                    selected: category == _selectedCategory,
                    onSelected: (selected) {
                      if (selected) {
                        setState(() => _selectedCategory = category);
                      }
                    },
                  ),
                );
              }).toList(),
            ),
          ),
        ),
        SizedBox(height: 8),
        Expanded(
          child: _isLoading
              ? Center(child: CircularProgressIndicator())
              : filteredModels.isEmpty
                  ? Center(
                      child: Text(
                        'No models found matching your criteria',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                      ),
                    )
                  : ListView.builder(
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      itemCount: filteredModels.length,
                      itemBuilder: (context, index) {
                        final model = filteredModels[index];
                        return _buildAvailableModelCard(model);
                      },
                    ),
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 12),
            child: Icon(Icons.search, color: Colors.grey[600], size: 20),
          ),
          Expanded(
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search models...',
                hintStyle: TextStyle(color: Colors.grey[500], fontSize: 14),
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
              ),
              onChanged: (value) => setState(() => _filterText = value),
            ),
          ),
          IconButton(
            icon: Icon(Icons.tune, color: Colors.grey[600], size: 20),
            onPressed: _showFilterOptions,
          ),
        ],
      ),
    );
  }

  Widget _buildDownloadedModelCard(Map<String, dynamic> model) {
    return Card(
      margin: EdgeInsets.only(bottom: 16),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [Colors.purple.shade200, Colors.purple.shade400],
                    ),
                  ),
                  child: Icon(Icons.auto_awesome, color: Colors.white),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        model['name'].toString(),
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        'Size: ${model['size'] ?? 'Unknown'}',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _configureModel(model),
                    icon: Icon(Icons.settings),
                    label: Text('Configure'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Color(0xFF8B5CF6),
                      side: BorderSide(color: Color(0xFF8B5CF6)),
                      padding: EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _showDeleteConfirmation(model),
                    icon: Icon(Icons.delete_outline),
                    label: Text('Delete'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade50,
                      foregroundColor: Colors.red,
                      elevation: 0,
                      padding: EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: BorderSide(color: Colors.red.shade200),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvailableModelCard(OllamaModel model) {
    // Check if model is in downloading state
    final isDownloading = _downloadingModels.containsKey(model.name) && 
                          _downloadingModels[model.name]!.isDownloading;
    
    // Check if model is already downloaded
    final isDownloaded = _downloadingModels.containsKey(model.name) && 
                         _downloadingModels[model.name]!.isDownloaded;
    
    // Get download progress
    final downloadProgress = _downloadingModels.containsKey(model.name) 
        ? _downloadingModels[model.name]!.downloadProgress 
        : 0.0;

    return Card(
      margin: EdgeInsets.only(bottom: 16),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        model.getCategoryColor().withOpacity(0.7),
                        model.getCategoryColor(),
                      ],
                    ),
                  ),
                  child: Icon(model.getCategoryIcon(), color: Colors.white),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        model.name,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Container(
                        margin: EdgeInsets.only(top: 4),
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: model.getCategoryColor().withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          model.category,
                          style: TextStyle(
                            color: model.getCategoryColor()[700],
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (model.pulls > 0)
                  Chip(
                    label: Text(
                      '${(model.pulls / 1000000).toStringAsFixed(1)}M',
                      style: TextStyle(fontSize: 12),
                    ),
                    backgroundColor: Colors.grey.shade100,
                  ),
              ],
            ),
            if (model.description.isNotEmpty) ...[
              SizedBox(height: 12),
              Text(
                model.description,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[800],
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            if (model.parameters.isNotEmpty) ...[
              SizedBox(height: 12),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: model.parameters.map((param) => Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Color(0xFFEEF2FF),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    param,
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFF6366F1),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                )).toList(),
              ),
            ],
            SizedBox(height: 16),
            if (isDownloading) ...[
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Downloading: ${(downloadProgress * 100).toInt()}%',
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF8B5CF6),
                    ),
                  ),
                  SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: downloadProgress,
                    backgroundColor: Colors.grey.shade200,
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF8B5CF6)),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ],
              ),
            ] else if (isDownloaded) ...[
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _configureModel(_downloadedModels.firstWhere(
                        (m) => m['name'] == model.name,
                        orElse: () => {'name': model.name},
                      )),
                      icon: Icon(Icons.settings),
                      label: Text('Configure'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Color(0xFF8B5CF6),
                        side: BorderSide(color: Color(0xFF8B5CF6)),
                        padding: EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ] else ...[
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _showInstallOptions(model),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF8B5CF6),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: Text('Download'),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}