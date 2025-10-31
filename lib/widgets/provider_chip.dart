import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../motion/tokens.dart';
import '../theme/colors.dart';
import '../theme/typography.dart';

class ProviderChip extends StatelessWidget {
  const ProviderChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.glow = false,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final bool glow;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: label,
      button: true,
      selected: selected,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: MotionDurations.medium,
          curve: MotionCurves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          decoration: BoxDecoration(
            color: selected ? AppColors.primary.withOpacity(0.12) : AppColors.surface,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: selected ? AppColors.primary : AppColors.stroke,
              width: 1.5,
            ),
            boxShadow: glow
                ? [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.28),
                      blurRadius: 12,
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  label,
                  style: AppTypography.textTheme.bodyLarge?.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              AnimatedOpacity(
                opacity: selected ? 1 : 0,
                duration: MotionDurations.short,
                child: const Icon(Icons.check_rounded, color: AppColors.primary),
              ),
            ],
          ),
        ).animate(target: selected ? 1 : 0).scale(
              duration: MotionDurations.short,
              begin: const Offset(1, 1),
              end: const Offset(1.02, 1.02),
              curve: MotionCurves.easeOutCubic,
            ),
      ),
    );
  }
}
