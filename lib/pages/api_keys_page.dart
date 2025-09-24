import 'package:flutter/material.dart';
import '../services/model_service.dart';
import '../component/models.dart';

class ApiKeysPage extends StatefulWidget {
  const ApiKeysPage({Key? key}) : super(key: key);

  @override
  _ApiKeysPageState createState() => _ApiKeysPageState();
}

class _ApiKeysPageState extends State<ApiKeysPage> {
  final ModelService _modelService = ModelService();
  final List<ModelProvider> _supportedProviders = const [
    ModelProvider.openAI,
    ModelProvider.anthropic,
    ModelProvider.openRouter,
    ModelProvider.ollama,
  ];

  List<ProviderConnection> _providers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProviders();
  }

  Future<void> _loadProviders() async {
    setState(() {
      _isLoading = true;
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
          ),
        );
      }

      if (!mounted) return;
      setState(() {
        _providers = providerMap.values.toList()
          ..sort((a, b) => a.displayName.compareTo(b.displayName));
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load providers: $e')),
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update provider: $e')),
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
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: provider.provider.color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(provider.provider.icon, color: provider.provider.color),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        provider.displayName,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                      ),
                      Text(
                        provider.isActive ? 'Active' : 'Inactive',
                        style: TextStyle(color: provider.isActive ? Colors.green : Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.settings),
                  tooltip: 'Configure',
                  onPressed: () => _configureProvider(provider),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildInfoRow('Base URL', provider.baseUrl ?? provider.provider.defaultBaseUrl),
            if (requiresApiKey)
              _buildInfoRow(
                'API Key',
                provider.hasApiKey
                    ? '•••• ${provider.apiKeyPreview ?? ''}'
                    : 'Not configured',
              ),
            if (provider.metadata != null && provider.metadata!.isNotEmpty)
              _buildInfoRow('Metadata', provider.metadata.toString()),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () => _configureProvider(provider),
                icon: const Icon(Icons.edit),
                label: Text(provider.isActive ? 'Update Settings' : 'Activate'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(fontSize: 14)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Provider Settings'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadProviders,
              child: ListView(
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
                  if (_providers.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: Center(
                        child: Text(
                          'No providers configured yet. Tap a provider to add your credentials.',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ),
                    )
                  else
                    ..._providers.map(_buildProviderCard),
                  const SizedBox(height: 24),
                ],
              ),
            ),
    );
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
