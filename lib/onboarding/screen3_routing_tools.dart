import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../motion/effects.dart';
import '../motion/tokens.dart';
import '../theme/colors.dart';
import '../theme/typography.dart';
import '../widgets/onboarding_illustration.dart';
import '../widgets/primary_button.dart';
import '../widgets/toggle_row.dart';
import 'copy.dart';
import 'onboarding_state.dart';

class Screen3RoutingTools extends ConsumerWidget {
  const Screen3RoutingTools({
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
    final toggles = OB['s3_toggles']!.split(',');
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            OB['s3_title']!,
            style: AppTypography.textTheme.headlineLarge,
          ).onboardingTitle(reduceMotion: reduceMotion),
          const SizedBox(height: 16),
          Text(
            OB['s3_sub']!,
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
                ToggleRow(
                  label: toggles[0],
                  value: state.smartRouting,
                  onChanged: notifier.toggleSmartRouting,
                ).animate(delay: MotionStaggers.short).fadeIn(duration: MotionDurations.medium),
                const SizedBox(height: 12),
                ToggleRow(
                  label: toggles[1],
                  value: state.toolUse,
                  onChanged: notifier.toggleToolUse,
                ).animate(delay: MotionStaggers.short * 2).fadeIn(duration: MotionDurations.medium),
                const SizedBox(height: 12),
                ToggleRow(
                  label: toggles[2],
                  value: state.memory,
                  onChanged: notifier.toggleMemory,
                ).animate(delay: MotionStaggers.short * 3).fadeIn(duration: MotionDurations.medium),
                const Spacer(),
                OnboardingIllustration(
                  asset: 'assets/illustrations/ob3.gif',
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
            label: OB['s3_cta']!,
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
