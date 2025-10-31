import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../motion/effects.dart';
import '../motion/tokens.dart';
import '../providers/connect_sheet.dart';
import '../theme/colors.dart';
import '../theme/typography.dart';
import '../widgets/onboarding_illustration.dart';
import '../widgets/primary_button.dart';
import '../widgets/provider_chip.dart';
import '../widgets/secondary_button.dart';
import 'copy.dart';
import 'onboarding_state.dart';

class Screen2Providers extends HookConsumerWidget {
  const Screen2Providers({
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
    final providers = useMemoized(() => OB['s2_chips']!.split(','));
    final glowChip = useState<String?>(null);

    useEffect(() {
      if (glowChip.value != null) {
        final timer = Timer(MotionDurations.long, () => glowChip.value = null);
        return timer.cancel;
      }
      return null;
    }, [glowChip.value]);

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            OB['s2_title']!,
            style: AppTypography.textTheme.headlineLarge,
          ).onboardingTitle(reduceMotion: reduceMotion),
          const SizedBox(height: 16),
          Text(
            OB['s2_sub']!,
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
                Expanded(
                  child: GridView.builder(
                    itemCount: providers.length,
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 2.6,
                    ),
                    padding: EdgeInsets.zero,
                    physics: const BouncingScrollPhysics(parent: ClampingScrollPhysics()),
                    itemBuilder: (context, index) {
                      final provider = providers[index];
                      final hasKey = state.providerKeys.containsKey(provider.toLowerCase());
                      return ProviderChip(
                        label: provider,
                        selected: hasKey,
                        glow: glowChip.value == provider,
                        onTap: () async {
                          final result = await showProviderConnectSheet(
                            context: context,
                            provider: provider,
                            initialValue: state.providerKeys[provider.toLowerCase()] ?? '',
                          );
                          if (result != null) {
                            notifier.updateProviderKey(provider.toLowerCase(), result);
                            glowChip.value = provider;
                          }
                        },
                      ).animate(delay: MotionStaggers.short * index).fadeIn(duration: MotionDurations.medium);
                    },
                  ),
                ),
                const SizedBox(height: 24),
                OnboardingIllustration(
                  asset: 'assets/illustration/ob2.png',
                  reduceMotion: reduceMotion,
                  height: MediaQuery.of(context).size.height * 0.24,
                ).onboardingIllustration(
                  reduceMotion: reduceMotion,
                  delay: MotionStaggers.medium,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          PrimaryButton(
            label: OB['s2_cta']!,
            onPressed: () => controller.nextPage(
              duration: MotionDurations.medium,
              curve: MotionCurves.easeOutCubic,
            ),
          ).onboardingCta(
            reduceMotion: reduceMotion,
            delay: MotionStaggers.medium,
          ),
          const SizedBox(height: 16),
          SecondaryButton(
            label: OB['s2_later']!,
            onPressed: () => controller.nextPage(
              duration: MotionDurations.medium,
              curve: MotionCurves.easeOutCubic,
            ),
          ),
        ],
      ),
    );
  }
}
