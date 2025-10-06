import 'package:flutter/material.dart';

import '../component/models.dart';
import '../services/backend_api_service.dart';
import '../services/model_service.dart';
import '../services/remote_model_service.dart';

class LibraryPage extends StatefulWidget {
  const LibraryPage({Key? key}) : super(key: key);

  @override
  State<LibraryPage> createState() => _LibraryPageState();
}

class _LibraryPageState extends State<LibraryPage> {
  final ModelService _modelService = ModelService();
  final RemoteModelService _remoteModelService = RemoteModelService();
  final TextEditingController _searchController = TextEditingController();

  bool _isLoading = false;
  String? _error;
  List<AvailableModelOption> _availableModels = [];
  String _searchQuery = '';
  final Set<String> _importingModelIds = <String>{};

  @override
  void initState() {
    super.initState();
    _loadModels();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadModels() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final models = await _remoteModelService.getAvailableModels();
      if (!mounted) return;
      setState(() {
        _availableModels = models;
      });
    } on BackendApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _availableModels = [];
        _error = e.message;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _availableModels = [];
        _error = e.toString();
      });
    } finally {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _onSearchChanged(String value) {
    setState(() {
      _searchQuery = value;
    });
  }

  List<AvailableModelOption> get _filteredModels {
    final query = _searchQuery.trim().toLowerCase();
    if (query.isEmpty) {
      return List<AvailableModelOption>.from(_availableModels);
    }

    return _availableModels.where((model) {
      final provider = ModelProviderExtension.fromBackend(model.provider);
      final description = _resolveDescription(model).toLowerCase();
      return model.name.toLowerCase().contains(query) ||
          model.id.toLowerCase().contains(query) ||
          provider.displayName.toLowerCase().contains(query) ||
          description.contains(query);
    }).toList();
  }

  Map<ModelProvider, List<AvailableModelOption>> _groupModels(
    List<AvailableModelOption> models,
  ) {
    final grouped = <ModelProvider, List<AvailableModelOption>>{};
    for (final option in models) {
      final provider = ModelProviderExtension.fromBackend(option.provider);
      grouped.putIfAbsent(provider, () => []).add(option);
    }
    return grouped;
  }

  void _showSnack(String message, Color backgroundColor) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: backgroundColor),
    );
  }

  Future<bool> _importModel(
    AvailableModelOption option, {
    BuildContext? popContext,
  }) async {
    final provider = ModelProviderExtension.fromBackend(option.provider);

    if (mounted) {
      setState(() {
        _importingModelIds.add(option.id);
      });
    }

    var succeeded = false;
    try {
      await _modelService.importModelsFromProvider(
        provider: provider,
        selections: [option],
      );
      succeeded = true;
      if (mounted) {
        _showSnack('${option.name} imported successfully', Colors.green);
      }
    } on BackendApiException catch (e) {
      if (mounted) {
        _showSnack(e.message, Colors.red);
      }
    } catch (e) {
      if (mounted) {
        _showSnack('Failed to import ${option.name}: $e', Colors.red);
      }
    } finally {
      if (mounted) {
        setState(() {
          _importingModelIds.remove(option.id);
        });
      }
    }

    if (succeeded && popContext != null && Navigator.of(popContext).canPop()) {
      Navigator.of(popContext).pop();
    }

    return succeeded;
  }

  void _showModelDetails(AvailableModelOption model) {
    final provider = ModelProviderExtension.fromBackend(model.provider);

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        var localImporting = _importingModelIds.contains(model.id);
        return StatefulBuilder(
          builder: (context, setModalState) {
            Future<void> handleImport() async {
              if (localImporting) return;
              setModalState(() {
                localImporting = true;
              });
              final success = await _importModel(
                model,
                popContext: sheetContext,
              );
              if (!success && mounted) {
                setModalState(() {
                  localImporting = false;
                });
              }
            }

            return _buildModelDetailsSheet(
              sheetContext: sheetContext,
              provider: provider,
              model: model,
              isImporting: localImporting,
              onImport: handleImport,
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.grey[50],
        elevation: 0,
        titleSpacing: 24,
        title: const Text(
          'Model Library',
          style: TextStyle(
            color: Colors.black,
            fontSize: 30,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.black),
            tooltip: 'Refresh models',
            onPressed: _loadModels,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading && _availableModels.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null && _availableModels.isEmpty) {
      return _buildErrorState(_error!);
    }

    final filtered = _filteredModels;

    if (!_isLoading && filtered.isEmpty) {
      return RefreshIndicator(
        onRefresh: _loadModels,
        color: const Color(0xFF6D28D9),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
          children: [
            _buildSearchBar(),
            const SizedBox(height: 24),
            _buildEmptyState(
              icon: Icons.travel_explore,
              title: 'No models found',
              message: 'Adjust your search or try refreshing the catalogue.',
            ),
          ],
        ),
      );
    }

    final grouped = _groupModels(filtered);
    final providers = grouped.keys.toList()
      ..sort((a, b) => a.displayName.compareTo(b.displayName));

    return RefreshIndicator(
      onRefresh: _loadModels,
      color: const Color(0xFF6D28D9),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        children: [
          _buildSearchBar(),
          const SizedBox(height: 24),
          for (final provider in providers) ...[
            _buildProviderHeader(provider),
            const SizedBox(height: 12),
            ...grouped[provider]!
                .map((model) => Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: _buildModelCard(provider, model),
                    ))
                .toList(),
            const SizedBox(height: 12),
          ],
          if (_isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        onChanged: _onSearchChanged,
        decoration: InputDecoration(
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    _onSearchChanged('');
                  },
                )
              : null,
          hintText: 'Search by model, provider, or capability',
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        ),
      ),
    );
  }

  Widget _buildProviderHeader(ModelProvider provider) {
    return Row(
      children: [
        _buildProviderAvatar(provider, size: 44),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              provider.displayName,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              'Models from ${provider.displayName}',
              style: TextStyle(
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildModelCard(ModelProvider provider, AvailableModelOption model) {
    final metadata = _normalizeMetadata(model.metadata);
    final description = _resolveDescription(model);
    final contextWindow = metadata['context_window'] ?? metadata['contextWindow'] ?? metadata['contextLength'];
    final maxOutput = metadata['max_output_tokens'] ?? metadata['maxTokens'];
    final capabilities = _stringList(metadata['capabilities']);
    final architecture = metadata['architecture'];
    final inputModalities = architecture is Map ? _stringList(architecture['input_modalities']) : <String>[];
    final outputModalities = architecture is Map ? _stringList(architecture['output_modalities']) : <String>[];
    final isImporting = _importingModelIds.contains(model.id);

    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () => _showModelDetails(model),
      child: Card(
        elevation: 0,
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: Colors.grey.shade200),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          model.name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          model.id,
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                  FilledButton.icon(
                    onPressed: isImporting ? null : () => _importModel(model),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF6D28D9),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: isImporting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.download, size: 20),
                    label: Text(isImporting ? 'Importing' : 'Import'),
                  ),
                ],
              ),
              if (description.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  description,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: Colors.grey[700]),
                ),
              ],
              const SizedBox(height: 16),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  _buildMetadataChip(
                    icon: Icons.business,
                    label: provider.displayName,
                  ),
                  if (contextWindow != null)
                    _buildMetadataChip(
                      icon: Icons.unfold_more,
                      label: 'Context ${contextWindow.toString()} tokens',
                    ),
                  if (maxOutput != null)
                    _buildMetadataChip(
                      icon: Icons.vertical_align_bottom,
                      label: 'Max output ${maxOutput.toString()} tokens',
                    ),
                  if (capabilities.isNotEmpty)
                    _buildMetadataChip(
                      icon: Icons.extension,
                      label: capabilities.take(2).join(' • '),
                    ),
                  if (inputModalities.isNotEmpty)
                    _buildMetadataChip(
                      icon: Icons.input,
                      label: 'Input: ${inputModalities.join(', ')}',
                    ),
                  if (outputModalities.isNotEmpty)
                    _buildMetadataChip(
                      icon: Icons.output,
                      label: 'Output: ${outputModalities.join(', ')}',
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModelDetailsSheet({
    required BuildContext sheetContext,
    required ModelProvider provider,
    required AvailableModelOption model,
    required bool isImporting,
    required Future<void> Function() onImport,
  }) {
    final metadata = _normalizeMetadata(model.metadata);
    final description = _resolveDescription(model);
    final pricing = metadata['pricing'];
    final contextWindow = metadata['context_window'] ?? metadata['contextWindow'] ?? metadata['contextLength'];
    final maxOutput = metadata['max_output_tokens'] ?? metadata['maxTokens'];
    final capabilities = _stringList(metadata['capabilities']);
    final tags = _stringList(metadata['tags']);
    final architecture = metadata['architecture'];
    final inputModalities = architecture is Map ? _stringList(architecture['input_modalities']) : <String>[];
    final outputModalities = architecture is Map ? _stringList(architecture['output_modalities']) : <String>[];

    final bottomPadding = MediaQuery.of(sheetContext).padding.bottom;

    return FractionallySizedBox(
      heightFactor: 0.92,
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 48,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildProviderAvatar(provider, size: 56),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                model.name,
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                model.id,
                                style: TextStyle(color: Colors.grey[600]),
                              ),
                              const SizedBox(height: 8),
                              _buildMetadataChip(
                                icon: Icons.business,
                                label: provider.displayName,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    if (description.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Text(
                        description,
                        style: TextStyle(
                          color: Colors.grey[800],
                          height: 1.5,
                        ),
                      ),
                    ],
                    const SizedBox(height: 20),
                    _buildSectionTitle('Model specifications'),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        if (contextWindow != null)
                          _buildInfoTile(
                            icon: Icons.unfold_more,
                            label: 'Context window',
                            value: '$contextWindow tokens',
                          ),
                        if (maxOutput != null)
                          _buildInfoTile(
                            icon: Icons.vertical_align_bottom,
                            label: 'Max output tokens',
                            value: '$maxOutput tokens',
                          ),
                        if (capabilities.isNotEmpty)
                          _buildInfoTile(
                            icon: Icons.extension,
                            label: 'Capabilities',
                            value: capabilities.join(', '),
                          ),
                        if (inputModalities.isNotEmpty)
                          _buildInfoTile(
                            icon: Icons.input,
                            label: 'Input modalities',
                            value: inputModalities.join(', '),
                          ),
                        if (outputModalities.isNotEmpty)
                          _buildInfoTile(
                            icon: Icons.output,
                            label: 'Output modalities',
                            value: outputModalities.join(', '),
                          ),
                        if (tags.isNotEmpty)
                          _buildInfoTile(
                            icon: Icons.local_offer,
                            label: 'Tags',
                            value: tags.join(', '),
                          ),
                      ],
                    ),
                    if (pricing is Map && pricing.isNotEmpty) ...[
                      const SizedBox(height: 24),
                      _buildSectionTitle('Pricing'),
                      const SizedBox(height: 12),
                      _buildPricingTable(pricing),
                    ],
                  ],
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(24, 12, 24, 24 + bottomPadding),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: isImporting ? null : onImport,
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF6D28D9),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  icon: isImporting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.download),
                  label: Text(isImporting ? 'Importing…' : 'Import model'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    final theme = Theme.of(context);
    final defaultStyle = const TextStyle(
      fontSize: 18,
      fontWeight: FontWeight.w600,
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(
        title,
        style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ) ??
            defaultStyle,
      ),
    );
  }

  Widget _buildInfoTile({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      width: 220,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: const Color(0xFF6D28D9)),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(color: Colors.grey[700]),
          ),
        ],
      ),
    );
  }

  Widget _buildPricingTable(Map<dynamic, dynamic> pricing) {
    final entries = pricing.entries
        .map((entry) => MapEntry(entry.key.toString(), entry.value))
        .where((entry) => entry.value != null && entry.value.toString().isNotEmpty)
        .toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          for (var i = 0; i < entries.length; i++)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: BoxDecoration(
                border: i == entries.length - 1
                    ? null
                    : Border(
                        bottom: BorderSide(color: Colors.grey.shade200),
                      ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _humanizeKey(entries[i].key),
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                  Text(
                    entries[i].value.toString(),
                    style: TextStyle(color: Colors.grey[700]),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  String _humanizeKey(String key) {
    final normalized = key.replaceAll('_', ' ').replaceAll('-', ' ');
    return normalized.isEmpty
        ? key
        : normalized[0].toUpperCase() + normalized.substring(1);
  }

  Widget _buildMetadataChip({required IconData icon, required String label}) {
    return Chip(
      avatar: Icon(icon, size: 18, color: const Color(0xFF6D28D9)),
      backgroundColor: const Color(0xFFEDE9FE),
      label: Text(
        label,
        style: const TextStyle(color: Color(0xFF4C1D95), fontWeight: FontWeight.w600),
      ),
    );
  }

  Map<String, dynamic> _normalizeMetadata(Map<String, dynamic>? raw) {
    if (raw == null) {
      return <String, dynamic>{};
    }
    return raw.map((key, value) => MapEntry(key.toString(), value));
  }

  String _resolveDescription(AvailableModelOption model) {
    final metadata = _normalizeMetadata(model.metadata);
    final description = metadata['description'] ?? model.description ?? '';
    return description.toString().trim();
  }

  List<String> _stringList(dynamic value) {
    if (value is List) {
      return value.map((entry) => entry.toString().trim()).where((entry) => entry.isNotEmpty).toList();
    }
    if (value is String) {
      return value
          .split(',')
          .map((entry) => entry.trim())
          .where((entry) => entry.isNotEmpty)
          .toList();
    }
    return <String>[];
  }

  Widget _buildErrorState(String message) {
    return _buildEmptyState(
      icon: Icons.lock_outline,
      title: 'Unable to fetch models',
      message: message,
      action: TextButton(
        onPressed: _loadModels,
        child: const Text('Try again'),
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String message,
    Widget? action,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: Colors.grey[500]),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: TextStyle(color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            if (action != null) ...[
              const SizedBox(height: 16),
              action,
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildProviderAvatar(ModelProvider provider, {double size = 44}) {
    final iconData = _resolveProviderIcon(provider);
    final color = _resolveProviderColor(provider);
    return CircleAvatar(
      radius: size / 2,
      backgroundColor: color.withOpacity(0.15),
      child: Icon(iconData, color: color, size: size / 2),
    );
  }

  IconData _resolveProviderIcon(ModelProvider provider) {
    switch (provider) {
      case ModelProvider.openAI:
        return Icons.auto_awesome;
      case ModelProvider.groq:
        return Icons.flash_on;
      case ModelProvider.openRouter:
        return Icons.route;
      case ModelProvider.imageRouter:
        return Icons.image;
      case ModelProvider.anthropic:
        return Icons.psychology;
      case ModelProvider.googleAI:
        return Icons.cloud;
      case ModelProvider.mistral:
        return Icons.waves;
      case ModelProvider.deepseek:
        return Icons.troubleshoot;
      case ModelProvider.lmStudio:
        return Icons.science;
      case ModelProvider.ollama:
        return Icons.terminal;
      case ModelProvider.pocketLLM:
        return Icons.smart_toy;
    }
  }

  Color _resolveProviderColor(ModelProvider provider) {
    switch (provider) {
      case ModelProvider.openAI:
        return const Color(0xFF10A37F);
      case ModelProvider.groq:
        return Colors.deepOrange;
      case ModelProvider.openRouter:
        return const Color(0xFF6B21A8);
      case ModelProvider.imageRouter:
        return Colors.orangeAccent;
      case ModelProvider.anthropic:
        return const Color(0xFF9333EA);
      case ModelProvider.googleAI:
        return const Color(0xFF1A73E8);
      case ModelProvider.mistral:
        return Colors.blueGrey;
      case ModelProvider.deepseek:
        return Colors.teal;
      case ModelProvider.lmStudio:
        return Colors.blue;
      case ModelProvider.ollama:
        return Colors.amber;
      case ModelProvider.pocketLLM:
        return const Color(0xFF8B5CF6);
    }
  }
}
