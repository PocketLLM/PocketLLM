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

enum SortOption {
  newest,
  topWeekly,
  pricingLowToHigh,
  pricingHighToLow,
  contextHighToLow,
  throughputHighToLow,
  latencyLowToHigh,
}

extension SortOptionExtension on SortOption {
  String get displayName {
    switch (this) {
      case SortOption.newest:
        return 'Newest';
      case SortOption.topWeekly:
        return 'Top Weekly';
      case SortOption.pricingLowToHigh:
        return 'Pricing: Low to High';
      case SortOption.pricingHighToLow:
        return 'Pricing: High to Low';
      case SortOption.contextHighToLow:
        return 'Context: High to Low';
      case SortOption.throughputHighToLow:
        return 'Throughput: High to Low';
      case SortOption.latencyLowToHigh:
        return 'Latency: Low to High';
    }
  }
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
  String? _activeFilter;
  ModelProvider? _providerFilter;
  final Set<String> _importingModelIds = <String>{};
  SortOption _currentSort = SortOption.newest;

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
      if (_activeFilter != null && _activeFilter != value) {
        _activeFilter = null;
      }
    });
  }

  void _clearSearchFilters() {
    if (_searchQuery.isEmpty && _activeFilter == null) {
      return;
    }

    _searchController.clear();
    _onSearchChanged('');
  }

  void _onFilterSelected(String filter) {
    if (_activeFilter == filter) {
      _clearSearchFilters();
      return;
    }

    setState(() {
      _activeFilter = filter;
    });
    _searchController.value = TextEditingValue(
      text: filter,
      selection: TextSelection.collapsed(offset: filter.length),
    );
    _onSearchChanged(filter);
  }

  void _clearProviderFilter() {
    if (_providerFilter == null) {
      return;
    }

    setState(() {
      _providerFilter = null;
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
      final metadataTerms = _metadataSearchTerms(model);
      return model.name.toLowerCase().contains(query) ||
          model.id.toLowerCase().contains(query) ||
          provider.displayName.toLowerCase().contains(query) ||
          description.contains(query) ||
          metadataTerms.any((term) => term.contains(query));
    }).toList();
  }

  List<String> get _discoveryTags {
    final ordered = <String, String>{};

    for (final model in _availableModels) {
      final metadata = _normalizeMetadata(model.metadata);
      final rawTags = <String>[]
        ..addAll(_stringList(metadata['capabilities']))
        ..addAll(_stringList(metadata['tags']));

      for (final entry in rawTags) {
        if (entry.isEmpty) continue;
        ordered.putIfAbsent(entry.toLowerCase(), () => _formatTag(entry));
      }
    }

    final tags = ordered.values.where((value) => value.isNotEmpty).toList();
    if (tags.isEmpty) {
      return const <String>['Chat', 'Reasoning', 'Vision', 'Coding', 'Voice', 'Agentic'];
    }
    return tags.take(8).toList();
  }

  String _formatTag(String tag) {
    final words = tag
        .split(RegExp(r'[\s_\-]+'))
        .where((word) => word.trim().isNotEmpty)
        .map((word) {
      final lower = word.toLowerCase();
      return lower[0].toUpperCase() + lower.substring(1);
    }).toList();
    return words.join(' ');
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Scaffold(
      backgroundColor: colorScheme.background,
      appBar: AppBar(
        backgroundColor: colorScheme.background,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: colorScheme.onBackground, size: 28),
          onPressed: () => Navigator.pop(context),
        ),
        titleSpacing: 0,
        title: Text(
          'Model Library',
          style: TextStyle(
            color: colorScheme.onBackground,
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: colorScheme.onBackground.withOpacity(0.8)),
            tooltip: 'Refresh catalogue',
            onPressed: _isLoading ? null : _loadModels,
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  void _showFilterSheet() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final providers = _availableModels
        .map((model) => ModelProviderExtension.fromBackend(model.provider))
        .toSet()
        .toList()
      ..sort((a, b) => a.displayName.compareTo(b.displayName));
    final tags = _discoveryTags;

    showModalBottomSheet(
      context: context,
      backgroundColor: colorScheme.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (sheetContext) {
        ModelProvider? localProvider = _providerFilter;
        String? localTag = _activeFilter;

        return StatefulBuilder(
          builder: (context, setModalState) {
            return SafeArea(
              top: false,
              child: Padding(
                padding: EdgeInsets.only(
                  left: 24,
                  right: 24,
                  top: 12,
                  bottom: 24 + MediaQuery.of(context).viewPadding.bottom,
                ),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.7,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: colorScheme.outline.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Filters',
                        style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: colorScheme.onSurface,
                            ) ??
                            TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: colorScheme.onSurface,
                            ),
                      ),
                      const SizedBox(height: 24),
                      Expanded(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (providers.isNotEmpty) ...[
                                Text(
                                  'Provider',
                                  style: theme.textTheme.titleSmall?.copyWith(
                                        fontWeight: FontWeight.w600,
                                        color: colorScheme.onSurface.withOpacity(0.8),
                                      ),
                                ),
                                const SizedBox(height: 12),
                                Wrap(
                                  spacing: 12,
                                  runSpacing: 12,
                                  children: providers
                                      .map((provider) => ChoiceChip(
                                            labelPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                            showCheckmark: false,
                                            selected: localProvider == provider,
                                            side: BorderSide(
                                              color: localProvider == provider
                                                  ? Colors.transparent
                                                  : colorScheme.outline.withOpacity(0.4),
                                            ),
                                            label: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                _buildProviderAvatar(provider, size: 28),
                                                const SizedBox(width: 10),
                                                Text(
                                                  provider.displayName,
                                                  style: TextStyle(
                                                    color: localProvider == provider
                                                        ? Colors.white
                                                        : colorScheme.onSurface.withOpacity(0.8),
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            backgroundColor: colorScheme.surfaceVariant,
                                            selectedColor: _resolveProviderColor(provider),
                                            onSelected: (selected) {
                                              setModalState(() {
                                                localProvider = selected ? provider : null;
                                              });
                                            },
                                          ))
                                      .toList(),
                                ),
                                const SizedBox(height: 28),
                              ],
                              if (tags.isNotEmpty) ...[
                                Text(
                                  'Capabilities',
                                  style: theme.textTheme.titleSmall?.copyWith(
                                        fontWeight: FontWeight.w600,
                                        color: colorScheme.onSurface.withOpacity(0.8),
                                      ),
                                ),
                                const SizedBox(height: 12),
                                Wrap(
                                  spacing: 10,
                                  runSpacing: 10,
                                  children: tags
                                      .map((tag) => FilterChip(
                                            label: Text(
                                              tag,
                                              style: TextStyle(
                                                fontWeight: FontWeight.w600,
                                                color: localTag == tag
                                                    ? Colors.white
                                                    : colorScheme.onSurface.withOpacity(0.75),
                                              ),
                                            ),
                                            selected: localTag == tag,
                                            onSelected: (_) {
                                              setModalState(() {
                                                localTag = localTag == tag ? null : tag;
                                              });
                                            },
                                            showCheckmark: false,
                                            backgroundColor: colorScheme.surfaceVariant,
                                            selectedColor: colorScheme.primary,
                                            side: BorderSide(
                                              color: localTag == tag
                                                  ? Colors.transparent
                                                  : colorScheme.outline.withOpacity(0.4),
                                            ),
                                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                          ))
                                      .toList(),
                                ),
                                const SizedBox(height: 28),
                              ],
                            ],
                          ),
                        ),
                      ),
                      Row(
                        children: [
                          TextButton(
                            onPressed: () {
                              setModalState(() {
                                localProvider = null;
                                localTag = null;
                              });
                            },
                            child: const Text('Reset'),
                          ),
                          const Spacer(),
                          FilledButton(
                            onPressed: () {
                              Navigator.of(sheetContext).pop();

                              if (localTag != _activeFilter) {
                                if (localTag == null) {
                                  _clearSearchFilters();
                                } else {
                                  _onFilterSelected(localTag!);
                                }
                              }

                              setState(() {
                                _providerFilter = localProvider;
                              });
                            },
                            style: FilledButton.styleFrom(
                              backgroundColor: colorScheme.primary,
                              foregroundColor: colorScheme.onPrimary,
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                            child: const Text(
                              'Apply filters',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildBody() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Browse curated models',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: Theme.of(context).colorScheme.onBackground,
                          ) ??
                          const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Import providers and stay in sync with the latest releases.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onBackground.withOpacity(0.65),
                          ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              _buildSortButton(),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: _buildSearchBar(),
        ),
        const SizedBox(height: 12),
        Builder(
          builder: (context) {
            final activeFilters = _buildActiveFilterChips();
            if (activeFilters == null) {
              return const SizedBox.shrink();
            }
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: activeFilters,
            );
          },
        ),
        const SizedBox(height: 12),
        Expanded(
          child: _buildModelList(),
        ),
      ],
    );
  }

  Widget _buildSortButton() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return PopupMenuButton<SortOption>(
      initialValue: _currentSort,
      onSelected: (SortOption value) {
        setState(() {
          _currentSort = value;
        });
      },
      offset: const Offset(0, 45),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          border: Border.all(color: colorScheme.outline.withOpacity(0.2)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Sort',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.unfold_more, size: 20, color: colorScheme.onSurface.withOpacity(0.6)),
          ],
        ),
      ),
      itemBuilder: (BuildContext context) => <PopupMenuEntry<SortOption>>[
        PopupMenuItem<SortOption>(
          value: SortOption.newest,
          child: Text(SortOption.newest.displayName),
        ),
        PopupMenuItem<SortOption>(
          value: SortOption.topWeekly,
          child: Text(SortOption.topWeekly.displayName),
        ),
        PopupMenuItem<SortOption>(
          value: SortOption.pricingLowToHigh,
          child: Text(SortOption.pricingLowToHigh.displayName),
        ),
        PopupMenuItem<SortOption>(
          value: SortOption.pricingHighToLow,
          child: Text(SortOption.pricingHighToLow.displayName),
        ),
        PopupMenuItem<SortOption>(
          value: SortOption.contextHighToLow,
          child: Text(SortOption.contextHighToLow.displayName),
        ),
        PopupMenuItem<SortOption>(
          value: SortOption.throughputHighToLow,
          child: Text(SortOption.throughputHighToLow.displayName),
        ),
        PopupMenuItem<SortOption>(
          value: SortOption.latencyLowToHigh,
          child: Text(SortOption.latencyLowToHigh.displayName),
        ),
      ],
    );
  }

  Widget _buildDiscoveryLayout({
    required AvailableModelOption? highlight,
    required List<Widget> bodyChildren,
    bool includeSearch = true,
    bool includeFilters = true,
  }) {
    final children = <Widget>[
      _buildTopSection(),
      const SizedBox(height: 24),
      _buildHeroCard(highlight),
    ];

    if (includeSearch) {
      children.addAll([
        const SizedBox(height: 24),
        _buildSearchBar(),
      ]);
    }

    if (includeFilters) {
      final filters = _buildCategoryFilters();
      if (filters != null) {
        children.addAll([
          const SizedBox(height: 16),
          filters,
        ]);
      }
    }

    children.add(const SizedBox(height: 24));
    children.addAll(bodyChildren);
    children.add(const SizedBox(height: 32));

    final listView = ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 56),
      children: children,
    );

    return RefreshIndicator(
      onRefresh: _loadModels,
      color: const Color(0xFF6D28D9),
      child: listView,
    );
  }

  Widget _buildTopSection() {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Model Library',
                style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: theme.colorScheme.onSurface,
                    ) ??
                    const TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.w800,
                      color: Colors.black,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'Discover curated AI models and import them into your workspace.',
                style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.7),
                    ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        _buildCircularAction(
          icon: Icons.refresh_rounded,
          tooltip: 'Refresh models',
          onTap: _loadModels,
        ),
      ],
    );
  }

  Widget _buildHeroCard(AvailableModelOption? highlight) {
    final theme = Theme.of(context);
    final provider = highlight != null
        ? ModelProviderExtension.fromBackend(highlight.provider)
        : null;
    final accentColor = highlight != null
        ? _resolveProviderColor(provider!)
        : const Color(0xFF4338CA);
    final description = highlight != null
        ? _resolveDescription(highlight)
        : 'Explore new models tailored for chat, vision, coding, and more.';

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(28),
      child: InkWell(
        borderRadius: BorderRadius.circular(28),
        onTap: highlight != null ? () => _showModelDetails(highlight) : null,
        child: Ink(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                accentColor.withOpacity(0.16),
                accentColor.withOpacity(0.08),
                Colors.white,
              ],
            ),
            border: Border.all(color: accentColor.withOpacity(0.2)),
            boxShadow: [
              BoxShadow(
                color: accentColor.withOpacity(0.15),
                blurRadius: 32,
                offset: const Offset(0, 24),
              ),
            ],
          ),
          child: Stack(
            children: [
              Positioned(
                top: -40,
                right: -30,
                child: Container(
                  width: 160,
                  height: 160,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: accentColor.withOpacity(0.18),
                  ),
                ),
              ),
              Positioned(
                bottom: -30,
                right: 40,
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: accentColor.withOpacity(0.12),
                  ),
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: accentColor.withOpacity(0.18),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.auto_awesome, size: 18, color: accentColor),
                        const SizedBox(width: 8),
                        Text(
                          highlight != null ? 'Featured model' : 'Discover models',
                          style: theme.textTheme.labelLarge?.copyWith(
                                color: accentColor,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    highlight?.name ?? 'Explore our curated catalogue',
                    style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: theme.colorScheme.onSurface,
                        ) ??
                        const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: Colors.black,
                        ),
                  ),
                  if (provider != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      provider.displayName,
                      style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: accentColor,
                          ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  Text(
                    description,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.72),
                          height: 1.4,
                        ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: accentColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        onPressed: highlight != null ? () => _showModelDetails(highlight) : _loadModels,
                        child: Text(highlight != null ? 'View details' : 'Browse models'),
                      ),
                      const SizedBox(width: 12),
                      TextButton(
                        onPressed: _loadModels,
                        child: const Text('Refresh'),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget? _buildCategoryFilters() {
    final tags = _discoveryTags;
    if (tags.isEmpty) {
      return null;
    }

    final theme = Theme.of(context);
    return SizedBox(
      height: 42,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemBuilder: (context, index) {
          final tag = tags[index];
          final selected = _activeFilter == tag;
          return FilterChip(
            label: Text(tag),
            selected: selected,
            showCheckmark: false,
            onSelected: (_) => _onFilterSelected(tag),
            backgroundColor: Colors.white,
            selectedColor: theme.colorScheme.primary,
            labelStyle: TextStyle(
              color: selected ? Colors.white : theme.colorScheme.onSurface.withOpacity(0.8),
              fontWeight: FontWeight.w600,
            ),
            side: BorderSide(color: selected ? Colors.transparent : Colors.black.withOpacity(0.08)),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          );
        },
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemCount: tags.length,
      ),
    );
  }

  Widget _buildCircularAction({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.white,
        shape: const CircleBorder(),
        elevation: 4,
        shadowColor: Colors.black.withOpacity(0.08),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Icon(icon, color: theme.colorScheme.primary, size: 22),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingState(AvailableModelOption? highlight) {
    final placeholders = List<Widget>.generate(3, (index) {
      return Padding(
        padding: EdgeInsets.only(bottom: index == 2 ? 0 : 20),
        child: _buildLoadingPlaceholderCard(),
      );
    });

    return _buildDiscoveryLayout(
      highlight: highlight,
      bodyChildren: placeholders,
    );
  }

  Widget _buildLoadingPlaceholderCard() {
    return Container(
      height: 164,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFEDE9FE),
            Color(0xFFFBF7FF),
            Color(0xFFFFFFFF),
          ],
        ),
      ),
      child: Align(
        alignment: Alignment.bottomLeft,
        child: Container(
          margin: const EdgeInsets.all(24),
          width: 120,
          height: 16,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.6),
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return TextField(
      controller: _searchController,
      onChanged: _onSearchChanged,
      decoration: InputDecoration(
        hintText: 'Search models',
        hintStyle: TextStyle(color: colorScheme.onSurface.withOpacity(0.4)),
        prefixIcon: Icon(Icons.search, color: colorScheme.onSurface.withOpacity(0.6), size: 22),
        suffixIcon: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_searchQuery.isNotEmpty)
              IconButton(
                icon: Icon(Icons.close, size: 20, color: colorScheme.onSurface.withOpacity(0.6)),
                tooltip: 'Clear search',
                onPressed: _clearSearchFilters,
              ),
            Padding(
              padding: const EdgeInsets.only(right: 6),
              child: IconButton(
                icon: Icon(Icons.tune, color: colorScheme.onSurface.withOpacity(0.7)),
                tooltip: 'Open filters',
                onPressed: _showFilterSheet,
              ),
            ),
          ],
        ),
        suffixIconConstraints: const BoxConstraints(minHeight: 0, minWidth: 0),
        filled: true,
        fillColor: colorScheme.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.outline.withOpacity(0.2)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.outline.withOpacity(0.2)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.primary.withOpacity(0.6), width: 1.4),
        ),
      ),
    );
  }

  Widget? _buildActiveFilterChips() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final chips = <Widget>[];

    if (_providerFilter != null) {
      final provider = _providerFilter!;
      final providerColor = _resolveProviderColor(provider);
      chips.add(
        InputChip(
          avatar: _buildProviderAvatar(provider, size: 28),
          label: Text(
            provider.displayName,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: providerColor,
            ),
          ),
          onDeleted: _clearProviderFilter,
          deleteIconColor: providerColor,
          backgroundColor: providerColor.withOpacity(0.12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        ),
      );
    }

    if (_activeFilter != null && _activeFilter!.isNotEmpty) {
      chips.add(
        InputChip(
          avatar: CircleAvatar(
            backgroundColor: colorScheme.primary.withOpacity(0.12),
            child: Icon(Icons.tag, size: 18, color: colorScheme.primary),
          ),
          label: Text(
            _activeFilter!,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: colorScheme.primary,
            ),
          ),
          onDeleted: _clearSearchFilters,
          deleteIconColor: colorScheme.primary,
          backgroundColor: colorScheme.primary.withOpacity(0.1),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        ),
      );
    }

    if (chips.isEmpty) {
      return null;
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: chips,
    );
  }

  Widget _buildModelList() {
    if (_isLoading && _availableModels.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_error != null && _availableModels.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'Error loading models',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadModels,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    final filtered = _sortedAndFilteredModels;

    if (filtered.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'No models found',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try adjusting your search or filters',
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadModels,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 80),
        itemCount: filtered.length,
        itemBuilder: (context, index) {
          return _buildCompactModelCard(filtered[index]);
        },
      ),
    );
  }

  List<AvailableModelOption> get _sortedAndFilteredModels {
    var models = _filteredModels;

    if (_providerFilter != null) {
      models = models
          .where(
            (model) =>
                ModelProviderExtension.fromBackend(model.provider) == _providerFilter,
          )
          .toList();
    }

    // Apply sorting
    switch (_currentSort) {
      case SortOption.newest:
        // Keep default order (assuming backend returns newest first)
        break;
      case SortOption.topWeekly:
        // Could implement based on metadata if available
        break;
      case SortOption.pricingLowToHigh:
        models.sort((a, b) {
          final priceA = _getModelPrice(a);
          final priceB = _getModelPrice(b);
          if (priceA == null && priceB == null) return 0;
          if (priceA == null) return 1;
          if (priceB == null) return -1;
          return priceA.compareTo(priceB);
        });
        break;
      case SortOption.pricingHighToLow:
        models.sort((a, b) {
          final priceA = _getModelPrice(a);
          final priceB = _getModelPrice(b);
          if (priceA == null && priceB == null) return 0;
          if (priceA == null) return 1;
          if (priceB == null) return -1;
          return priceB.compareTo(priceA);
        });
        break;
      case SortOption.contextHighToLow:
        models.sort((a, b) {
          final contextA = _getContextWindow(a);
          final contextB = _getContextWindow(b);
          if (contextA == null && contextB == null) return 0;
          if (contextA == null) return 1;
          if (contextB == null) return -1;
          return contextB.compareTo(contextA);
        });
        break;
      case SortOption.throughputHighToLow:
      case SortOption.latencyLowToHigh:
        // Could implement based on metadata if available
        break;
    }

    return models;
  }

  double? _getModelPrice(AvailableModelOption model) {
    final metadata = _normalizeMetadata(model.metadata);
    final pricing = metadata['pricing'];
    if (pricing is Map) {
      // Try to extract input price
      final inputPrice = pricing['input'] ?? pricing['prompt'] ?? pricing['input_cost_per_token'];
      if (inputPrice != null) {
        if (inputPrice is num) return inputPrice.toDouble();
        if (inputPrice is String) {
          // Try to parse price from string like "$0.50/M input"
          final match = RegExp(r'[\d.]+').firstMatch(inputPrice);
          if (match != null) {
            return double.tryParse(match.group(0)!);
          }
        }
      }
    }
    return null;
  }

  int? _getContextWindow(AvailableModelOption model) {
    final metadata = _normalizeMetadata(model.metadata);
    final context = metadata['context_window'] ?? metadata['contextWindow'] ?? metadata['contextLength'];
    if (context is int) return context;
    if (context is String) return int.tryParse(context);
    return null;
  }

  Widget? _buildCatalogueBanner() {
    final message = _catalogueMessage?.trim();
    if (message == null || message.isEmpty) {
      return null;
    }

    final colorScheme = Theme.of(context).colorScheme;
    final isFallback = _catalogueResponse?.usingFallback ?? false;
    final accent = isFallback ? const Color(0xFF6D28D9) : colorScheme.primary;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            accent.withOpacity(0.16),
            accent.withOpacity(0.08),
            Colors.white,
          ],
        ),
        border: Border.all(color: accent.withOpacity(0.22)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.7),
            ),
            child: Icon(
              isFallback ? Icons.auto_awesome : Icons.info_outline,
              color: accent,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: colorScheme.onSurface.withOpacity(0.8),
                height: 1.35,
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
    final accent = theme.colorScheme.primary;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            accent.withOpacity(0.12),
            Colors.white,
          ],
        ),
        border: Border.all(color: accent.withOpacity(0.18)),
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
    final accent = _resolveProviderColor(provider);
    final baseColor = configured ? accent : Colors.grey[700]!;
    final gradient = configured
        ? [accent.withOpacity(0.18), Colors.white]
        : [Colors.white, Colors.white];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradient,
        ),
        border: Border.all(color: baseColor.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.75),
            ),
            child: FittedBox(
              fit: BoxFit.contain,
              child: _buildProviderLogo(provider, size: 20, fallbackColor: baseColor),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            label,
            style: TextStyle(
              color: baseColor,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (!configured) ...[
            const SizedBox(width: 10),
            Icon(Icons.lock_open, size: 16, color: baseColor.withOpacity(0.75)),
          ],
        ],
      ),
    );
  }

  Widget _buildProviderHeader(ModelProvider provider, int modelCount) {
    final theme = Theme.of(context);
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
                style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: theme.colorScheme.onSurface,
                    ) ??
                    const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                '$modelCount model${modelCount == 1 ? '' : 's'} available',
                style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                      fontWeight: FontWeight.w600,
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

  Widget _buildCompactModelCard(AvailableModelOption model) {
    final provider = ModelProviderExtension.fromBackend(model.provider);
    final metadata = _normalizeMetadata(model.metadata);
    final description = _resolveDescription(model);
    final contextWindow = metadata['context_window'] ?? metadata['contextWindow'] ?? metadata['contextLength'];
    final pricing = metadata['pricing'];
    final capabilities = _stringList(metadata['capabilities']);
    final tags = _stringList(metadata['tags']);
    final isImporting = _importingModelIds.contains(model.id);

    // Get pricing info
    String? inputPrice;
    String? outputPrice;
    if (pricing is Map) {
      inputPrice = pricing['input']?.toString() ?? pricing['prompt']?.toString();
      outputPrice = pricing['output']?.toString() ?? pricing['completion']?.toString();
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: InkWell(
        onTap: () => _showModelDetails(model),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Model name and context
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
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          model.id,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (contextWindow != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '${_formatTokenCount(contextWindow)} tokens',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              // Description
              if (description.isNotEmpty) ...[
                Text(
                  description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade700,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 12),
              ],
              Row(
                children: [
                  _buildProviderAvatar(provider, size: 32),
                  const SizedBox(width: 10),
                  Text(
                    provider.displayName,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade700,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Tags/Capabilities
              if (capabilities.isNotEmpty || tags.isNotEmpty) ...[
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ...capabilities.take(3).map((cap) => _buildTag(cap, Colors.blue)),
                    ...tags.take(2).map((tag) => _buildTag(tag, Colors.purple)),
                  ],
                ),
                const SizedBox(height: 12),
              ],
              // Pricing info
              if (inputPrice != null || outputPrice != null) ...[
                Row(
                  children: [
                    if (inputPrice != null) ...[
                      Text(
                        '$inputPrice input',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      if (outputPrice != null) ...[
                        Text(
                          ' | ',
                          style: TextStyle(color: Colors.grey.shade400),
                        ),
                      ],
                    ],
                    if (outputPrice != null)
                      Text(
                        '$outputPrice output',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade700,
                        ),
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTag(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          color: color,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  String _formatTokenCount(dynamic count) {
    if (count is int) {
      if (count >= 1000000) {
        return '${(count / 1000000).toStringAsFixed(1)}M';
      } else if (count >= 1000) {
        return '${(count / 1000).toStringAsFixed(1)}K';
      }
      return count.toString();
    }
    return count.toString();
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

    final theme = Theme.of(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(28),
        onTap: () => _showModelDetails(model),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                accentColor.withOpacity(isImporting ? 0.22 : 0.16),
                accentColor.withOpacity(0.08),
                Colors.white,
              ],
            ),
            border: Border.all(
              color: accentColor.withOpacity(isImporting ? 0.45 : 0.18),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: accentColor.withOpacity(isImporting ? 0.22 : 0.14),
                blurRadius: isImporting ? 28 : 22,
                offset: const Offset(0, 20),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildProviderAvatar(provider, size: 54),
                    const SizedBox(width: 18),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            model.name,
                            style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  color: theme.colorScheme.onSurface,
                                ) ??
                                const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.black,
                                ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            model.id,
                            style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                                  fontWeight: FontWeight.w600,
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
                  const SizedBox(height: 14),
                  Text(
                    description,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.72),
                          height: 1.45,
                        ),
                  ),
                ],
                if (metadataChips.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: metadataChips,
                  ),
                ],
              ],
            ),
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
    final color = tint ?? const Color(0xFF4338CA);
    final textColor = Color.lerp(color, Colors.black, 0.4)!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withOpacity(0.18),
            color.withOpacity(0.08),
          ],
        ),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.65),
            ),
            child: Icon(icon, size: 14, color: color),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              color: textColor,
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

  List<String> _metadataSearchTerms(AvailableModelOption model) {
    final metadata = _normalizeMetadata(model.metadata);
    final metadataFields = <String>[
      ..._stringList(metadata['capabilities']),
      ..._stringList(metadata['tags']),
    ];

    return metadataFields.map((value) => value.toLowerCase()).toList();
  }

  Widget _buildErrorState(String message, AvailableModelOption? highlight) {
    return _buildDiscoveryLayout(
      highlight: highlight,
      bodyChildren: [
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
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String message,
    Widget? action,
  }) {
    final theme = Theme.of(context);
    final accent = theme.colorScheme.primary;
    return Container(
      constraints: const BoxConstraints(maxWidth: 420),
      padding: const EdgeInsets.fromLTRB(28, 32, 28, 32),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            accent.withOpacity(0.12),
            Colors.white,
          ],
        ),
        border: Border.all(color: accent.withOpacity(0.18)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: accent.withOpacity(0.15),
            ),
            child: Icon(icon, size: 32, color: accent),
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
                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                  height: 1.45,
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
