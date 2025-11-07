import 'dart:convert';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../component/models.dart';

class OllamaService {
  static final OllamaService _instance = OllamaService._internal();
  factory OllamaService() => _instance;
  OllamaService._internal();

  Future<List<String>> getOllamaModels(String baseUrl) async {
    try {
      debugPrint('Fetching Ollama models from $baseUrl');
      final response = await http.get(
        Uri.parse('$baseUrl/api/tags'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final models = (data['models'] as List<dynamic>?) ?? [];
        return models.map((model) => model['name'].toString()).toList();
      } else {
        final v1Response = await http.get(
          Uri.parse('$baseUrl/v1/models'),
          headers: {
            'Content-Type': 'application/json',
          },
        );

        if (v1Response.statusCode == 200) {
          final data = jsonDecode(v1Response.body);
          final models = (data['models'] as List<dynamic>?) ?? [];
          return models.map((model) => model['name'].toString()).toList();
        }

        debugPrint('Failed to fetch Ollama models: ${response.statusCode} ${response.body}');
        return [];
      }
    } catch (e) {
      debugPrint('Error fetching Ollama models: $e');
      return [];
    }
  }

  Future<bool> testConnection(String baseUrl) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/tags'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        return true;
      }

      final v1Response = await http.get(
        Uri.parse('$baseUrl/v1/models'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      return v1Response.statusCode == 200;
    } catch (e) {
      debugPrint('Connection test failed: $e');
      return false;
    }
  }

  Future<ModelConfig> importModel({
    required String baseUrl,
    required String modelName,
    String? systemPrompt,
    double? temperature,
  }) async {
    final config = ModelConfig(
      id: '',
      name: modelName,
      provider: ModelProvider.ollama,
      baseUrl: baseUrl,
      model: modelName,
      systemPrompt: systemPrompt,
      temperature: temperature ?? 0.8,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    return config;
  }

  Future<String> getChatResponse(
    ModelConfig config,
    String userMessage,
    bool stream,
    Function(String)? onToken,
  ) async {
    final baseUrl = config.baseUrl;
    final additionalParams = config.additionalParams ?? {};
    final temperature = additionalParams['temperature'] as double? ?? 0.7;
    final systemPrompt = additionalParams['systemPrompt'] as String? ?? '';

    // First check if the model exists
    try {
      final response = await http.get(Uri.parse('$baseUrl/api/tags'));
      if (response.statusCode != 200) {
        throw Exception('Failed to connect to Ollama server');
      }
    } catch (e) {
      debugPrint('Error checking Ollama models: $e');
      return 'Error connecting to Ollama server at ${config.baseUrl}. Please make sure Ollama is running.';
    }

    final client = http.Client();
    final completer = Completer<String>();
    final buffer = StringBuffer();
    StreamSubscription? subscription;

    try {
      final request = http.Request(
        'POST',
        Uri.parse('$baseUrl/api/generate'),
      );

      request.headers['Content-Type'] = 'application/json';
      request.body = jsonEncode({
        'model': config.model,
        'prompt': userMessage,
        'stream': true,
        'temperature': temperature,
        'system': systemPrompt,
      });

      final response = await client.send(request);

      if (response.statusCode == 200) {
        subscription = response.stream
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .listen(
            (line) {
              if (line.trim().isNotEmpty) {
                try {
                  final data = jsonDecode(line);
                  final content = data['response'] as String?;

                  if (content != null && content.isNotEmpty) {
                    buffer.write(content);
                    if (stream && onToken != null) {
                      onToken(content);
                    }
                  }

                  if (data['done'] == true) {
                    completer.complete(buffer.toString());
                    subscription?.cancel();
                    client.close();
                  }
                } catch (e) {
                  debugPrint('Warning: Error parsing streaming response line: $e\nLine: $line');
                }
              }
            },
            onDone: () {
              if (!completer.isCompleted) {
                completer.complete(buffer.toString());
              }
              subscription?.cancel();
              client.close();
            },
            onError: (e) {
              if (!completer.isCompleted) {
                completer.completeError('Error streaming response: $e');
              }
              subscription?.cancel();
              client.close();
            },
            cancelOnError: false
          );
      } else {
        client.close();
        throw Exception('Failed to get response: ${response.statusCode}');
      }

      return await completer.future;
    } catch (e) {
      client.close();
      debugPrint('Error in Ollama response: $e');
      rethrow;
    }
  }
}