import 'package:flutter/material.dart';

/// Stepper component based on the Figma design
class CustomStepper extends StatelessWidget {
  final int currentStep;
  final int maxSteps;

  const CustomStepper({
    Key? key,
    required this.currentStep,
    required this.maxSteps,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(maxSteps, (index) {
        final isCompleted = index < currentStep;
        final isCurrent = index == currentStep;
        
        Color backgroundColor;
        Color textColor;
        
        if (isCompleted) {
          backgroundColor = colors.primary;
          textColor = colors.onPrimary;
        } else if (isCurrent) {
          backgroundColor = colors.primary.withOpacity(0.12);
          textColor = colors.primary;
        } else {
          backgroundColor = colors.surfaceVariant;
          textColor = colors.onSurfaceVariant;
        }

        return Row(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: backgroundColor,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: isCompleted
                    ? const Icon(Icons.check, size: 16, color: Colors.white)
                    : Text(
                        '${index + 1}',
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: textColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
            if (index < maxSteps - 1) ...[
              const SizedBox(width: 8),
              Container(
                width: 24,
                height: 2,
                color: index < currentStep ? colors.primary : colors.surfaceVariant,
              ),
              const SizedBox(width: 8),
            ],
          ],
        );
      }),
    );
  }
}