import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Reusable card-based layout that renders each onboarding step with
/// consistent spacing, typography, and navigation controls.
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
        padding: const EdgeInsets.all(24),
        child: Column(
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
            Expanded(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 560),
                  child: Card(
                    clipBehavior: Clip.antiAlias,
                    elevation: 8,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        return SingleChildScrollView(
                          padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(24),
                                child: Container(
                                  color: theme.colorScheme.surfaceVariant,
                                  padding: const EdgeInsets.all(16),
                                  child: Image.asset(
                                    illustrationAsset,
                                    fit: BoxFit.contain,
                                    height: constraints.maxWidth > 420 ? 260 : 200,
                                    semanticLabel: title,
                                  ),
                                ),
                              ),
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
                                body!,
                              ],
                              if (footer != null) ...[
                                const SizedBox(height: 24),
                                footer!,
                              ],
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            _ProgressDots(
              currentStep: currentStep,
              totalSteps: totalSteps,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: 16),
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
        return AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          height: 10,
          width: isActive ? 24 : 10,
          decoration: BoxDecoration(
            color: isActive ? color : color.withOpacity(0.25),
            borderRadius: BorderRadius.circular(20),
          ),
        );
      }),
    );
  }
}
