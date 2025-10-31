import 'package:flutter/material.dart';
import '../motion/tokens.dart';
import '../theme/colors.dart';
import '../theme/typography.dart';

class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.heroTag,
    this.loading = false,
    this.semanticsLabel,
  });

  final String label;
  final VoidCallback? onPressed;
  final Object? heroTag;
  final bool loading;
  final String? semanticsLabel;

  @override
  Widget build(BuildContext context) {
    final button = ElevatedButton(
      onPressed: loading ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textPrimary,
        minimumSize: const Size.fromHeight(56),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        textStyle: AppTypography.textTheme.labelLarge,
      ),
      child: AnimatedSwitcher(
        duration: MotionDurations.short,
        child: loading
            ? SizedBox(
                key: const ValueKey('loader'),
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation(AppColors.textPrimary),
                ),
              )
            : Text(
                label,
                key: ValueKey(label),
              ),
      ),
    );

    final semantics = Semantics(
      label: semanticsLabel ?? label,
      button: true,
      child: button,
    );

    if (heroTag != null) {
      return Hero(tag: heroTag!, child: semantics);
    }

    return semantics;
  }
}
