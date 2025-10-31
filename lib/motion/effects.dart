import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../theme/colors.dart';
import 'tokens.dart';

extension AnimateEntrance on Widget {
  Widget onboardingTitle({required bool reduceMotion, Duration? delay}) {
    if (reduceMotion) {
      return animate().fadeIn(duration: MotionDurations.short, delay: delay);
    }
    return animate()
        .fadeIn(duration: MotionDurations.medium, delay: delay)
        .slide(begin: const Offset(0, 0.12), end: Offset.zero, curve: MotionCurves.easeOutCubic);
  }

  Widget onboardingSubtitle({required bool reduceMotion, Duration? delay}) {
    if (reduceMotion) {
      return animate().fadeIn(duration: MotionDurations.short, delay: delay);
    }
    return animate()
        .fadeIn(duration: MotionDurations.medium, delay: delay)
        .slide(begin: const Offset(0, 0.16), end: Offset.zero, curve: MotionCurves.easeOutCubic);
  }

  Widget onboardingIllustration({required bool reduceMotion, Duration? delay}) {
    if (reduceMotion) {
      return animate().fadeIn(duration: MotionDurations.short, delay: delay);
    }
    return animate()
        .fadeIn(duration: MotionDurations.long, delay: delay)
        .scale(begin: 0.96, end: 1.0, curve: MotionCurves.easeOutCubic);
  }

  Widget onboardingCta({required bool reduceMotion, Duration? delay}) {
    if (reduceMotion) {
      return animate().fadeIn(duration: MotionDurations.short, delay: delay);
    }
    return animate()
        .fadeIn(duration: MotionDurations.medium, delay: delay)
        .slide(begin: const Offset(0, 0.24), end: Offset.zero, curve: MotionCurves.emphasized);
  }
}

extension DotAnimate on Widget {
  Widget dotActive(double progress) {
    return animate()
        .scale(
          duration: MotionDurations.pager,
          begin: 1,
          end: 1 + 0.6 * progress,
          curve: MotionCurves.pager,
        )
        .tint(
          duration: MotionDurations.pager,
          curve: MotionCurves.pager,
          color: ColorTween(
            begin: AppColors.textSecondary,
            end: AppColors.primary,
          ),
        );
  }
}
