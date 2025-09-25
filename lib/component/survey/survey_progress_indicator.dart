import 'package:flutter/material.dart';

class SurveyProgressIndicator extends StatelessWidget {
  final int totalSteps;
  final int currentStep;

  const SurveyProgressIndicator({
    super.key,
    required this.totalSteps,
    required this.currentStep,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(totalSteps, (index) {
        final stepNumber = index + 1;
        final isActive = index == currentStep;
        final isCompleted = index < currentStep;
        final Color backgroundColor;
        final Color textColor;

        if (isActive) {
          backgroundColor = theme.colorScheme.primary;
          textColor = Colors.white;
        } else if (isCompleted) {
          backgroundColor = theme.colorScheme.primary.withOpacity(0.12);
          textColor = theme.colorScheme.primary;
        } else {
          backgroundColor = Colors.grey.shade200;
          textColor = Colors.grey.shade500;
        }

        return Container(
          width: 32,
          height: 32,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: backgroundColor,
            shape: BoxShape.circle,
          ),
          child: Text(
            '$stepNumber',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: textColor,
              fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
            ),
          ),
        );
      }),
    );
  }
}
