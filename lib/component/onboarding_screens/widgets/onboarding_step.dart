import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Reusable layout that renders each onboarding step with consistent spacing,
/// typography, and navigation controls. The content now sits directly on the
/// page without being wrapped in decorative containers so the experience feels
/// lighter and faster.
class OnboardingStep extends StatelessWidget {
  const OnboardingStep({
    required this.illustrationAsset,
    required this.title,
    required this.subtitle,
    required this.currentStep,
    required this.totalSteps,
    this.body,
    this.footer,
    this.onSkip,
    this.onNext,
    this.onPrevious,
    this.showPrevious = false,
    this.isLastStep = false,
    Key? key,
  }) : super(key: key);

  final String illustrationAsset;
  final String title;
  final String subtitle;
  final Widget? body;
  final Widget? footer;
  final VoidCallback? onSkip;
  final VoidCallback? onNext;
  final VoidCallback? onPrevious;
  final bool showPrevious;
  final bool isLastStep;
  final int currentStep;
  final int totalSteps;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed: onSkip,
                child: Text(
                  'Skip',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.7),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final maxContentWidth = constraints.maxWidth >= 720 ? 640.0 : constraints.maxWidth;

                  return Align(
                    alignment: Alignment.topCenter,
                    child: AnimatedSize(
                      duration: const Duration(milliseconds: 350),
                      curve: Curves.easeInOut,
                      child: ConstrainedBox(
                        constraints: BoxConstraints(maxWidth: maxContentWidth),
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 300),
                            switchInCurve: Curves.easeInOut,
                            switchOutCurve: Curves.easeInOut,
                            child: Column(
                              key: ValueKey(title),
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _Illustration(illustrationAsset: illustrationAsset, title: title),
                                const SizedBox(height: 28),
                                Text(
                                  title,
                                  style: GoogleFonts.plusJakartaSans(
                                    textStyle: theme.textTheme.headlineMedium,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: -0.3,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  subtitle,
                                  style: GoogleFonts.inter(
                                    textStyle: theme.textTheme.bodyLarge,
                                    height: 1.4,
                                    color: theme.colorScheme.onSurface.withOpacity(0.78),
                                  ),
                                ),
                                if (body != null) ...[
                                  const SizedBox(height: 24),
                                  AnimatedSwitcher(
                                    duration: const Duration(milliseconds: 300),
                                    switchInCurve: Curves.easeOut,
                                    switchOutCurve: Curves.easeIn,
                                    child: KeyedSubtree(
                                      key: ValueKey('body-$title'),
                                      child: body!,
                                    ),
                                  ),
                                ],
                                if (footer != null) ...[
                                  const SizedBox(height: 24),
                                  AnimatedSwitcher(
                                    duration: const Duration(milliseconds: 300),
                                    child: KeyedSubtree(
                                      key: ValueKey('footer-$title'),
                                      child: footer!,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 24),
            _ProgressDots(
              currentStep: currentStep,
              totalSteps: totalSteps,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                if (showPrevious)
                  OutlinedButton(
                    onPressed: onPrevious,
                    child: const Text('Previous'),
                  )
                else
                  const SizedBox(width: 100),
                const Spacer(),
                FilledButton(
                  onPressed: onNext,
                  child: Text(isLastStep ? 'Finish' : 'Next'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Illustration extends StatelessWidget {
  const _Illustration({
    required this.illustrationAsset,
    required this.title,
  });

  final String illustrationAsset;
  final String title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isWide = MediaQuery.of(context).size.width > 480;
    final targetHeight = isWide ? 260.0 : 200.0;

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 400),
      switchInCurve: Curves.easeOut,
      switchOutCurve: Curves.easeIn,
      child: ClipRRect(
        key: ValueKey(illustrationAsset),
        borderRadius: BorderRadius.circular(28),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceVariant,
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Image.asset(
              illustrationAsset,
              fit: BoxFit.contain,
              height: targetHeight,
              semanticLabel: title,
            ),
          ),
        ),
      ),
    );
  }
}

class _ProgressDots extends StatelessWidget {
  const _ProgressDots({
    required this.currentStep,
    required this.totalSteps,
    required this.color,
  });

  final int currentStep;
  final int totalSteps;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(totalSteps, (index) {
        final bool isActive = index == currentStep;
        return AnimatedOpacity(
          duration: const Duration(milliseconds: 250),
          opacity: isActive ? 1 : 0.45,
          child: AnimatedScale(
            duration: const Duration(milliseconds: 250),
            scale: isActive ? 1.05 : 0.9,
            curve: Curves.easeInOut,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              height: 10,
              width: isActive ? 28 : 10,
              decoration: BoxDecoration(
                color: isActive ? color : color.withOpacity(0.25),
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
        );
      }),
    );
  }
}
