/// File Overview:
/// - Purpose: Manage provider API keys and activation state directly from the
///   client.
/// - Backend Migration: Keep UI but ensure key storage/activation happens on
///   the backend rather than device-side.
import 'package:flutter/material.dart';

import '../component/models.dart';
import '../services/backend_api_service.dart';
import '../services/model_service.dart';

class ApiKeysPage extends StatefulWidget {
  const ApiKeysPage({Key? key}) : super(key: key);

  @override
  _ApiKeysPageState createState() => _ApiKeysPageState();
}

class _ApiKeysPageState extends State<ApiKeysPage> {
  final ModelService _modelService = ModelService();
  final List<ModelProvider> _supportedProviders = const [
    ModelProvider.openAI,
    ModelProvider.groq,
    ModelProvider.anthropic,
    ModelProvider.openRouter,
    ModelProvider.imageRouter,
    ModelProvider.ollama,
  ];

  List<ProviderConnection> _providers = [];
  bool _isLoading = true;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _loadProviders();
  }

  Future<void> _loadProviders() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
    });

    try {
      final remoteProviders = await _modelService.getProviders();
      final providerMap = {
        for (final provider in remoteProviders) provider.provider: provider,
      };

      for (final provider in _supportedProviders) {
        providerMap.putIfAbsent(
          provider,
          () => ProviderConnection(
            id: '',
            provider: provider,
            displayName: provider.displayName,
            baseUrl: provider.defaultBaseUrl,
            isActive: false,
            hasApiKey: false,
            apiKeyPreview: null,
            metadata: const {},
            statusMessage: 'Not configured. Add an API key to enable this provider.',
          ),
        );
      }

      if (!mounted) return;
      setState(() {
        _providers = providerMap.values.toList()
          ..sort((a, b) => a.displayName.compareTo(b.displayName));
        _loadError = null;
      });
    } catch (e) {
      if (!mounted) return;
      final message = _mapErrorToMessage(e, action: 'load your providers');
      setState(() {
        _loadError = message;
      });
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

  Future<void> _configureProvider(ProviderConnection provider) async {
    final result = await showModalBottomSheet<_ProviderUpdateResult>(
      context: context,
      isScrollControlled: true,
      builder: (context) => _ProviderConfigSheet(provider: provider),
    );

    if (result == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      if (result.deactivate) {
        await _modelService.deactivateProvider(provider.provider);
        await _loadProviders();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${provider.displayName} deactivated.')),
        );
        return;
      }

      if (provider.id.isEmpty) {
        await _modelService.activateProvider(
          provider: provider.provider,
          apiKey: result.apiKey,
          baseUrl: result.baseUrl,
        );
      } else {
        await _modelService.updateProvider(
          provider: provider.provider,
          apiKey: result.apiKey,
          baseUrl: result.baseUrl,
          removeApiKey: result.removeApiKey,
        );
      }

      await _loadProviders();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${provider.displayName} updated.')),
      );
    } catch (e) {
      if (!mounted) return;
      final message = _mapErrorToMessage(e, action: 'update ${provider.displayName}');
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

  Widget _buildProviderCard(ProviderConnection provider) {
    final requiresApiKey = provider.provider != ModelProvider.ollama;
    final isConfigured = provider.id.isNotEmpty || provider.hasApiKey || provider.isActive;
    final statusColor = provider.isActive
        ? Colors.green[700]
        : (isConfigured ? Colors.orange[700] : Colors.grey[600]);
    final statusText = provider.isActive
        ? 'Active and ready to use'
        : (isConfigured
            ? 'Configured but inactive'
            : 'Not configured yet');
    final baseUrl = (provider.baseUrl?.isNotEmpty ?? false)
        ? provider.baseUrl!
        : provider.provider.defaultBaseUrl;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
      elevation: 0,
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _configureProvider(provider),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 16,
                width: 16,
                margin: const EdgeInsets.only(top: 6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: provider.isActive
                        ? Theme.of(context).colorScheme.primary
                        : Colors.grey.shade400,
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 2,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(provider.provider.icon, color: provider.provider.color, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            provider.displayName,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      statusText,
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Base URL: $baseUrl',
                      style: const TextStyle(fontSize: 13),
                    ),
                    if (requiresApiKey)
                      Text(
                        provider.hasApiKey
                            ? 'API Key: •••• ${provider.apiKeyPreview ?? ''}'
                            : 'API Key not provided',
                        style: const TextStyle(fontSize: 13),
                      ),
                    if (provider.statusMessage != null && provider.statusMessage!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          provider.statusMessage!,
                          style: TextStyle(
                            color: Colors.grey[700],
                            fontSize: 12,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right, size: 20),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final configuredProviders = _providers.where((p) => p.id.isNotEmpty || p.isActive || p.hasApiKey).toList();
    final pendingProviders = _providers.where((p) => !(p.id.isNotEmpty || p.isActive || p.hasApiKey)).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Provider Settings'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadProviders,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      'Manage API keys and connection settings for supported providers. Only active providers will be available when adding models.',
                      style: TextStyle(color: Colors.grey[700]),
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (_loadError != null && _providers.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.warning_amber_rounded, size: 36, color: Colors.orange),
                          const SizedBox(height: 12),
                          Text(
                            _loadError!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 15),
                          ),
                          const SizedBox(height: 16),
                          OutlinedButton.icon(
                            onPressed: _loadProviders,
                            icon: const Icon(Icons.refresh),
                            label: const Text('Retry'),
                          ),
                        ],
                      ),
                    )
                  else ...[
                    if (configuredProviders.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: Text(
                          'Configured providers',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                    if (configuredProviders.isNotEmpty)
                      ...configuredProviders.map(_buildProviderCard),
                    if (configuredProviders.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: Text(
                          'No providers configured yet. Start by selecting one below.',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ),
                    const SizedBox(height: 12),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Text(
                        'Available providers',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    if (pendingProviders.isNotEmpty)
                      ...pendingProviders.map(_buildProviderCard)
                    else
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: Text(
                          'Great! Every provider has been set up.',
                          style: TextStyle(color: Colors.green[700]),
                        ),
                      ),
                  ],
                  const SizedBox(height: 24),
                ],
              ),
            ),
    );
  }

  String _mapErrorToMessage(Object error, {required String action}) {
    if (error is BackendApiException) {
      if (error.statusCode >= 500) {
        return 'We couldn\'t $action because the server responded with an error. Please try again shortly.';
      }
      if (error.statusCode == 401 || error.statusCode == 403) {
        return 'You don\'t have permission to $action. Please verify your credentials and try again.';
      }
      if (error.message.isNotEmpty) {
        return error.message;
      }
    }

    return 'We couldn\'t $action. Please check your connection and try again.';
  }
}

class _ProviderUpdateResult {
  final String? apiKey;
  final String? baseUrl;
  final bool deactivate;
  final bool removeApiKey;

  const _ProviderUpdateResult({
    this.apiKey,
    this.baseUrl,
    this.deactivate = false,
    this.removeApiKey = false,
  });
}

class _ProviderConfigSheet extends StatefulWidget {
  final ProviderConnection provider;

  const _ProviderConfigSheet({required this.provider});

  @override
  State<_ProviderConfigSheet> createState() => _ProviderConfigSheetState();
}

class _ProviderConfigSheetState extends State<_ProviderConfigSheet> {
  late final TextEditingController _baseUrlController;
  final TextEditingController _apiKeyController = TextEditingController();
  bool _removeApiKey = false;

  bool get _requiresApiKey => widget.provider.provider != ModelProvider.ollama;

  @override
  void initState() {
    super.initState();
    _baseUrlController = TextEditingController(
      text: widget.provider.baseUrl ?? widget.provider.provider.defaultBaseUrl,
    );
  }

  @override
  void dispose() {
    _baseUrlController.dispose();
    _apiKeyController.dispose();
    super.dispose();
  }

  void _submit() {
    final baseUrlText = _baseUrlController.text.trim();
    if (widget.provider.provider == ModelProvider.ollama && baseUrlText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Base URL is required for Ollama.')),
      );
      return;
    }

    final apiKeyText = _apiKeyController.text.trim();
    final hasExistingKey = widget.provider.hasApiKey;

    if (_requiresApiKey && !_removeApiKey && !hasExistingKey && apiKeyText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${widget.provider.displayName} requires an API key.')),
      );
      return;
    }

    Navigator.of(context).pop(
      _ProviderUpdateResult(
        apiKey: _removeApiKey ? null : (apiKeyText.isEmpty ? null : apiKeyText),
        baseUrl: baseUrlText.isEmpty ? null : baseUrlText,
        deactivate: false,
        removeApiKey: _removeApiKey,
      ),
    );
  }

  void _deactivate() {
    Navigator.of(context).pop(const _ProviderUpdateResult(deactivate: true));
  }

  void _clearApiKey() {
    setState(() {
      _removeApiKey = true;
      _apiKeyController.clear();
    });
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
          Text(
            '${widget.provider.displayName} Settings',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _baseUrlController,
            decoration: const InputDecoration(labelText: 'Base URL'),
          ),
          if (_requiresApiKey) ...[
            const SizedBox(height: 12),
          TextField(
            controller: _apiKeyController,
            decoration: const InputDecoration(
              labelText: 'API Key',
              helperText: 'Leave blank to keep existing key',
            ),
            obscureText: true,
            onChanged: (_) {
              if (_removeApiKey) {
                setState(() {
                  _removeApiKey = false;
                });
              }
            },
          ),
          if (widget.provider.hasApiKey)
            TextButton(
              onPressed: _clearApiKey,
              child: const Text('Remove stored API key'),
              ),
          ],
          const SizedBox(height: 24),
          Row(
            children: [
              if (widget.provider.isActive)
                TextButton(
                  onPressed: _deactivate,
                  child: const Text('Deactivate Provider'),
                ),
              const Spacer(),
              ElevatedButton(
                onPressed: _submit,
                child: const Text('Save'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
