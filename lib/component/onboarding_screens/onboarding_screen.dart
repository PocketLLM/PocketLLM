import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../pages/auth/auth_flow_screen.dart';
import 'widgets/demo_chat_input.dart';
import 'widgets/model_selection.dart';
import 'widgets/onboarding_step.dart';
import 'widgets/provider_selection.dart' show ProviderOption;
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
  static const List<String> _illustrations = [
    'assets/illustrations/ob1.png',
    'assets/illustrations/ob2.png',
    'assets/illustrations/ob3.gif',
    'assets/illustrations/ob4.gif',
    'assets/illustrations/ob5.gif',
    'assets/illustrations/ob6.gif',
  ];
  final TextEditingController _demoChatController = TextEditingController();
  late final PageController _pageController;

  int _currentStep = 0;
  String? _selectedModelId;
  ThemeMode _themeMode = ThemeMode.system;
  Color _accentColor = const Color(0xFF6750A4);
  LayoutDensity _layoutDensity = LayoutDensity.comfortable;
  bool _isCompleting = false;
  bool _isTransitioning = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      for (final asset in _illustrations) {
        precacheImage(AssetImage(asset), context);
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _demoChatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: PageView.builder(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: _totalSteps,
        itemBuilder: (context, index) {
          final stepData = _buildStep(context, index);
          final isLastStep = index == _totalSteps - 1;

          return OnboardingStep(
            key: ValueKey('step-$index'),
            illustrationAsset: stepData.illustration,
            title: stepData.title,
            subtitle: stepData.subtitle,
            body: stepData.body,
            footer: stepData.footer,
            currentStep: _currentStep,
            totalSteps: _totalSteps,
            showPrevious: index > 0,
            isLastStep: isLastStep,
            onSkip: _isCompleting || _isTransitioning ? null : _skipOnboarding,
            onPrevious: index > 0 && !_isTransitioning ? () => _handlePreviousFrom(index) : null,
            onNext: _isCompleting || _isTransitioning
                ? null
                : () => _handleNextFrom(index, isLastStep: isLastStep),
          );
        },
      ),
    );
  }

  _OnboardingStepData _buildStep(BuildContext context, int step) {
    switch (step) {
      case 0:
        return const _OnboardingStepData(
          illustration: 'assets/illustrations/ob1.png',
          title: 'Welcome to PocketLLM',
          subtitle:
              'Experience privacy-first, multi-model AI chat—your conversations, your control.',
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'PocketLLM keeps your data on-device and helps you orchestrate multiple providers securely. Let’s personalize the experience in a few quick steps.',
              ),
            ],
          ),
        );
      case 1:
        return _OnboardingStepData(
          illustration: 'assets/illustrations/ob2.png',
          title: 'Mix and match providers',
          subtitle: 'PocketLLM plays nicely with multiple AI providers at once.',
          body: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Connect OpenAI, Anthropic, Azure OpenAI, Ollama, and more to build the perfect toolbox. '
                'Setups are optional during onboarding—add what you need when you are ready.',
              ),
              SizedBox(height: 20),
              Wrap(
                spacing: 12,
                runSpacing: 12,
              ),
            ],
          ),
          footer: Text(
            'Head to Settings → Providers anytime to securely add, edit, or remove API keys.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        );
      case 2:
        // Updated to remove dependency on _models field
        return const _OnboardingStepData(
          illustration: 'assets/illustrations/ob3.gif',
          title: 'Pick your favorite model',
          subtitle:
              'Choose a default model and preview it with a sample chat. You can change anytime!',
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'You can select a default model after onboarding. '
                'Go to Settings → Models to configure your AI models.',
              ),
              SizedBox(height: 20),
            ],
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
        // Updated to remove dependency on _models field
        final modelSummary = _selectedModelId == null
            ? 'Model selection pending'
            : 'Selected model: $_selectedModelId';

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
              'Here’s what you’ve personalized so far. Explore chat history, the model catalogue, or settings any time.',
          // body: Column(
          //   crossAxisAlignment: CrossAxisAlignment.start,
          //   children: [
          //     _SummaryTile(
          //       icon: Icons.smart_toy_outlined,
          //       title: 'Default model',
          //       description: modelSummary,
          //     ),
          //     const SizedBox(height: 12),
          //     _SummaryTile(
          //       icon: Icons.palette_outlined,
          //       title: 'Theme & layout',
          //       description: '$themeSummary · $layoutSummary',
          //     ),
          //     const SizedBox(height: 12),
          //     const _SummaryTile(
          //       icon: Icons.cloud_outlined,
          //       title: 'Providers',
          //       description: 'Add providers later from Settings → Providers when you\'re ready.',
          //     ),
          //     const SizedBox(height: 24),
          //     const Wrap(
          //       spacing: 12,
          //       runSpacing: 12,
          //       children: [
          //         _QuickLink(icon: Icons.history, label: 'Chat history'),
          //         _QuickLink(icon: Icons.grid_view, label: 'Model catalogue'),
          //         _QuickLink(icon: Icons.settings, label: 'Settings'),
          //       ],
          //     ),
          //   ],
          // ),
          footer: _isCompleting
              ? const Center(child: CircularProgressIndicator())
              : Text(
                  'You can revisit onboarding anytime from Settings → Profile.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
        );
    }
  }

  void _handleNextFrom(int index, {required bool isLastStep}) {
    // Removed model selection validation since we're not using the _models field
    if (isLastStep) {
      unawaited(_completeOnboarding());
      return;
    }

    unawaited(_animateToStep(index + 1));
  }

  void _handlePreviousFrom(int index) {
    if (index <= 0) return;
    unawaited(_animateToStep(index - 1));
  }

  Future<void> _animateToStep(int targetStep) async {
    if (_isTransitioning || targetStep == _currentStep) {
      return;
    }

    setState(() {
      _isTransitioning = true;
      _currentStep = targetStep.clamp(0, _totalSteps - 1);
    });

    if (!_pageController.hasClients) {
      _pageController.jumpToPage(_currentStep);
      if (mounted) {
        setState(() => _isTransitioning = false);
      }
      return;
    }

    try {
      await _pageController.animateToPage(
        _currentStep,
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOutCubic,
      );
    } finally {
      if (mounted) {
        setState(() => _isTransitioning = false);
      }
    }
  }

  Future<void> _skipOnboarding() async {
    await _completeOnboarding(skipped: true);
  }

  Future<void> _completeOnboarding({bool skipped = false}) async {
    if (_isCompleting) return;
    setState(() => _isCompleting = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('showHome', true);
      await prefs.remove('authSkipped');
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