import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

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
  AvailableModelsResponse? _catalogueResponse;
  String? _catalogueMessage;
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
      final response = await _remoteModelService.getAvailableModels();
      final trimmedMessage = response.message?.trim();
      if (!mounted) return;
      setState(() {
        _catalogueResponse = response;
        _availableModels = response.models;
        _catalogueMessage =
            (trimmedMessage == null || trimmedMessage.isEmpty) ? null : trimmedMessage;
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
    Widget child;

    if (_isLoading && _availableModels.isEmpty) {
      child = KeyedSubtree(key: const ValueKey('loading'), child: _buildLoadingState());
    } else if (_error != null && _availableModels.isEmpty) {
      child = KeyedSubtree(key: const ValueKey('error'), child: _buildErrorState(_error!));
    } else {
      final filtered = _filteredModels;
      if (!_isLoading && filtered.isEmpty) {
        final emptyMessage = _searchQuery.isEmpty
            ? (_catalogueMessage ?? 'Adjust your search or try refreshing the catalogue.')
            : 'No models matched your search. Try adjusting your filters.';
        child = KeyedSubtree(
          key: const ValueKey('empty'),
          child: RefreshIndicator(
            onRefresh: _loadModels,
            color: const Color(0xFF6D28D9),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 48),
              children: [
                _buildSearchBar(),
                const SizedBox(height: 24),
                Align(
                  alignment: Alignment.topCenter,
                  child: _buildEmptyState(
                    icon: Icons.travel_explore,
                    title: 'No models found',
                    message: emptyMessage,
                  ),
                ),
              ],
            ),
          ),
        );
      } else {
        final grouped = _groupModels(filtered);
        final providers = grouped.keys.toList()
          ..sort((a, b) => a.displayName.compareTo(b.displayName));
        final notice = _buildCatalogueBanner();
        final summary = _buildProviderSummary();

        child = KeyedSubtree(
          key: ValueKey('content-${filtered.length}'),
          child: RefreshIndicator(
            onRefresh: _loadModels,
            color: const Color(0xFF6D28D9),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 48),
              children: [
                _buildSearchBar(),
                const SizedBox(height: 20),
                if (summary != null) ...[
                  summary,
                  const SizedBox(height: 20),
                ],
                if (notice != null) ...[
                  notice,
                  const SizedBox(height: 16),
                ],
                for (var index = 0; index < providers.length; index++) ...
                    _buildProviderSection(
                  providers[index],
                  grouped[providers[index]]!,
                  index == providers.length - 1,
                ),
                if (_isLoading)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: CircularProgressIndicator(),
                    ),
                  ),
              ],
            ),
          ),
        );
      }
    }

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 250),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      child: child,
    );
  }

  Widget _buildLoadingState() {
    return RefreshIndicator(
      onRefresh: _loadModels,
      color: const Color(0xFF6D28D9),
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(24, 32, 24, 48),
        itemCount: 4,
        itemBuilder: (context, index) {
          return Padding(
            padding: EdgeInsets.only(bottom: index == 3 ? 0 : 20),
            child: _buildLoadingPlaceholderCard(),
          );
        },
      ),
    );
  }

  Widget _buildLoadingPlaceholderCard() {
    return Container(
      height: 140,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.grey.shade200,
            Colors.grey.shade100,
            Colors.grey.shade200,
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outline.withOpacity(0.15)),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withOpacity(0.08),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        onChanged: _onSearchChanged,
        style: TextStyle(color: colorScheme.onSurface),
        decoration: InputDecoration(
          prefixIcon: Icon(Icons.search, color: colorScheme.onSurface.withOpacity(0.6)),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    _onSearchChanged('');
                  },
                  color: colorScheme.onSurface.withOpacity(0.6),
                )
              : null,
          hintText: 'Search by model, provider, or capability',
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          filled: false,
        ),
      ),
    );
  }

  Widget? _buildCatalogueBanner() {
    final message = _catalogueMessage?.trim();
    if (message == null || message.isEmpty) {
      return null;
    }

    final colorScheme = Theme.of(context).colorScheme;
    final isFallback = _catalogueResponse?.usingFallback ?? false;
    final accent = isFallback ? const Color(0xFF6D28D9) : colorScheme.primary;
    final background = isFallback
        ? const Color(0xFFEDE9FE)
        : colorScheme.surface.withOpacity(0.95);
    final border = isFallback
        ? const Color(0xFFDDD6FE)
        : colorScheme.outline.withOpacity(0.35);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(isFallback ? Icons.auto_awesome : Icons.info_outline, color: accent),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: colorScheme.onSurface.withOpacity(0.85),
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget? _buildProviderSummary() {
    final response = _catalogueResponse;
    if (response == null) {
      return null;
    }

    final configured = response.configuredProviders.toSet().toList();
    final missing = response.missingProviders.toSet().toList();

    if (configured.isEmpty && missing.isEmpty) {
      return null;
    }

    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (configured.isNotEmpty) ...[
            Text(
              'Connected providers',
              style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ) ??
                  const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: configured
                  .map((providerId) => _buildProviderStatusChip(providerId, configured: true))
                  .toList(),
            ),
          ],
          if (configured.isNotEmpty && missing.isNotEmpty)
            const SizedBox(height: 20),
          if (missing.isNotEmpty) ...[
            Text(
              'Available to connect',
              style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ) ??
                  const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: missing
                  .map((providerId) => _buildProviderStatusChip(providerId, configured: false))
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildProviderStatusChip(String providerId, {required bool configured}) {
    final provider = ModelProviderExtension.fromBackend(providerId);
    final label = provider.displayName;
    final color = configured ? const Color(0xFF4C1D95) : Colors.grey[700]!;
    final background = configured ? const Color(0xFFEDE9FE) : Colors.grey.shade200;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 20,
            height: 20,
            child: FittedBox(
              fit: BoxFit.contain,
              child: _buildProviderLogo(provider, size: 20, fallbackColor: color),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (!configured) ...[
            const SizedBox(width: 8),
            Icon(Icons.lock_open, size: 16, color: color.withOpacity(0.8)),
          ],
        ],
      ),
    );
  }

  Widget _buildProviderHeader(ModelProvider provider, int modelCount) {
    return Row(
      children: [
        _buildProviderAvatar(provider, size: 48),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                provider.displayName,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '$modelCount model${modelCount == 1 ? '' : 's'} available',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  List<Widget> _buildProviderSection(
    ModelProvider provider,
    List<AvailableModelOption> models,
    bool isLast,
  ) {
    return [
      _buildProviderHeader(provider, models.length),
      const SizedBox(height: 12),
      ...models
          .map((model) => Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: _buildModelCard(provider, model),
              ))
          .toList(),
      if (!isLast) const SizedBox(height: 28),
    ];
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

    final accentColor = _resolveProviderColor(provider);
    final metadataChips = <Widget>[];

    if (contextWindow != null) {
      metadataChips.add(
        _buildMetadataChip(
          icon: Icons.unfold_more,
          label: 'Context ${contextWindow.toString()} tokens',
          tint: accentColor,
        ),
      );
    }
    if (maxOutput != null) {
      metadataChips.add(
        _buildMetadataChip(
          icon: Icons.vertical_align_bottom,
          label: 'Max output ${maxOutput.toString()} tokens',
          tint: accentColor,
        ),
      );
    }
    if (capabilities.isNotEmpty) {
      metadataChips.add(
        _buildMetadataChip(
          icon: Icons.extension,
          label: capabilities.take(3).join(' • '),
          tint: accentColor,
        ),
      );
    }
    if (inputModalities.isNotEmpty) {
      metadataChips.add(
        _buildMetadataChip(
          icon: Icons.input,
          label: 'Input: ${inputModalities.join(', ')}',
          tint: accentColor,
        ),
      );
    }
    if (outputModalities.isNotEmpty) {
      metadataChips.add(
        _buildMetadataChip(
          icon: Icons.output,
          label: 'Output: ${outputModalities.join(', ')}',
          tint: accentColor,
        ),
      );
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: () => _showModelDetails(model),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isImporting ? accentColor.withOpacity(0.4) : Colors.grey.shade200,
              width: 1.4,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isImporting ? 0.08 : 0.05),
                blurRadius: isImporting ? 18 : 12,
                offset: const Offset(0, 8),
              ),
            ],
          ),
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
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          model.id,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  _buildImportButton(model, isImporting, accentColor),
                ],
              ),
              if (description.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  description,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: Colors.grey[700], height: 1.4),
                ),
              ],
              if (metadataChips.isNotEmpty) ...[
                const SizedBox(height: 18),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: metadataChips,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImportButton(
    AvailableModelOption model,
    bool isImporting,
    Color accentColor,
  ) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 132),
      child: FilledButton.icon(
        onPressed: isImporting ? null : () => _importModel(model),
        style: FilledButton.styleFrom(
          backgroundColor: accentColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        icon: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          child: isImporting
              ? const SizedBox(
                  key: ValueKey('spinner'),
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : const Icon(Icons.download, key: ValueKey('icon'), size: 20),
        ),
        label: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: Text(
            isImporting ? 'Importing…' : 'Import',
            key: ValueKey<bool>(isImporting),
            style: const TextStyle(fontWeight: FontWeight.w600),
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
                                tint: _resolveProviderColor(provider),
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

  Widget _buildMetadataChip({
    required IconData icon,
    required String label,
    Color? tint,
  }) {
    final color = tint ?? const Color(0xFF6D28D9);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
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
    return RefreshIndicator(
      onRefresh: _loadModels,
      color: const Color(0xFF6D28D9),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(24, 80, 24, 48),
        children: [
          Align(
            alignment: Alignment.topCenter,
            child: _buildEmptyState(
              icon: Icons.lock_outline,
              title: 'Unable to fetch models',
              message: message,
              action: TextButton(
                onPressed: _loadModels,
                child: const Text('Try again'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String message,
    Widget? action,
  }) {
    final theme = Theme.of(context);
    return Container(
      constraints: const BoxConstraints(maxWidth: 420),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFFEDE9FE),
            ),
            child: Icon(icon, size: 32, color: const Color(0xFF6D28D9)),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ) ??
                const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                  height: 1.5,
                ) ??
                TextStyle(color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
          if (action != null) ...[
            const SizedBox(height: 20),
            action,
          ],
        ],
      ),
    );
  }

  Widget _buildProviderAvatar(ModelProvider provider, {double size = 44}) {
    final color = _resolveProviderColor(provider);
    final asset = provider.brandAsset;
    final logoSize = size * 0.6;

    Widget child;
    if (asset != null) {
      child = ClipOval(
        child: SizedBox(
          width: logoSize,
          height: logoSize,
          child: FittedBox(
            fit: BoxFit.contain,
            child: _buildBrandAsset(asset, logoSize, color),
          ),
        ),
      );
    } else {
      child = Icon(
        _resolveProviderIcon(provider),
        color: color,
        size: logoSize,
      );
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withOpacity(0.12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      alignment: Alignment.center,
      child: child,
    );
  }

  Widget _buildProviderLogo(
    ModelProvider provider, {
    required double size,
    Color? fallbackColor,
  }) {
    final color = fallbackColor ?? _resolveProviderColor(provider);
    final asset = provider.brandAsset;
    if (asset != null) {
      return _buildBrandAsset(asset, size, color);
    }
    return Icon(
      _resolveProviderIcon(provider),
      size: size,
      color: color,
    );
  }

  Widget _buildBrandAsset(String asset, double size, Color fallbackColor) {
    final lower = asset.toLowerCase();
    if (lower.endsWith('.svg')) {
      return SvgPicture.asset(
        asset,
        width: size,
        height: size,
        fit: BoxFit.contain,
        placeholderBuilder: (context) => Icon(
          Icons.image_outlined,
          size: size,
          color: fallbackColor,
        ),
      );
    }

    return Image.asset(
      asset,
      width: size,
      height: size,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.high,
      errorBuilder: (context, error, stackTrace) => Icon(
        Icons.image_outlined,
        size: size,
        color: fallbackColor,
      ),
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
