import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../motion/effects.dart';
import '../motion/tokens.dart';
import '../theme/colors.dart';
import '../theme/typography.dart';
import '../widgets/onboarding_illustration.dart';
import '../widgets/primary_button.dart';
import '../widgets/secondary_button.dart';
import 'copy.dart';
import 'onboarding_state.dart';

class Screen6Done extends HookConsumerWidget {
  const Screen6Done({
    super.key,
    required this.reduceMotion,
    required this.notifier,
  });

  final bool reduceMotion;
  final OnboardingController notifier;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final overlayVisible = useState(false);

    useEffect(() {
      if (reduceMotion) return null;
      final timer = Timer(const Duration(seconds: 3), () {
        if (!overlayVisible.value) {
          overlayVisible.value = true;
        }
      });
      return timer.cancel;
    }, [reduceMotion]);

    void finish() {
      notifier.complete();
      context.go('/home');
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            OB['s6_title']!,
            style: AppTypography.textTheme.headlineLarge,
          ).onboardingTitle(reduceMotion: reduceMotion),
          const SizedBox(height: 16),
          Text(
            OB['s6_sub']!,
            style: AppTypography.textTheme.bodyLarge?.copyWith(
              color: AppColors.textSecondary,
            ),
          ).onboardingSubtitle(
            reduceMotion: reduceMotion,
            delay: MotionStaggers.short,
          ),
          const SizedBox(height: 24),
          Expanded(
            child: Stack(
              alignment: Alignment.center,
              children: [
                OnboardingIllustration(
                  asset: 'assets/illustrations/ob6.gif',
                  reduceMotion: reduceMotion,
                  height: MediaQuery.of(context).size.height * 0.32,
                ).onboardingIllustration(
                  reduceMotion: reduceMotion,
                  delay: MotionStaggers.medium,
                ),
                if (!reduceMotion)
                  AnimatedOpacity(
                    opacity: overlayVisible.value ? 1 : 0,
                    duration: MotionDurations.medium,
                    child: OnboardingIllustration(
                      asset: 'assets/illustrations/ob6.gif',
                      reduceMotion: true,
                      height: MediaQuery.of(context).size.height * 0.32,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          PrimaryButton(
            label: OB['s6_cta']!,
            onPressed: finish,
            heroTag: 'start_chatting_cta',
          ).onboardingCta(
            reduceMotion: reduceMotion,
            delay: MotionStaggers.medium,
          ),
          const SizedBox(height: 16),
          SecondaryButton(
            label: OB['s6_alt']!,
            onPressed: () {
              notifier.complete();
              // TODO: Implement import flow route.
              context.go('/home');
            },
          ),
        ],
      ),
    );
  }
}
