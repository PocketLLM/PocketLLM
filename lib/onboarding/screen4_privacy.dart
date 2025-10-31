import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../motion/effects.dart';
import '../motion/tokens.dart';
import '../theme/colors.dart';
import '../theme/typography.dart';
import '../widgets/checkbox_row.dart';
import '../widgets/onboarding_illustration.dart';
import '../widgets/primary_button.dart';
import 'copy.dart';
import 'onboarding_state.dart';

class Screen4Privacy extends ConsumerWidget {
  const Screen4Privacy({
    super.key,
    required this.reduceMotion,
    required this.controller,
    required this.state,
    required this.notifier,
  });

  final bool reduceMotion;
  final PageController controller;
  final OnboardingModel state;
  final OnboardingController notifier;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final checks = OB['s4_checks']!.split(',');
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            OB['s4_title']!,
            style: AppTypography.textTheme.headlineLarge,
          ).onboardingTitle(reduceMotion: reduceMotion),
          const SizedBox(height: 16),
          Text(
            OB['s4_sub']!,
            style: AppTypography.textTheme.bodyLarge?.copyWith(
              color: AppColors.textSecondary,
            ),
          ).onboardingSubtitle(
            reduceMotion: reduceMotion,
            delay: MotionStaggers.short,
          ),
          const SizedBox(height: 24),
          Expanded(
            child: Column(
              children: [
                CheckboxRow(
                  label: checks[0],
                  value: state.localHistoryOnly,
                  onChanged: notifier.toggleLocalHistory,
                ).animate(delay: MotionStaggers.short).scale(
                      begin: 0.96,
                      end: 1.05,
                      duration: MotionDurations.medium,
                      curve: MotionCurves.emphasized,
                    ),
                const SizedBox(height: 12),
                CheckboxRow(
                  label: checks[1],
                  value: state.analytics,
                  onChanged: notifier.toggleAnalytics,
                ).animate(delay: MotionStaggers.short * 2).scale(
                      begin: 0.96,
                      end: 1.05,
                      duration: MotionDurations.medium,
                      curve: MotionCurves.emphasized,
                    ),
                const SizedBox(height: 12),
                CheckboxRow(
                  label: checks[2],
                  value: state.localVectorCache,
                  onChanged: notifier.toggleLocalVector,
                ).animate(delay: MotionStaggers.short * 3).scale(
                      begin: 0.96,
                      end: 1.05,
                      duration: MotionDurations.medium,
                      curve: MotionCurves.emphasized,
                    ),
                const Spacer(),
                OnboardingIllustration(
                  asset: 'assets/illustrations/ob4.gif',
                  reduceMotion: reduceMotion,
                  height: MediaQuery.of(context).size.height * 0.28,
                ).onboardingIllustration(
                  reduceMotion: reduceMotion,
                  delay: MotionStaggers.medium,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          PrimaryButton(
            label: OB['s4_cta']!,
            onPressed: () => controller.nextPage(
              duration: MotionDurations.medium,
              curve: MotionCurves.easeOutCubic,
            ),
          ).onboardingCta(
            reduceMotion: reduceMotion,
            delay: MotionStaggers.medium,
          ),
        ],
      ),
    );
  }
}
