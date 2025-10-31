import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../motion/effects.dart';
import '../motion/tokens.dart';
import '../theme/colors.dart';
import '../theme/typography.dart';
import '../widgets/onboarding_illustration.dart';
import '../widgets/primary_button.dart';
import '../widgets/secondary_button.dart';
import 'copy.dart';

class Screen5Permissions extends HookConsumerWidget {
  const Screen5Permissions({
    super.key,
    required this.reduceMotion,
    required this.controller,
  });

  final bool reduceMotion;
  final PageController controller;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final enabling = useState(false);
    final shimmer = useState(false);
    final shake = useState(0);

    Future<void> handleEnable() async {
      if (enabling.value) return;
      enabling.value = true;
      shimmer.value = true;
      await Future<void>.delayed(const Duration(seconds: 2));
      shimmer.value = false;
      enabling.value = false;
      controller.nextPage(
        duration: MotionDurations.medium,
        curve: MotionCurves.easeOutCubic,
      );
    }

    void handleSkip() {
      shake.value++;
      controller.nextPage(
        duration: MotionDurations.medium,
        curve: MotionCurves.easeOutCubic,
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            OB['s5_title']!,
            style: AppTypography.textTheme.headlineLarge,
          ).onboardingTitle(reduceMotion: reduceMotion),
          const SizedBox(height: 16),
          Text(
            OB['s5_sub']!,
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
                OnboardingIllustration(
                  asset: 'assets/illustration/ob5.gif',
                  reduceMotion: reduceMotion,
                  height: MediaQuery.of(context).size.height * 0.3,
                ).onboardingIllustration(
                  reduceMotion: reduceMotion,
                  delay: MotionStaggers.medium,
                ),
                const SizedBox(height: 24),
                AnimatedSwitcher(
                  duration: MotionDurations.medium,
                  child: shimmer.value
                      ? Animate(
                          key: const ValueKey('progress'),
                          onPlay: (controller) => controller.repeat(),
                          effects: const [
                            ShimmerEffect(duration: Duration(milliseconds: 900)),
                          ],
                          child: Container(
                            height: 6,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(999),
                              gradient: LinearGradient(
                                colors: [
                                  AppColors.primary.withOpacity(0.2),
                                  AppColors.primary,
                                  AppColors.primary.withOpacity(0.2),
                                ],
                              ),
                            ),
                          ),
                        )
                      : const SizedBox(height: 6),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Animate(
            key: ValueKey(shake.value),
            effects: reduceMotion
                ? [const FadeEffect(duration: MotionDurations.short)]
                : [
                    const ShakeEffect(
                      duration: Duration(milliseconds: 360),
                      hz: 4,
                      offset: Offset(8, 0),
                    ),
                  ],
            child: PrimaryButton(
              label: OB['s5_cta']!,
              onPressed: enabling.value ? null : handleEnable,
              loading: enabling.value,
            ).onboardingCta(
              reduceMotion: reduceMotion,
              delay: MotionStaggers.medium,
            ),
          ),
          const SizedBox(height: 16),
          SecondaryButton(
            label: OB['s5_skip']!,
            onPressed: handleSkip,
          ),
        ],
      ),
    );
  }
}
