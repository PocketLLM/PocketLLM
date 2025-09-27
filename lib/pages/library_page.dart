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

class _LibraryPageState extends State<LibraryPage> with TickerProviderStateMixin {
  final ModelService _modelService = ModelService();
  final RemoteModelService _remoteModelService = RemoteModelService();

  late TabController _tabController;
  bool _loadingDownloaded = false;
  bool _loadingAvailable = false;
  List<ModelConfig> _downloadedModels = [];
  List<AvailableModelOption> _availableModels = [];
  String? _availableError;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _refreshAll();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _refreshAll() {
    _fetchDownloadedModels();
    _loadAvailableModels();
  }

  Future<void> _fetchDownloadedModels() async {
    setState(() {
      _loadingDownloaded = true;
    });
    try {
      final models = await _modelService.getSavedModels();
      if (!mounted) return;
      setState(() {
        _downloadedModels = models;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _downloadedModels = [];
      });
      _showSnack('Failed to load saved models: $e', Colors.red);
    } finally {
      if (!mounted) return;
      setState(() {
        _loadingDownloaded = false;
      });
    }
  }

  Future<void> _loadAvailableModels() async {
    setState(() {
      _loadingAvailable = true;
      _availableError = null;
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
        _availableError = e.message;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _availableModels = [];
        _availableError = e.toString();
      });
    } finally {
      if (!mounted) return;
      setState(() {
        _loadingAvailable = false;
      });
    }
  }

  void _showSnack(String message, Color backgroundColor) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: backgroundColor),
    );
  }

  List<AvailableModelOption> get _filteredAvailableModels {
    final query = _searchQuery.trim().toLowerCase();
    if (query.isEmpty) {
      return List<AvailableModelOption>.from(_availableModels);
    }
    return _availableModels.where((model) {
      final description = model.description ?? '';
      return model.name.toLowerCase().contains(query) ||
          model.id.toLowerCase().contains(query) ||
          description.toLowerCase().contains(query) ||
          model.provider.toLowerCase().contains(query);
    }).toList();
  }

  Map<ModelProvider, List<AvailableModelOption>> _groupAvailableModels(
    List<AvailableModelOption> models,
  ) {
    final grouped = <ModelProvider, List<AvailableModelOption>>{};
    for (final option in models) {
      final provider = ModelProviderExtension.fromBackend(option.provider);
      grouped.putIfAbsent(provider, () => []).add(option);
    }
    return grouped;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.grey[50],
        elevation: 0,
        title: const Text(
          'Model Library',
          style: TextStyle(
            color: Colors.black,
            fontSize: 32,
            fontWeight: FontWeight.bold,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFF8B5CF6),
          unselectedLabelColor: Colors.grey[600],
          indicatorColor: const Color(0xFF8B5CF6),
          tabs: const [
            Tab(text: 'Imported'),
            Tab(text: 'Available'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.black),
            onPressed: _refreshAll,
            tooltip: 'Refresh models',
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildDownloadedTab(),
          _buildAvailableTab(),
        ],
      ),
    );
  }

  Widget _buildDownloadedTab() {
    if (_loadingDownloaded) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_downloadedModels.isEmpty) {
      return _buildEmptyState(
        icon: Icons.download_done,
        title: 'No models imported yet',
        message: 'Import models from the Available tab once you add provider API keys.',
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _downloadedModels.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final model = _downloadedModels[index];
        return Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.grey.shade200),
          ),
          child: ListTile(
            leading: _buildProviderAvatar(model.provider),
            title: Text(
              model.name,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Text(model.model),
            trailing: Text(
              model.provider.displayName,
              style: TextStyle(color: Colors.grey[600]),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAvailableTab() {
    if (_loadingAvailable) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_availableError != null) {
      return _buildErrorState(_availableError!);
    }

    final filtered = _filteredAvailableModels;
    if (filtered.isEmpty) {
      return _buildEmptyState(
        icon: Icons.travel_explore,
        title: 'No models found',
        message: 'Adjust your search or configure provider API keys in Settings.',
      );
    }

    final grouped = _groupAvailableModels(filtered);
    final providers = grouped.keys.toList()
      ..sort((a, b) => a.displayName.compareTo(b.displayName));

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      children: [
        _buildSearchBar(),
        const SizedBox(height: 16),
        for (final provider in providers) ...[
          _buildProviderHeader(provider),
          const SizedBox(height: 8),
          ...grouped[provider]!
              .map((model) => _buildAvailableModelCard(provider, model))
              .toList(),
          const SizedBox(height: 24),
        ],
      ],
    );
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: TextField(
        decoration: const InputDecoration(
          prefixIcon: Icon(Icons.search),
          hintText: 'Search models by name or provider',
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        onChanged: (value) => setState(() => _searchQuery = value),
      ),
    );
  }

  Widget _buildProviderHeader(ModelProvider provider) {
    return Row(
      children: [
        _buildProviderAvatar(provider),
        const SizedBox(width: 12),
        Text(
          provider.displayName,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildAvailableModelCard(ModelProvider provider, AvailableModelOption model) {
    final description = model.description?.trim();
    final metadata = model.metadata ?? const {};
    final contextWindow = metadata['context_window'] ?? metadata['contextLength'];
    final pricing = metadata['pricing'];

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
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
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
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
                ElevatedButton.icon(
                  onPressed: () => _importModel(provider, model),
                  icon: const Icon(Icons.download, size: 18),
                  label: const Text('Import'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF8B5CF6),
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
            if (description != null && description.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                description,
                style: TextStyle(color: Colors.grey[700]),
              ),
            ],
            if (contextWindow != null || pricing != null) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 8,
                children: [
                  if (contextWindow != null)
                    _buildMetadataChip(
                      icon: Icons.unfold_more,
                      label: 'Context: $contextWindow tokens',
                    ),
                  if (pricing is Map && pricing.isNotEmpty)
                    _buildMetadataChip(
                      icon: Icons.attach_money,
                      label: _formatPricing(pricing),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMetadataChip({required IconData icon, required String label}) {
    return Chip(
      avatar: Icon(icon, size: 18, color: const Color(0xFF8B5CF6)),
      backgroundColor: const Color(0xFFEDE9FE),
      label: Text(
        label,
        style: const TextStyle(color: Color(0xFF5B21B6)),
      ),
    );
  }

  String _formatPricing(Map<dynamic, dynamic> pricing) {
    final prompt = pricing['prompt'] ?? pricing['input'];
    final completion = pricing['completion'] ?? pricing['output'];
    if (prompt == null && completion == null) {
      return 'Pricing available';
    }
    if (prompt != null && completion != null) {
      return 'Prompt $prompt / Completion $completion';
    }
    return 'Price ${prompt ?? completion}';
  }

  Widget _buildErrorState(String message) {
    return _buildEmptyState(
      icon: Icons.lock_outline,
      title: 'Unable to fetch models',
      message: message,
      action: TextButton(
        onPressed: _loadAvailableModels,
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

  Widget _buildProviderAvatar(ModelProvider provider) {
    final iconData = _resolveProviderIcon(provider);
    final color = _resolveProviderColor(provider);
    return CircleAvatar(
      backgroundColor: color.withOpacity(0.15),
      child: Icon(iconData, color: color),
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
      default:
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
      default:
        return const Color(0xFF8B5CF6);
    }
  }

  Future<void> _importModel(ModelProvider provider, AvailableModelOption option) async {
    try {
      await _modelService.importModelsFromProvider(
        provider: provider,
        selections: [option],
      );
      await _fetchDownloadedModels();
      _showSnack('${option.name} imported successfully', Colors.green);
    } on BackendApiException catch (e) {
      _showSnack(e.message, Colors.red);
    } catch (e) {
      _showSnack('Failed to import ${option.name}: $e', Colors.red);
    }
  }
}
