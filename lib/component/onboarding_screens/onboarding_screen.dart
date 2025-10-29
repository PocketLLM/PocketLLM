import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../pages/auth/auth_flow_screen.dart';
import 'widgets/demo_chat_input.dart';
import 'widgets/model_selection.dart';
import 'widgets/onboarding_step.dart';
import 'widgets/provider_selection.dart';
import 'widgets/theme_customization.dart';

/// Centralized onboarding flow that guides the user through configuring the
/// PocketLLM experience. The flow now spans six steps and persists onboarding
/// completion to avoid repeat prompts.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({Key? key}) : super(key: key);

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  static const _totalSteps = 6;
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  final TextEditingController _demoChatController = TextEditingController();

  final List<ProviderOption> _providers = const [
    ProviderOption(
      id: 'openai',
      name: 'OpenAI',
      description: 'GPT-4o, GPT-3.5, and vision-ready assistants.',
      icon: Icons.auto_awesome,
    ),
    ProviderOption(
      id: 'anthropic',
      name: 'Anthropic',
      description: 'Claude models optimized for safe, long-form dialog.',
      icon: Icons.psychology_alt,
    ),
    ProviderOption(
      id: 'azure',
      name: 'Azure OpenAI',
      description: 'Enterprise compliant Azure-hosted OpenAI access.',
      icon: Icons.cloud_outlined,
    ),
    ProviderOption(
      id: 'ollama',
      name: 'Ollama',
      description: 'Run open models locally without sharing data.',
      icon: Icons.memory,
    ),
  ];

  late final List<ModelOption> _models;

  final Set<String> _connectedProviders = <String>{};
  final Map<String, String> _apiKeys = <String, String>{};

  int _currentStep = 0;
  String? _selectedModelId;
  ThemeMode _themeMode = ThemeMode.system;
  Color _accentColor = const Color(0xFF6750A4);
  LayoutDensity _layoutDensity = LayoutDensity.comfortable;
  bool _isCompleting = false;

  @override
  void initState() {
    super.initState();
    _models = [
      const ModelOption(
        id: 'gpt-4o-mini',
        name: 'GPT-4o mini',
        providerId: 'openai',
        description: 'Fast, multimodal model for everyday chats.',
        healthLabel: 'Stable',
        icon: Icons.auto_fix_high,
      ),
      const ModelOption(
        id: 'claude-3-haiku',
        name: 'Claude 3 Haiku',
        providerId: 'anthropic',
        description: 'Concise, friendly, and safe assistant replies.',
        healthLabel: 'Optimal',
        icon: Icons.coffee_maker,
      ),
      const ModelOption(
        id: 'gpt-4-turbo',
        name: 'GPT-4 Turbo',
        providerId: 'azure',
        description: 'Azure managed GPT-4 with enterprise guardrails.',
        healthLabel: 'Healthy',
        icon: Icons.business_center,
      ),
      const ModelOption(
        id: 'llama3-8b',
        name: 'Llama 3 8B',
        providerId: 'ollama',
        description: 'Local-first open model with strong reasoning.',
        healthLabel: 'Community',
        icon: Icons.pets,
      ),
    ];

  }

  @override
  void dispose() {
    _demoChatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final stepData = _buildStep();
    final isLastStep = _currentStep == _totalSteps - 1;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 400),
        transitionBuilder: (child, animation) => FadeTransition(
          opacity: CurvedAnimation(parent: animation, curve: Curves.easeInOut),
          child: child,
        ),
        child: OnboardingStep(
          key: ValueKey(_currentStep),
          illustrationAsset: stepData.illustration,
          title: stepData.title,
          subtitle: stepData.subtitle,
          body: stepData.body,
          footer: stepData.footer,
          currentStep: _currentStep,
          totalSteps: _totalSteps,
          showPrevious: _currentStep > 0,
          isLastStep: isLastStep,
          onSkip: _isCompleting ? null : _skipOnboarding,
          onPrevious: _currentStep > 0 ? _handlePrevious : null,
          onNext: _isCompleting ? null : _handleNext,
        ),
      ),
    );
  }

  _OnboardingStepData _buildStep() {
    switch (_currentStep) {
      case 0:
        return _OnboardingStepData(
          illustration: 'assets/illustrations/ob1.png',
          title: 'Welcome to PocketLLM',
          subtitle:
              'Experience privacy-first, multi-model AI chat—your conversations, your control.',
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                'PocketLLM keeps your data on-device and helps you orchestrate multiple providers securely. Let’s personalize the experience in a few quick steps.',
              ),
            ],
          ),
        );
      case 1:
        return _OnboardingStepData(
          illustration: 'assets/illustrations/ob2.png',
          title: 'Connect your AI providers',
          subtitle:
              'Securely add your API keys—PocketLLM never stores or shares your keys outside your device.',
          body: ProviderSelection(
            options: _providers,
            connectedProviders: _connectedProviders,
            apiKeys: _apiKeys,
            onRequestApiKey: _showApiKeyDialog,
            onRemoveProvider: _removeProvider,
          ),
          footer: Text(
            'Tap a provider to connect or disconnect. Keys are encrypted locally using the system keystore.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        );
      case 2:
        return _OnboardingStepData(
          illustration: 'assets/illustrations/ob3.gif',
          title: 'Pick your favorite model',
          subtitle:
              'Choose a default model and preview it with a sample chat. You can change anytime!',
          body: ModelSelection(
            models: _models,
            selectedModelId: _selectedModelId,
            onSelectModel: (model) {
              setState(() => _selectedModelId = model.id);
            },
            onPreview: _showModelPreview,
          ),
        );
      case 3:
        return _OnboardingStepData(
          illustration: 'assets/illustrations/ob4.gif',
          title: 'Make it yours!',
          subtitle:
              'Choose a theme, chat layout, and accessibility options for your best experience.',
          body: ThemeCustomization(
            themeMode: _themeMode,
            onThemeModeChanged: (mode) => setState(() => _themeMode = mode),
            accentColor: _accentColor,
            onAccentChanged: (color) => setState(() => _accentColor = color),
            layoutDensity: _layoutDensity,
            onLayoutChanged: (density) => setState(() => _layoutDensity = density),
          ),
        );
      case 4:
        return _OnboardingStepData(
          illustration: 'assets/illustrations/ob5.gif',
          title: 'Say hello to your new AI assistant!',
          subtitle:
              'Try your first message below. Need inspiration? Use these tips.',
          body: DemoChatInput(
            controller: _demoChatController,
            onSuggestionSelected: (value) {
              _demoChatController.text = value;
              _demoChatController.selection = TextSelection.collapsed(
                offset: value.length,
              );
            },
            onSend: () {
              final message = _demoChatController.text.trim();
              if (message.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Try typing a quick hello to get started.')),
                );
                return;
              }

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Your assistant is ready for: "$message"'),
                ),
              );
            },
          ),
        );
      case 5:
      default:
        final providerSummary = _connectedProviders.isEmpty
            ? 'No providers connected yet'
            : _connectedProviders
                .map(
                  (id) => _providers.firstWhere((option) => option.id == id).name,
                )
                .join(', ');

        final modelSummary = _selectedModelId == null
            ? 'Model selection pending'
            : _models.firstWhere((model) => model.id == _selectedModelId!).name;

        final themeSummary = switch (_themeMode) {
          ThemeMode.dark => 'Dark mode',
          ThemeMode.light => 'Light mode',
          ThemeMode.system => 'Match system',
        };

        final layoutSummary =
            _layoutDensity == LayoutDensity.compact ? 'Compact bubbles' : 'Comfortable spacing';

        return _OnboardingStepData(
          illustration: 'assets/illustrations/ob6.gif',
          title: 'All set!',
          subtitle:
              'Here’s what you’ve enabled: Provider X, Model Y, Theme Z. Explore chat history, model catalogue, or settings any time.',
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SummaryTile(
                icon: Icons.cloud_done,
                title: 'Providers',
                description: providerSummary,
              ),
              const SizedBox(height: 12),
              _SummaryTile(
                icon: Icons.smart_toy_outlined,
                title: 'Default model',
                description: modelSummary,
              ),
              const SizedBox(height: 12),
              _SummaryTile(
                icon: Icons.palette_outlined,
                title: 'Theme & layout',
                description: '$themeSummary · $layoutSummary',
              ),
              const SizedBox(height: 24),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: const [
                  _QuickLink(icon: Icons.history, label: 'Chat history'),
                  _QuickLink(icon: Icons.grid_view, label: 'Model catalogue'),
                  _QuickLink(icon: Icons.settings, label: 'Settings'),
                ],
              ),
            ],
          ),
          footer: _isCompleting
              ? const Center(child: CircularProgressIndicator())
              : Text(
                  'You can revisit onboarding anytime from Settings → Profile.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
        );
    }
  }

  void _handleNext() {
    switch (_currentStep) {
      case 1:
        if (_connectedProviders.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Connect at least one provider to continue.')),
          );
          return;
        }
        break;
      case 2:
        if (_selectedModelId == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Choose a default model to continue.')),
          );
          return;
        }
        break;
      case 5:
        unawaited(_completeOnboarding());
        return;
    }

    setState(() {
      _currentStep = (_currentStep + 1).clamp(0, _totalSteps - 1);
    });
  }

  void _handlePrevious() {
    setState(() {
      _currentStep = (_currentStep - 1).clamp(0, _totalSteps - 1);
    });
  }

  Future<void> _skipOnboarding() async {
    await _completeOnboarding(skipped: true);
  }

  Future<void> _showApiKeyDialog(ProviderOption option) async {
    final formKey = GlobalKey<FormState>();
    final controller = TextEditingController(text: _apiKeys[option.id] ?? '');
    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Add ${option.name} key'),
          content: Form(
            key: formKey,
            child: TextFormField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: 'API Key',
                hintText: 'sk-... or similar',
              ),
              obscureText: true,
              validator: (value) {
                final text = value?.trim() ?? '';
                if (text.isEmpty) {
                  return 'Enter your API key to continue.';
                }
                if (text.length < 8) {
                  return 'That key looks too short.';
                }
                return null;
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                if (formKey.currentState?.validate() ?? false) {
                  Navigator.of(context).pop(true);
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    if (result != true) {
      controller.dispose();
      return;
    }

    final value = controller.text.trim();
    controller.dispose();

    await _secureStorage.write(
      key: 'provider_api_key_${option.id}',
      value: value,
      aOptions: const AndroidOptions(encryptedSharedPreferences: true),
      iOptions: const IOSOptions(accessibility: IOSAccessibility.first_unlock_this_device_only),
    );

    setState(() {
      _apiKeys[option.id] = value;
      _connectedProviders.add(option.id);
    });

    if (_selectedModelId == null) {
      final firstModel = _models.firstWhere(
        (model) => model.providerId == option.id,
        orElse: () => _models.first,
      );
      setState(() => _selectedModelId = firstModel.id);
    }
  }

  Future<void> _removeProvider(ProviderOption option) async {
    await _secureStorage.delete(
      key: 'provider_api_key_${option.id}',
      aOptions: const AndroidOptions(encryptedSharedPreferences: true),
      iOptions: const IOSOptions(
        accessibility: IOSAccessibility.first_unlock_this_device_only,
      ),
    );
    setState(() {
      _apiKeys.remove(option.id);
      _connectedProviders.remove(option.id);
      if (_selectedModelId != null) {
        final selectedModel = _models.firstWhere(
          (model) => model.id == _selectedModelId!,
          orElse: () => _models.first,
        );
        if (selectedModel.providerId == option.id) {
          _selectedModelId = null;
        }
      }
    });
  }

  Future<void> _showModelPreview(ModelOption model) async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(
                  backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.15),
                  child: Icon(model.icon, color: Theme.of(context).colorScheme.primary),
                ),
                title: Text(model.name),
                subtitle: Text(model.description),
              ),
              const SizedBox(height: 12),
              const Text(
                'Sample interaction',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceVariant,
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: const EdgeInsets.all(16),
                child: const Text(
                  'User: “Give me three creative ice-breaker questions for a team meeting.”\n\n'
                  'Model: “1. If you could instantly master any skill, what would it be and why?\n'
                  '2. What is the most surprising fact you learned recently?\n'
                  '3. If our team had a theme song, what should it be?”',
                ),
              ),
              const SizedBox(height: 24),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton(
                  onPressed: () {
                    setState(() => _selectedModelId = model.id);
                    Navigator.of(context).pop();
                  },
                  child: const Text('Use this model'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _completeOnboarding({bool skipped = false}) async {
    if (_isCompleting) return;
    setState(() => _isCompleting = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('showHome', true);
      await prefs.remove('authSkipped');
      await prefs.setStringList('onboarding.providers', _connectedProviders.toList());
      if (_selectedModelId != null) {
        await prefs.setString('onboarding.defaultModel', _selectedModelId!);
      }
      await prefs.setString('onboarding.themeMode', _themeMode.name);
      await prefs.setString('onboarding.layoutDensity', _layoutDensity.name);
      await prefs.setInt('onboarding.accentColor', _accentColor.value);
      await prefs.setBool('onboarding.skipped', skipped);

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const AuthFlowScreen()),
      );
    } catch (error, stackTrace) {
      // Provide quick feedback and allow retry.
      debugPrint('Failed to complete onboarding: $error\n$stackTrace');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('We could not save your preferences. Please try again.'),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isCompleting = false);
      }
    }
  }
}

class _OnboardingStepData {
  const _OnboardingStepData({
    required this.illustration,
    required this.title,
    required this.subtitle,
    this.body,
    this.footer,
  });

  final String illustration;
  final String title;
  final String subtitle;
  final Widget? body;
  final Widget? footer;
}

class _SummaryTile extends StatelessWidget {
  const _SummaryTile({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.surfaceVariant,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: theme.colorScheme.primary.withOpacity(0.15),
              child: Icon(icon, color: theme.colorScheme.primary),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(description, style: theme.textTheme.bodyMedium),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickLink extends StatelessWidget {
  const _QuickLink({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return FilledButton.tonalIcon(
      onPressed: () {},
      icon: Icon(icon),
      label: Text(label),
    );
  }
}
