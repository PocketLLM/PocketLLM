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
import 'onboarding_state.dart';

class Screen1Welcome extends HookConsumerWidget {
  const Screen1Welcome({
    super.key,
    required this.reduceMotion,
    required this.pageController,
  });

  final bool reduceMotion;
  final PageController pageController;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final parallax = useState<double>(0.0);

    useEffect(() {
      void listener() {
        final page = pageController.hasClients ? (pageController.page ?? 0) : 0;
        parallax.value = page;
      }

      pageController.addListener(listener);
      return () => pageController.removeListener(listener);
    }, [pageController]);

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: AnimatedBuilder(
              animation: pageController,
              builder: (context, _) {
                final delta = reduceMotion ? 0.0 : (parallax.value) * -24;
                final imageDelta = reduceMotion ? 0.0 : (parallax.value) * -16;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Transform.translate(
                      offset: Offset(delta, 0),
                      child: Text(
                        OB['s1_title']!,
                        style: AppTypography.textTheme.headlineLarge,
                      ).onboardingTitle(reduceMotion: reduceMotion),
                    ),
                    const SizedBox(height: 16),
                    Transform.translate(
                      offset: Offset(delta * 0.8, 0),
                      child: Text(
                        OB['s1_sub']!,
                        style: AppTypography.textTheme.bodyLarge?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ).onboardingSubtitle(
                        reduceMotion: reduceMotion,
                        delay: MotionStaggers.short,
                      ),
                    ),
                    const Spacer(),
                    Transform.translate(
                      offset: Offset(imageDelta, 0),
                      child: OnboardingIllustration(
                        asset: 'assets/illustration/ob1.png',
                        reduceMotion: reduceMotion,
                        height: MediaQuery.of(context).size.height * 0.32,
                      ).onboardingIllustration(
                        reduceMotion: reduceMotion,
                        delay: MotionStaggers.medium,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: PrimaryButton(
                  label: OB['s1_cta']!,
                  onPressed: () => pageController.nextPage(
                    duration: MotionDurations.medium,
                    curve: MotionCurves.easeOutCubic,
                  ),
                  semanticsLabel: OB['s1_cta'],
                ).onboardingCta(
                  reduceMotion: reduceMotion,
                  delay: MotionStaggers.medium,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SecondaryButton(
            label: OB['s1_skip']!,
            onPressed: () {
              ref.read(onboardingControllerProvider.notifier).complete();
              pageController.animateToPage(
                5,
                duration: MotionDurations.long,
                curve: MotionCurves.easeInOutCubic,
              );
            },
          ),
        ],
      ),
    );
  }
}
