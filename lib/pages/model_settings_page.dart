/// File Overview:
/// - Purpose: Manage model configurations and providers entirely from the
///   client UI.
/// - Backend Migration: Keep UI but rely on backend-managed providers/models,
///   removing any direct client-side persistence.
import 'package:flutter/material.dart';
import '../component/models.dart';
import '../component/model_config_dialog.dart';
import '../component/model_list_item.dart';
import '../services/backend_api_service.dart';
import '../services/model_service.dart';
import 'auth/auth_page.dart';

class ModelSettingsPage extends StatefulWidget {
  const ModelSettingsPage({Key? key}) : super(key: key);

  @override
  _ModelSettingsPageState createState() => _ModelSettingsPageState();
}

class _ModelSettingsPageState extends State<ModelSettingsPage> {
  final ModelService _modelService = ModelService();

  List<ModelConfig> _modelConfigs = [];
  List<ProviderConnection> _providers = [];
  bool _isLoadingModels = true;
  bool _isLoadingProviders = true;
  String? _selectedModelId;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    await Future.wait([
      _loadProviders(),
      _loadModels(),
    ]);
  }

  Future<void> _loadProviders() async {
    setState(() {
      _isLoadingProviders = true;
    });

    try {
      final providers = await _modelService.getProviders();
      setState(() {
        _providers = providers;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load providers: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingProviders = false;
        });
      }
    }
  }

  Future<void> _loadModels({bool refreshRemote = true}) async {
    setState(() {
      _isLoadingModels = true;
    });

    try {
      final models = await _modelService.getSavedModels(refreshRemote: refreshRemote);
      final defaultId = await _modelService.getDefaultModel();
      if (!mounted) return;
      setState(() {
        _modelConfigs = models;
        _selectedModelId = defaultId;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load models: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingModels = false;
        });
      }
    }
  }

  Future<void> _refreshAll() async {
    await Future.wait([
      _loadProviders(),
      _loadModels(),
    ]);
  }

  void _showAddModelSheet() {
    final activeProviders = _providers.where((p) => p.isActive).toList();
    if (activeProviders.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Activate a provider in API Keys first.')),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => _AddModelSheet(
        providers: activeProviders,
        onImport: (provider, selections) async {
          Navigator.of(context).pop();
          await _importModels(provider, selections);
        },
      ),
    );
  }

  Future<void> _importModels(
    ProviderConnection provider,
    List<AvailableModelOption> selections,
  ) async {
    setState(() {
      _isLoadingModels = true;
    });

    try {
      await _modelService.importModelsFromProvider(
        provider: provider.provider,
        providerId: provider.id,
        selections: selections,
      );
      await _loadModels();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Imported ${selections.length} model(s) from ${provider.displayName}.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to import models: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingModels = false;
        });
      }
    }
  }

  void _showModelDetails(ModelConfig model) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => _ModelDetailsSheet(
        model: model,
        isDefault: model.id == _selectedModelId,
        onSetDefault: () async {
          Navigator.of(context).pop();
          await _setDefaultModel(model.id);
        },
        onDelete: () async {
          Navigator.of(context).pop();
          await _deleteModel(model.id);
        },
      ),
    );
  }

  Future<void> _setDefaultModel(String id) async {
    await _modelService.setDefaultModel(id);
    if (!mounted) return;
    setState(() {
      _selectedModelId = id;
    });
  }

  Future<void> _deleteModel(String modelId) async {
    setState(() {
      _isLoadingModels = true;
    });

    try {
      await _modelService.deleteModel(modelId);
      await _loadModels(refreshRemote: false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Model deleted.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete model: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingModels = false;
        });
      }
    }
  }

  Widget _buildProviderStatus() {
    if (_isLoadingProviders) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_providers.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Text(
          'No providers configured yet. Visit API Keys to activate providers.',
          style: TextStyle(color: Colors.grey[600]),
        ),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _providers.map((provider) {
          final color = provider.isActive ? Colors.green : Colors.grey;
          final icon = provider.provider.icon;
          return Container(
            margin: const EdgeInsets.only(right: 12),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: color.withOpacity(0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: color),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      provider.displayName,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: color,
                      ),
                    ),
                    Text(
                      provider.isActive ? 'Active' : 'Inactive',
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildModelList() {
    if (_isLoadingModels) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_modelConfigs.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.smart_toy_outlined, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 12),
            Text(
              'No models imported yet',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.grey[700]),
            ),
            const SizedBox(height: 8),
            Text(
              'Activate a provider and add models to get started.',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 120),
      itemCount: _modelConfigs.length,
      itemBuilder: (context, index) {
        final model = _modelConfigs[index];
        final isDefault = model.id == _selectedModelId;
        return GestureDetector(
          onTap: () => _showModelDetails(model),
          child: Card(
            elevation: 0,
            margin: const EdgeInsets.symmetric(vertical: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(
                color: isDefault ? Colors.deepPurple : Colors.grey[200]!,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: model.provider.color.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(model.provider.icon, color: model.provider.color),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                model.name,
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                              ),
                            ),
                            if (isDefault)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.deepPurple,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Text('Default', style: TextStyle(color: Colors.white, fontSize: 12)),
                              ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '${model.provider.displayName} • ${model.model}',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                        if (model.metadata?['description'] != null) ...[
                          const SizedBox(height: 6),
                          Text(
                            model.metadata!['description'],
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(color: Colors.grey[700]),
                          ),
                        ],
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            OutlinedButton.icon(
                              onPressed: () => _showModelDetails(model),
                              icon: const Icon(Icons.info_outline),
                              label: const Text('Details'),
                            ),
                            const SizedBox(width: 12),
                            if (!isDefault)
                              OutlinedButton.icon(
                                onPressed: () => _setDefaultModel(model.id),
                                icon: const Icon(Icons.check),
                                label: const Text('Set Default'),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Model Settings'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddModelSheet,
        icon: const Icon(Icons.add),
        label: const Text('Add Model'),
      ),
      body: RefreshIndicator(
        onRefresh: _refreshAll,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              'Providers',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            _buildProviderStatus(),
            const SizedBox(height: 16),
            Text(
              'Models',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.65,
              child: _buildModelList(),
            ),
          ],
        ),
      ),
    );
  }
}

class _AddModelSheet extends StatefulWidget {
  final List<ProviderConnection> providers;
  final Future<void> Function(ProviderConnection provider, List<AvailableModelOption> selections) onImport;

  const _AddModelSheet({required this.providers, required this.onImport});

  @override
  State<_AddModelSheet> createState() => _AddModelSheetState();
}

class _AddModelSheetState extends State<_AddModelSheet> {
  final ModelService _modelService = ModelService();
  ProviderConnection? _selectedProvider;
  List<AvailableModelOption> _availableModels = [];
  final Set<String> _selectedModelIds = {};
  bool _isLoading = false;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    if (widget.providers.isNotEmpty) {
      _selectedProvider = widget.providers.first;
      _loadModels();
    }
  }

  Future<void> _loadModels() async {
    final provider = _selectedProvider;
    if (provider == null) return;

    setState(() {
      _isLoading = true;
      _availableModels = [];
      _selectedModelIds.clear();
    });

    try {
      final models = await _modelService.getProviderModels(
        provider: provider.provider,
        search: _searchQuery.isEmpty ? null : _searchQuery,
      );
      if (!mounted) return;
      setState(() {
        _availableModels = models;
      });
    } catch (e) {
      if (!mounted) return;
      final message = e is BackendApiException ? e.message : 'Failed to load models: $e';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _toggleSelection(String modelId) {
    setState(() {
      if (_selectedModelIds.contains(modelId)) {
        _selectedModelIds.remove(modelId);
      } else {
        _selectedModelIds.add(modelId);
      }
    });
  }

  Future<void> _submit() async {
    final provider = _selectedProvider;
    if (provider == null || _selectedModelIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select at least one model to import.')),
      );
      return;
    }

    final selections = _availableModels
        .where((model) => _selectedModelIds.contains(model.id))
        .toList();
    await widget.onImport(provider, selections);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            height: 4,
            width: 40,
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          Text(
            'Add Models',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<ProviderConnection>(
            value: _selectedProvider,
            decoration: const InputDecoration(labelText: 'Provider'),
            items: widget.providers
                .map(
                  (provider) => DropdownMenuItem(
                    value: provider,
                    child: Text(provider.displayName),
                  ),
                )
                .toList(),
            onChanged: (value) {
              setState(() {
                _selectedProvider = value;
              });
              _loadModels();
            },
          ),
          const SizedBox(height: 12),
          TextField(
            decoration: const InputDecoration(
              labelText: 'Search models',
              prefixIcon: Icon(Icons.search),
            ),
            onChanged: (value) {
              _searchQuery = value;
              _loadModels();
            },
          ),
          const SizedBox(height: 16),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(24),
              child: CircularProgressIndicator(),
            )
          else if (_availableModels.isEmpty)
            Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                'No models found for the selected provider.',
                style: TextStyle(color: Colors.grey[600]),
              ),
            )
          else
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.4,
              child: ListView.builder(
                itemCount: _availableModels.length,
                itemBuilder: (context, index) {
                  final model = _availableModels[index];
                  final selected = _selectedModelIds.contains(model.id);
                  return CheckboxListTile(
                    value: selected,
                    title: Text(model.name),
                    subtitle: model.description != null
                        ? Text(
                            model.description!,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          )
                        : null,
                    onChanged: (_) => _toggleSelection(model.id),
                  );
                },
              ),
            ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _selectedModelIds.isEmpty ? null : _submit,
              icon: const Icon(Icons.download),
              label: Text('Import ${_selectedModelIds.length} model(s)'),
            ),
          ),
        ],
      ),
    );
  }
}

class _ModelDetailsSheet extends StatelessWidget {
  final ModelConfig model;
  final bool isDefault;
  final VoidCallback onSetDefault;
  final VoidCallback onDelete;

  const _ModelDetailsSheet({
    required this.model,
    required this.isDefault,
    required this.onSetDefault,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 4,
            width: 40,
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          Row(
            children: [
              Icon(model.provider.icon, color: model.provider.color),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  model.name,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildInfoRow('Provider', model.provider.displayName),
          _buildInfoRow('Model ID', model.model),
          _buildInfoRow('Base URL', model.baseUrl),
          if (model.systemPrompt != null && model.systemPrompt!.isNotEmpty)
            _buildInfoRow('System Prompt', model.systemPrompt!),
          _buildInfoRow('Temperature', model.temperature.toString()),
          if (model.maxTokens != null)
            _buildInfoRow('Max Tokens', model.maxTokens.toString()),
          if (model.metadata != null && model.metadata!.isNotEmpty)
            _buildInfoRow('Metadata', model.metadata.toString()),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: isDefault ? null : onSetDefault,
                  icon: const Icon(Icons.check_circle),
                  label: Text(isDefault ? 'Default Model' : 'Set as Default'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('Delete'),
                  style: OutlinedButton.styleFrom(foregroundColor: Colors.redAccent),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}
