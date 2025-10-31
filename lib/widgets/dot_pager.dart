import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../motion/effects.dart';
import '../motion/tokens.dart';
import '../theme/colors.dart';

class DotPager extends StatelessWidget {
  const DotPager({
    super.key,
    required this.controller,
    required this.count,
  });

  final PageController controller;
  final int count;

  double _progressForIndex(int index) {
    final page = controller.hasClients ? (controller.page ?? controller.initialPage.toDouble()) : controller.initialPage.toDouble();
    return (1 - (page - index).abs()).clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(count, (index) {
            final progress = _progressForIndex(index);
            final active = progress > 0.5;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: active ? AppColors.primary : AppColors.textSecondary.withOpacity(math.max(0.2, progress)),
                  borderRadius: BorderRadius.circular(99),
                ),
              ).dotActive(progress),
            );
          }),
        ).animate().fadeIn(duration: MotionDurations.medium);
      },
    );
  }
}
