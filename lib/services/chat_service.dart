import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'model_service.dart';
import 'pocket_llm_service.dart';
import '../component/models.dart';

class ChatService {
  static final ModelService _modelService = ModelService();
  
  // Get response from the selected model
  static Future<String> getModelResponse(String userMessage, {
    required String conversationId,
    required String modelId,
  }) async {
    try {
      final modelService = ModelService();
      debugPrint('Getting response for model ID: $modelId');
      
      // Validate model ID
      if (modelId.isEmpty) {
        debugPrint('Model ID is empty');
        throw Exception('No model selected. Please select a model in Settings.');
      }

      // Get the model configuration
      final modelConfigs = await modelService.getSavedModels();
      debugPrint('Found ${modelConfigs.length} model configs');
      
      ModelConfig? modelConfig;
      try {
        modelConfig = modelConfigs.firstWhere(
          (config) => config.id == modelId,
          orElse: () => throw Exception('Model not found with ID: $modelId'),
        );
        debugPrint('Selected model: ${modelConfig.name} (${modelConfig.provider})');
      } catch (e) {
        debugPrint('Error finding model: $e');
        throw Exception('Model not found: $e');
      }

      // Get response based on provider
      String response;
      debugPrint('Getting response from provider: ${modelConfig.provider}');
      
      switch (modelConfig.provider) {
        case ModelProvider.pocketLLM:
          debugPrint('Using PocketLLM service');
          response = await PocketLLMService.getPocketLLMResponse(modelConfig, userMessage);
          break;
          
        case ModelProvider.ollama:
          debugPrint('Using Ollama service');
          response = await _getOllamaResponse(modelConfig, userMessage, false, null);
          break;
          
        case ModelProvider.openAI:
          debugPrint('Using OpenAI service');
          response = await _getOpenAIResponse(modelConfig, userMessage, false, null);
          break;
          
        case ModelProvider.anthropic:
          debugPrint('Using Anthropic service');
          response = await _getAnthropicResponse(modelConfig, userMessage, false, null);
          break;
          
        case ModelProvider.mistral:
          debugPrint('Using Mistral service');
          response = await _getMistralResponse(modelConfig, userMessage, false, null);
          break;
          
        case ModelProvider.deepseek:
          debugPrint('Using DeepSeek service');
          response = await _getDeepseekResponse(modelConfig, userMessage, false, null);
          break;
          
        case ModelProvider.lmStudio:
          debugPrint('Using LM Studio service');
          response = await _getLMStudioResponse(modelConfig, userMessage, false, null);
          break;
          
        default:
          debugPrint('Unknown provider: ${modelConfig.provider}');
          throw Exception('Unsupported model provider: ${modelConfig.provider}');
      }
      
      debugPrint('Got response (${response.length} chars)');
      return response;
    } catch (e) {
      debugPrint('Error in getModelResponse: $e');
      throw Exception('Failed to get model response: $e');
    }
  }
  
  // Get response from Ollama
  static Future<String> _getOllamaResponse(
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
        'model': config.id,
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
  
  // Get response from OpenAI compatible API
  static Future<String> _getOpenAIResponse(
    ModelConfig config, 
    String userMessage,
    bool stream,
    Function(String)? onToken,
  ) async {
    try {
      debugPrint('Connecting to OpenAI compatible API at ${config.baseUrl}');
      
      // Get additional parameters
      final additionalParams = config.additionalParams ?? {};
      final systemPrompt = additionalParams['systemPrompt'] as String? ?? '';
      final temperature = additionalParams['temperature'] as double? ?? 0.7;
      
      // Validate the API key
      if (config.apiKey == null || config.apiKey!.isEmpty) {
        return 'API key is required for OpenAI compatible API.';
      }
      
      // Prepare messages with system prompt if provided
      final messages = <Map<String, String>>[];
      
      if (systemPrompt.isNotEmpty) {
        messages.add({
          'role': 'system',
          'content': systemPrompt,
        });
      }
      
      messages.add({
        'role': 'user',
        'content': userMessage,
      });
      
      // Handle streaming response if requested
      if (stream && onToken != null) {
        final client = http.Client();
        final completer = Completer<String>();
        final buffer = StringBuffer();
        StreamSubscription? subscription;
        
        void cleanupAndComplete([String? error]) {
          subscription?.cancel();
          client.close();
          if (error != null && !completer.isCompleted) {
            completer.completeError(error);
          } else if (!completer.isCompleted) {
            completer.complete(buffer.toString());
          }
        }
        
        try {
          final request = http.Request(
            'POST',
            Uri.parse('${config.baseUrl}/chat/completions'),
          );
          
          request.headers['Authorization'] = 'Bearer ${config.apiKey}';
          request.headers['Content-Type'] = 'application/json';
          request.body = jsonEncode({
            'model': config.id,
            'messages': messages,
            'stream': true,
            'temperature': temperature,
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
                      // Handle SSE format with 'data: ' prefix
                      if (line.startsWith('data: ')) {
                        line = line.substring(6).trim();
                      }
                      
                      // Skip empty lines and [DONE] marker
                      if (line.isEmpty || line == '[DONE]') {
                        if (line == '[DONE]') {
                          cleanupAndComplete();
                        }
                        return;
                      }
                      
                      // Try to parse the JSON data
                      Map<String, dynamic> data;
                      try {
                        data = jsonDecode(line);
                      } catch (jsonError) {
                        debugPrint('Warning: Invalid JSON in streaming response: $jsonError\nLine: $line');
                        return; // Skip this line and continue
                      }
                      
                      String? content;
                      
                      // Handle OpenAI format
                      if (data['choices'] != null && data['choices'].isNotEmpty) {
                        if (data['choices'][0]['delta'] != null && data['choices'][0]['delta']['content'] != null) {
                          content = data['choices'][0]['delta']['content'];
                        } else if (data['choices'][0]['message'] != null && data['choices'][0]['message']['content'] != null) {
                          content = data['choices'][0]['message']['content'];
                        }
                      }
                      
                      if (content != null && content.isNotEmpty) {
                        buffer.write(content);
                        onToken(content);
                      }
                    } catch (e) {
                      debugPrint('Warning: Error parsing streaming response line: $e');
                      // Continue processing other lines
                    }
                  }
                },
                onDone: () => cleanupAndComplete(),
                onError: (e) => cleanupAndComplete('Error streaming response: $e'),
                cancelOnError: false
              );
          } else {
            cleanupAndComplete('Failed to get response: ${response.statusCode}');
          }
          
          return await completer.future;
        } catch (e) {
          cleanupAndComplete('Error in OpenAI streaming response: $e');
          rethrow;
        }
      } else {
        // Handle non-streaming response
        final response = await http.post(
          Uri.parse('${config.baseUrl}/chat/completions'),
          headers: {
            'Authorization': 'Bearer ${config.apiKey}',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'model': config.id,
            'messages': messages,
            'stream': false,
            'temperature': temperature,
          }),
        );
        
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          return data['choices'][0]['message']['content'];
        } else {
          debugPrint('OpenAI API error: ${response.statusCode} ${response.body}');
          return 'Failed to get response: ${response.statusCode} - ${response.body}';
        }
      }
    } catch (e) {
      debugPrint('Error getting OpenAI response: $e');
      return 'Error connecting to OpenAI: $e';
    }
  }
  
  // Get response from Anthropic
  static Future<String> _getAnthropicResponse(
    ModelConfig config, 
    String userMessage,
    bool stream,
    Function(String)? onToken,
  ) async {
    try {
      debugPrint('Connecting to Anthropic API at ${config.baseUrl}');
      
      // Get additional parameters
      final additionalParams = config.additionalParams ?? {};
      final systemPrompt = additionalParams['systemPrompt'] as String? ?? '';
      final temperature = additionalParams['temperature'] as double? ?? 0.7;
      
      // Validate the API key
      if (config.apiKey == null || config.apiKey!.isEmpty) {
        return 'API key is required for Anthropic API.';
      }
      
      final Map<String, dynamic> requestBody = {
        'model': config.id,
        'messages': [
          {'role': 'user', 'content': userMessage},
        ],
        'max_tokens': 1024,
        'temperature': temperature,
      };
      
      // Add system prompt if provided
      if (systemPrompt.isNotEmpty) {
        requestBody['system'] = systemPrompt;
      }
      
      final response = await http.post(
        Uri.parse('${config.baseUrl}/v1/messages'),
        headers: {
          'x-api-key': config.apiKey ?? '',
          'Content-Type': 'application/json',
          'anthropic-version': '2023-06-01',
        },
        body: jsonEncode(requestBody),
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['content'][0]['text'];
      } else {
        debugPrint('Anthropic API error: ${response.statusCode} ${response.body}');
        return 'Failed to get response: ${response.statusCode} - ${response.body}';
      }
    } catch (e) {
      debugPrint('Error getting Anthropic response: $e');
      return 'Error connecting to Anthropic: $e';
    }
  }
  
  // Get response from LLM Studio
  static Future<String> _getLMStudioResponse(
    ModelConfig config, 
    String userMessage,
    bool stream,
    Function(String)? onToken,
  ) async {
    try {
      debugPrint('Connecting to LLM Studio at ${config.baseUrl}');
      
      // Get additional parameters
      final additionalParams = config.additionalParams ?? {};
      final systemPrompt = additionalParams['systemPrompt'] as String? ?? '';
      final temperature = additionalParams['temperature'] as double? ?? 0.7;
      
      // Implement LLM Studio API call
      final response = await http.post(
        Uri.parse('${config.baseUrl}/api/generate'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'model': config.id,
          'prompt': systemPrompt.isNotEmpty 
              ? '$systemPrompt\n\n$userMessage' 
              : userMessage,
          'max_tokens': 1024,
          'temperature': temperature,
        }),
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['response'] ?? 'No response from LLM Studio';
      } else {
        debugPrint('LLM Studio API error: ${response.statusCode} ${response.body}');
        return 'Failed to get response: ${response.statusCode} - ${response.body}';
      }
    } catch (e) {
      debugPrint('Error getting LLM Studio response: $e');
      return 'Error connecting to LLM Studio: $e';
    }
  }



  // Get response from Mistral
  static Future<String> _getMistralResponse(
    ModelConfig config, 
    String userMessage,
    bool stream,
    Function(String)? onToken,
  ) async {
    try {
      debugPrint('Connecting to Mistral at ${config.baseUrl}');
      
      // Get additional parameters
      final additionalParams = config.additionalParams ?? {};
      final systemPrompt = additionalParams['systemPrompt'] as String? ?? '';
      final temperature = additionalParams['temperature'] as double? ?? 0.7;
      
      // Prepare messages with system prompt if provided
      final messages = <Map<String, String>>[];
      
      if (systemPrompt.isNotEmpty) {
        messages.add({
          'role': 'system',
          'content': systemPrompt,
        });
      }
      
      messages.add({
        'role': 'user',
        'content': userMessage,
      });
      
      // Handle streaming response if requested
      if (stream && onToken != null) {
        final client = http.Client();
        final completer = Completer<String>();
        final buffer = StringBuffer();
        StreamSubscription? subscription;
        
        void cleanupAndComplete([String? error]) {
          subscription?.cancel();
          client.close();
          if (error != null && !completer.isCompleted) {
            completer.completeError(error);
          } else if (!completer.isCompleted) {
            completer.complete(buffer.toString());
          }
        }
        
        try {
          final request = http.Request(
            'POST',
            Uri.parse('${config.baseUrl}/chat/completions'),
          );
          
          request.headers['Authorization'] = 'Bearer ${config.apiKey}';
          request.headers['Content-Type'] = 'application/json';
          request.body = jsonEncode({
            'model': config.id,
            'messages': messages,
            'stream': true,
            'temperature': temperature,
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
                      // Handle SSE format with 'data: ' prefix
                      if (line.startsWith('data: ')) {
                        line = line.substring(6).trim();
                      }
                      
                      // Skip empty lines and [DONE] marker
                      if (line.isEmpty || line == '[DONE]') {
                        if (line == '[DONE]') {
                          cleanupAndComplete();
                        }
                        return;
                      }
                      
                      // Try to parse the JSON data
                      Map<String, dynamic> data;
                      try {
                        data = jsonDecode(line);
                      } catch (jsonError) {
                        debugPrint('Warning: Invalid JSON in streaming response: $jsonError\nLine: $line');
                        return; // Skip this line and continue
                      }
                      
                      String? content;
                      
                      // Handle Mistral format (similar to OpenAI)
                      if (data['choices'] != null && data['choices'].isNotEmpty) {
                        if (data['choices'][0]['delta'] != null && data['choices'][0]['delta']['content'] != null) {
                          content = data['choices'][0]['delta']['content'];
                        } else if (data['choices'][0]['message'] != null && data['choices'][0]['message']['content'] != null) {
                          content = data['choices'][0]['message']['content'];
                        }
                      }
                      
                      if (content != null && content.isNotEmpty) {
                        buffer.write(content);
                        onToken(content);
                      }
                    } catch (e) {
                      debugPrint('Warning: Error parsing streaming response line: $e');
                      // Continue processing other lines
                    }
                  }
                },
                onDone: () => cleanupAndComplete(),
                onError: (e) => cleanupAndComplete('Error streaming response: $e'),
                cancelOnError: false
              );
          } else {
            cleanupAndComplete('Failed to get response: ${response.statusCode}');
          }
          
          return await completer.future;
        } catch (e) {
          cleanupAndComplete('Error in Mistral streaming response: $e');
          rethrow;
        }
      } else {
        // Non-streaming response
        final response = await http.post(
          Uri.parse('${config.baseUrl}/chat/completions'),
          headers: {
            'Authorization': 'Bearer ${config.apiKey}',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'model': config.id,
            'messages': messages,
            'temperature': temperature,
          }),
        );

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          return data['choices']?[0]?['message']?['content'] ?? 'No response content';
        } else {
          Map<String, dynamic> errorData;
          try {
            errorData = jsonDecode(response.body);
            final errorMessage = errorData['error']?['message'] ?? 'Unknown error';
            throw Exception('Failed to get response: $errorMessage');
          } catch (e) {
            throw Exception('Failed to get response: ${response.statusCode}');
          }
        }
      }
    } catch (e) {
      debugPrint('Error getting Mistral response: $e');
      return 'Error connecting to Mistral: $e';
    }
  }

  // Get response from DeepSeek
  static Future<String> _getDeepseekResponse(
    ModelConfig config, 
    String userMessage,
    bool stream,
    Function(String)? onToken,
  ) async {
    try {
      debugPrint('Connecting to DeepSeek at ${config.baseUrl}');
      
      // Get additional parameters
      final additionalParams = config.additionalParams ?? {};
      final systemPrompt = additionalParams['systemPrompt'] as String? ?? '';
      final temperature = additionalParams['temperature'] as double? ?? 0.7;
      
      // Prepare messages with system prompt if provided
      final messages = <Map<String, String>>[];
      
      if (systemPrompt.isNotEmpty) {
        messages.add({
          'role': 'system',
          'content': systemPrompt,
        });
      }
      
      messages.add({
        'role': 'user',
        'content': userMessage,
      });
      
      // Handle streaming response if requested
      if (stream && onToken != null) {
        final client = http.Client();
        final completer = Completer<String>();
        final buffer = StringBuffer();
        StreamSubscription? subscription;
        
        void cleanupAndComplete([String? error]) {
          subscription?.cancel();
          client.close();
          if (error != null && !completer.isCompleted) {
            completer.completeError(error);
          } else if (!completer.isCompleted) {
            completer.complete(buffer.toString());
          }
        }
        
        try {
          final request = http.Request(
            'POST',
            Uri.parse('${config.baseUrl}/chat/completions'),
          );
          
          request.headers['Authorization'] = 'Bearer ${config.apiKey}';
          request.headers['Content-Type'] = 'application/json';
          request.body = jsonEncode({
            'model': config.id,
            'messages': messages,
            'stream': true,
            'temperature': temperature,
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
                      // Handle SSE format with 'data: ' prefix
                      if (line.startsWith('data: ')) {
                        line = line.substring(6).trim();
                      }
                      
                      // Skip empty lines and [DONE] marker
                      if (line.isEmpty || line == '[DONE]') {
                        if (line == '[DONE]') {
                          cleanupAndComplete();
                        }
                        return;
                      }
                      
                      // Try to parse the JSON data
                      Map<String, dynamic> data;
                      try {
                        data = jsonDecode(line);
                      } catch (jsonError) {
                        debugPrint('Warning: Invalid JSON in streaming response: $jsonError\nLine: $line');
                        return; // Skip this line and continue
                      }
                      
                      String? content;
                      
                      // Handle DeepSeek format (similar to OpenAI)
                      if (data['choices'] != null && data['choices'].isNotEmpty) {
                        if (data['choices'][0]['delta'] != null && data['choices'][0]['delta']['content'] != null) {
                          content = data['choices'][0]['delta']['content'];
                        } else if (data['choices'][0]['message'] != null && data['choices'][0]['message']['content'] != null) {
                          content = data['choices'][0]['message']['content'];
                        }
                      }
                      
                      if (content != null && content.isNotEmpty) {
                        buffer.write(content);
                        onToken(content);
                      }
                    } catch (e) {
                      debugPrint('Warning: Error parsing streaming response line: $e');
                      // Continue processing other lines
                    }
                  }
                },
                onDone: () => cleanupAndComplete(),
                onError: (e) => cleanupAndComplete('Error streaming response: $e'),
                cancelOnError: false
              );
          } else {
            cleanupAndComplete('Failed to get response: ${response.statusCode}');
          }
          
          return await completer.future;
        } catch (e) {
          cleanupAndComplete('Error in DeepSeek streaming response: $e');
          rethrow;
        }
      } else {
        // Handle non-streaming response
        final response = await http.post(
          Uri.parse('${config.baseUrl}/chat/completions'),
          headers: {
            'Authorization': 'Bearer ${config.apiKey}',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'model': config.id,
            'messages': messages,
            'temperature': temperature,
          }),
        );
        
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          return data['choices'][0]['message']['content'];
        } else {
          debugPrint('DeepSeek API error: ${response.statusCode} ${response.body}');
          return 'Failed to get response: ${response.statusCode} - ${response.body}';
        }
      }
    } catch (e) {
      debugPrint('Error getting DeepSeek response: $e');
      return 'Error connecting to DeepSeek: $e';
    }
  }
}