import 'package:flutter/material.dart';

class OllamaModel {
  final String name;
  final String description;
  final List<String> parameters;
  final String category;
  final String size;
  final int pulls;
  final int tags;
  final String lastUpdated;
  final String url;
  bool isDownloading;
  double downloadProgress;
  bool isDownloaded;
  bool isConfiguring;
  Map<String, dynamic> configuration;

  OllamaModel({
    required this.name,
    required this.description,
    this.parameters = const [],
    this.category = 'Text',
    this.size = 'Unknown',
    this.pulls = 0,
    this.tags = 0,
    this.lastUpdated = '',
    this.url = '',
    this.isDownloading = false,
    this.downloadProgress = 0.0,
    this.isDownloaded = false,
    this.isConfiguring = false,
    this.configuration = const {},
  });

  // Get parameter sizes
  List<String> getParameterSizes() {
    return parameters.where((param) => 
      param.contains('b') || param.contains('m')
    ).toList();
  }

  // Get parameter features
  List<String> getParameterFeatures() {
    return parameters.where((param) => 
      !param.contains('b') && !param.contains('m')
    ).toList();
  }

  // Check if model has a specific feature
  bool hasFeature(String feature) {
    return parameters.any((param) => param.toLowerCase() == feature.toLowerCase());
  }

  // Get default parameter size
  String getDefaultSize() {
    final sizes = getParameterSizes();
    return sizes.isNotEmpty ? sizes[0] : '';
  }

  // Get all available models
  static List<OllamaModel> getAllModels() {
    return [
      OllamaModel(
        name: 'deepseek-r1',
        description: "DeepSeek's first-generation of reasoning models with comparable performance to OpenAI-o1, including six dense models distilled from DeepSeek-R1 based on Llama and Qwen.",
        parameters: ['1.5b', '7b', '8b', '14b', '32b', '70b', '671b'],
        pulls: 22600000,
        tags: 29,
        lastUpdated: '3 weeks ago',
      ),
      OllamaModel(
        name: 'llama3.3',
        description: 'New state of the art 70B model. Llama 3.3 70B offers similar performance compared to the Llama 3.1 405B model.',
        parameters: ['tools', '70b'],
        pulls: 1400000,
        tags: 14,
        lastUpdated: '2 months ago',
      ),
      OllamaModel(
        name: 'phi4',
        description: 'Phi-4 is a 14B parameter, state-of-the-art open model from Microsoft.',
        parameters: ['14b'],
        pulls: 861200,
        tags: 5,
        lastUpdated: '7 weeks ago',
      ),
      OllamaModel(
        name: 'llama3.2',
        description: "Meta's Llama 3.2 goes small with 1B and 3B models.",
        parameters: ['tools', '1b', '3b'],
        pulls: 9800000,
        tags: 63,
        lastUpdated: '5 months ago',
      ),
      OllamaModel(
        name: 'llama3.1',
        description: 'Llama 3.1 is a new state-of-the-art model from Meta available in 8B, 70B and 405B parameter sizes.',
        parameters: ['tools', '8b', '70b', '405b'],
        pulls: 25700000,
        tags: 93,
        lastUpdated: '3 months ago',
      ),
      OllamaModel(
        name: 'nomic-embed-text',
        description: 'A high-performing open embedding model with a large token context window.',
        parameters: ['embedding'],
        category: 'Embedding',
        pulls: 17900000,
        tags: 3,
        lastUpdated: '12 months ago',
      ),
      OllamaModel(
        name: 'mistral',
        description: 'The 7B model released by Mistral AI, updated to version 0.3.',
        parameters: ['tools', '7b'],
        pulls: 9800000,
        tags: 84,
        lastUpdated: '7 months ago',
      ),
      OllamaModel(
        name: 'qwen2.5',
        description: 'Qwen2.5 models are pretrained on Alibaba\'s latest large-scale dataset, encompassing up to 18 trillion tokens. The model supports up to 128K tokens and has multilingual support.',
        parameters: ['tools', '0.5b', '1.5b', '3b', '7b', '14b', '32b', '72b'],
        pulls: 4900000,
        tags: 133,
        lastUpdated: '5 months ago',
      ),
      OllamaModel(
        name: 'qwen2.5-coder',
        description: 'The latest series of Code-Specific Qwen models, with significant improvements in code generation, code reasoning, and code fixing.',
        parameters: ['tools', '0.5b', '1.5b', '3b', '7b', '14b', '32b'],
        category: 'Code',
        pulls: 4400000,
        tags: 196,
        lastUpdated: '3 months ago',
      ),
      OllamaModel(
        name: 'gemma',
        description: 'Gemma is a family of lightweight, state-of-the-art open models built by Google DeepMind. Updated to version 1.1',
        parameters: ['2b', '7b'],
        pulls: 4400000,
        tags: 102,
        lastUpdated: '10 months ago',
      ),
      OllamaModel(
        name: 'llava',
        description: '🌋 LLaVA is a novel end-to-end trained large multimodal model that combines a vision encoder and Vicuna for general-purpose visual and language understanding. Updated to version 1.6.',
        parameters: ['vision', '7b', '13b', '34b'],
        category: 'Vision',
        pulls: 3700000,
        tags: 98,
        lastUpdated: '13 months ago',
      ),
      OllamaModel(
        name: 'gemma2',
        description: 'Google Gemma 2 is a high-performing and efficient model available in three sizes: 2B, 9B, and 27B.',
        parameters: ['2b', '9b', '27b'],
        pulls: 3100000,
        tags: 94,
        lastUpdated: '7 months ago',
      ),
      OllamaModel(
        name: 'llama2',
        description: 'Llama 2 is a collection of foundation language models ranging from 7B to 70B parameters.',
        parameters: ['7b', '13b', '70b'],
        pulls: 3000000,
        tags: 102,
        lastUpdated: '14 months ago',
      ),
      OllamaModel(
        name: 'phi3',
        description: 'Phi-3 is a family of lightweight 3B (Mini) and 14B (Medium) state-of-the-art open models by Microsoft.',
        parameters: ['3.8b', '14b'],
        pulls: 2900000,
        tags: 72,
        lastUpdated: '7 months ago',
      ),
      OllamaModel(
        name: 'codellama',
        description: 'A large language model that can use text prompts to generate and discuss code.',
        parameters: ['7b', '13b', '34b', '70b'],
        category: 'Code',
        pulls: 1800000,
        tags: 199,
        lastUpdated: '7 months ago',
      ),
      OllamaModel(
        name: 'mxbai-embed-large',
        description: 'State-of-the-art large embedding model from mixedbread.ai',
        parameters: ['embedding', '335m'],
        category: 'Embedding',
        pulls: 1700000,
        tags: 4,
        lastUpdated: '10 months ago',
      ),
      OllamaModel(
        name: 'llama3.2-vision',
        description: 'Llama 3.2 Vision is a collection of instruction-tuned image reasoning generative models in 11B and 90B sizes.',
        parameters: ['vision', '11b', '90b'],
        category: 'Vision',
        pulls: 1400000,
        tags: 9,
        lastUpdated: '3 months ago',
      ),
      OllamaModel(
        name: 'tinyllama',
        description: 'The TinyLlama project is an open endeavor to train a compact 1.1B Llama model on 3 trillion tokens.',
        parameters: ['1.1b'],
        pulls: 1300000,
        tags: 36,
        lastUpdated: '14 months ago',
      ),
      OllamaModel(
        name: 'mistral-nemo',
        description: 'A state-of-the-art 12B model with 128k context length, built by Mistral AI in collaboration with NVIDIA.',
        parameters: ['tools', '12b'],
        pulls: 1300000,
        tags: 17,
        lastUpdated: '7 months ago',
      ),
      OllamaModel(
        name: 'starcoder2',
        description: 'StarCoder2 is the next generation of transparently trained open code LLMs that comes in three sizes: 3B, 7B and 15B parameters.',
        parameters: ['3b', '7b', '15b'],
        category: 'Code',
        pulls: 893100,
        tags: 67,
        lastUpdated: '5 months ago',
      ),
      OllamaModel(
        name: 'deepseek-v3',
        description: 'A strong Mixture-of-Experts (MoE) language model with 671B total parameters with 37B activated for each token.',
        parameters: ['671b'],
        pulls: 707000,
        tags: 5,
        lastUpdated: '7 weeks ago',
      ),
      OllamaModel(
        name: 'deepseek-coder-v2',
        description: 'An open-source Mixture-of-Experts code language model that achieves performance comparable to GPT4-Turbo in code-specific tasks.',
        parameters: ['16b', '236b'],
        category: 'Code',
        pulls: 702900,
        tags: 64,
        lastUpdated: '5 months ago',
      ),
      OllamaModel(
        name: 'snowflake-arctic-embed',
        description: 'A suite of text embedding models by Snowflake, optimized for performance.',
        parameters: ['embedding', '22m', '33m', '110m', '137m', '335m'],
        category: 'Embedding',
        pulls: 695000,
        tags: 16,
        lastUpdated: '10 months ago',
      ),
      OllamaModel(
        name: 'llama2-uncensored',
        description: 'Uncensored Llama 2 model by George Sung and Jarrad Hope.',
        parameters: ['7b', '70b'],
        pulls: 631800,
        tags: 34,
        lastUpdated: '16 months ago',
      ),
      OllamaModel(
        name: 'deepseek-coder',
        description: 'DeepSeek Coder is a capable coding model trained on two trillion code and natural language tokens.',
        parameters: ['1.3b', '6.7b', '33b'],
        category: 'Code',
        pulls: 589200,
        tags: 102,
        lastUpdated: '14 months ago',
      ),
      OllamaModel(
        name: 'mixtral',
        description: 'A set of Mixture of Experts (MoE) model with open weights by Mistral AI in 8x7b and 8x22b parameter sizes.',
        parameters: ['tools', '8x7b', '8x22b'],
        pulls: 576500,
        tags: 70,
        lastUpdated: '2 months ago',
      ),
      OllamaModel(
        name: 'dolphin-mixtral',
        description: 'Uncensored, 8x7b and 8x22b fine-tuned models based on the Mixtral mixture of experts models that excels at coding tasks.',
        parameters: ['8x7b', '8x22b'],
        category: 'Code',
        pulls: 517900,
        tags: 70,
        lastUpdated: '2 months ago',
      ),
      OllamaModel(
        name: 'codegemma',
        description: 'CodeGemma is a collection of powerful, lightweight models that can perform a variety of coding tasks.',
        parameters: ['2b', '7b'],
        category: 'Code',
        pulls: 514000,
        tags: 85,
        lastUpdated: '7 months ago',
      ),
      OllamaModel(
        name: 'openthinker',
        description: 'A fully open-source family of reasoning models built using a dataset derived by distilling DeepSeek-R1.',
        parameters: ['7b', '32b'],
        pulls: 506100,
        tags: 9,
        lastUpdated: '2 weeks ago',
      ),
      OllamaModel(
        name: 'bge-m3',
        description: 'BGE-M3 is a new model from BAAI distinguished for its versatility in Multi-Functionality, Multi-Linguality, and Multi-Granularity.',
        parameters: ['embedding', '567m'],
        category: 'Embedding',
        pulls: 498200,
        tags: 3,
        lastUpdated: '6 months ago',
      ),
      OllamaModel(
        name: 'phi',
        description: 'Phi-2: a 2.7B language model by Microsoft Research that demonstrates outstanding reasoning and language understanding capabilities.',
        parameters: ['2.7b'],
        pulls: 494000,
        tags: 18,
        lastUpdated: '14 months ago',
      ),
      OllamaModel(
        name: 'minicpm-v',
        description: 'A series of multimodal LLMs (MLLMs) designed for vision-language understanding.',
        parameters: ['vision', '8b'],
        category: 'Vision',
        pulls: 433800,
        tags: 17,
        lastUpdated: '3 months ago',
      ),
      OllamaModel(
        name: 'llava-llama3',
        description: 'A LLaVA model fine-tuned from Llama 3 Instruct with better scores in several benchmarks.',
        parameters: ['vision', '8b'],
        category: 'Vision',
        pulls: 395500,
        tags: 4,
        lastUpdated: '10 months ago',
      ),
      OllamaModel(
        name: 'wizardlm2',
        description: 'State of the art large language model from Microsoft AI with improved performance on complex chat, multilingual, reasoning and agent use cases.',
        parameters: ['7b', '8x22b'],
        pulls: 355600,
        tags: 22,
        lastUpdated: '10 months ago',
      ),
      OllamaModel(
        name: 'dolphin-mistral',
        description: 'The uncensored Dolphin model based on Mistral that excels at coding tasks. Updated to version 2.8.',
        parameters: ['7b'],
        category: 'Code',
        pulls: 323400,
        tags: 120,
        lastUpdated: '11 months ago',
      ),
      OllamaModel(
        name: 'smollm2',
        description: 'SmolLM2 is a family of compact language models available in three size: 135M, 360M, and 1.7B parameters.',
        parameters: ['tools', '135m', '360m', '1.7b'],
        pulls: 319500,
        tags: 49,
        lastUpdated: '4 months ago',
      ),
      OllamaModel(
        name: 'all-minilm',
        description: 'Embedding models on very large sentence level datasets.',
        parameters: ['embedding', '22m', '33m'],
        category: 'Embedding',
        pulls: 304600,
        tags: 10,
        lastUpdated: '10 months ago',
      ),
      OllamaModel(
        name: 'dolphin-llama3',
        description: 'Dolphin 2.9 is a new model with 8B and 70B sizes by Eric Hartford based on Llama 3 that has a variety of instruction, conversational, and coding skills.',
        parameters: ['8b', '70b'],
        pulls: 289500,
        tags: 53,
        lastUpdated: '9 months ago',
      ),
      OllamaModel(
        name: 'dolphin3',
        description: 'Dolphin 3.0 Llama 3.1 8B 🐬 is the next generation of the Dolphin series of instruct-tuned models designed to be the ultimate general purpose local model.',
        parameters: ['8b'],
        pulls: 287000,
        tags: 5,
        lastUpdated: '8 weeks ago',
      ),
      OllamaModel(
        name: 'command-r',
        description: 'Command R is a Large Language Model optimized for conversational interaction and long context tasks.',
        parameters: ['tools', '35b'],
        pulls: 281700,
        tags: 32,
        lastUpdated: '6 months ago',
      ),
      OllamaModel(
        name: 'orca-mini',
        description: 'A general-purpose model ranging from 3 billion parameters to 70 billion, suitable for entry-level hardware.',
        parameters: ['3b', '7b', '13b', '70b'],
        pulls: 276100,
        tags: 119,
        lastUpdated: '16 months ago',
      ),
      OllamaModel(
        name: 'yi',
        description: 'Yi 1.5 is a high-performing, bilingual language model.',
        parameters: ['6b', '9b', '34b'],
        pulls: 266300,
        tags: 174,
        lastUpdated: '9 months ago',
      ),
      OllamaModel(
        name: 'hermes3',
        description: 'Hermes 3 is the latest version of the flagship Hermes series of LLMs by Nous Research',
        parameters: ['tools', '3b', '8b', '70b', '405b'],
        pulls: 261500,
        tags: 65,
        lastUpdated: '2 months ago',
      ),
    ];
  }

  // Get models by category
  static List<OllamaModel> getModelsByCategory(String category) {
    if (category.toLowerCase() == 'all models') {
      return getAllModels();
    }
    return getAllModels().where((model) => 
      model.category.toLowerCase() == category.toLowerCase()
    ).toList();
  }

  // Search models
  static List<OllamaModel> searchModels(String query) {
    query = query.toLowerCase();
    return getAllModels().where((model) =>
      model.name.toLowerCase().contains(query) ||
      model.description.toLowerCase().contains(query) ||
      model.parameters.any((param) => param.toLowerCase().contains(query))
    ).toList();
  }

  // Get icon based on category
  IconData getCategoryIcon() {
    switch (category.toLowerCase()) {
      case 'vision':
        return Icons.image;
      case 'audio':
        return Icons.mic;
      case 'embedding':
        return Icons.data_array;
      case 'code':
        return Icons.code;
      case 'text':
      default:
        return Icons.text_fields;
    }
  }

  // Get color based on category
  MaterialColor getCategoryColor() {
    switch (category.toLowerCase()) {
      case 'vision':
        return Colors.blue;
      case 'audio':
        return Colors.orange;
      case 'embedding':
        return Colors.teal;
      case 'code':
        return Colors.indigo;
      case 'text':
      default:
        return Colors.purple;
    }
  }

  // Get formatted size string
  String getFormattedSize() {
    final sizes = getParameterSizes();
    if (sizes.isNotEmpty) {
      return sizes.map((s) => s.toUpperCase()).join(', ');
    }
    return size;
  }

  // Get formatted pulls count
  String getFormattedPulls() {
    if (pulls >= 1000000) {
      return '${(pulls / 1000000).toStringAsFixed(1)}M';
    } else if (pulls >= 1000) {
      return '${(pulls / 1000).toStringAsFixed(1)}K';
    }
    return pulls.toString();
  }

  // Get model full name with size
  String getFullModelName(String selectedSize) {
    if (selectedSize.isEmpty) return name;
    return '$name:$selectedSize';
  }

  // Get installation command
  String getInstallCommand(String selectedSize) {
    final modelName = getFullModelName(selectedSize);
    return 'ollama pull $modelName';
  }

  // Get model configuration command
  String getConfigureCommand(String selectedSize) {
    final modelName = getFullModelName(selectedSize);
    return 'ollama show $modelName';
  }
}
