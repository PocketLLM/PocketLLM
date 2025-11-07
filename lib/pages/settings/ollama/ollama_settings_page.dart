import 'package:flutter/material.dart';

import '../../../services/ollama_service.dart';
import '../../../services/model_service.dart';

class OllamaSettingsPage extends StatefulWidget {
  const OllamaSettingsPage({Key? key}) : super(key: key);

  @override
  _OllamaSettingsPageState createState() => _OllamaSettingsPageState();
}

class _OllamaSettingsPageState extends State<OllamaSettingsPage> {
  final OllamaService _ollamaService = OllamaService();
  final ModelService _modelService = ModelService();
  final TextEditingController _urlController = TextEditingController();

  List<String> _models = [];
  bool _isLoading = false;
  bool _isConnected = false;

  @override
  void initState() {
    super.initState();
    _urlController.text = 'http://localhost:11434';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ollama Settings'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _urlController,
              decoration: const InputDecoration(
                labelText: 'Ollama Server URL',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _connect,
              child: _isLoading
                  ? const CircularProgressIndicator()
                  : const Text('Connect'),
            ),
            const SizedBox(height: 16),
            if (_isConnected)
              Expanded(
                child: ListView.builder(
                  itemCount: _models.length,
                  itemBuilder: (context, index) {
                    final model = _models[index];
                    return ListTile(
                      title: Text(model),
                      trailing: IconButton(
                        icon: const Icon(Icons.add),
                        onPressed: () => _importModel(model),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _connect() async {
    setState(() {
      _isLoading = true;
    });

    final url = _urlController.text;
    final isConnected = await _ollamaService.testConnection(url);

    if (isConnected) {
      final models = await _ollamaService.getOllamaModels(url);
      setState(() {
        _models = models;
        _isConnected = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Connected to Ollama')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to connect to Ollama')),
      );
    }

    setState(() {
      _isLoading = false;
    });
  }

  void _importModel(String modelName) async {
    final url = _urlController.text;
    final config = await _ollamaService.importModel(
      baseUrl: url,
      modelName: modelName,
    );
    await _modelService.saveModel(config);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Imported $modelName')),
    );
  }
}
