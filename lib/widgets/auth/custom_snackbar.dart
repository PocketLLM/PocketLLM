import 'package:flutter/material.dart';

/// Custom snackbar component based on the Figma design
class CustomSnackbar extends StatelessWidget {
  final String message;
  final SnackbarType type;
  final Duration duration;

  const CustomSnackbar({
    Key? key,
    required this.message,
    this.type = SnackbarType.info,
    this.duration = const Duration(seconds: 4),
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    // Determine background color based on type
    Color backgroundColor;
    Color textColor;
    IconData? icon;

    switch (type) {
      case SnackbarType.success:
        backgroundColor = colors.primary;
        textColor = colors.onPrimary;
        icon = Icons.check_circle_outline;
        break;
      case SnackbarType.error:
        backgroundColor = colors.error;
        textColor = colors.onError;
        icon = Icons.error_outline;
        break;
      case SnackbarType.info:
        backgroundColor = colors.secondary;
        textColor = colors.onSecondary;
        icon = Icons.info_outline;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, color: textColor, size: 20),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Text(
              message,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: textColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Show the snackbar
  static void show(BuildContext context, CustomSnackbar snackbar) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: snackbar,
        duration: snackbar.duration,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.all(16),
        padding: EdgeInsets.zero,
        backgroundColor: Colors.transparent,
      ),
    );
  }
}

enum SnackbarType { success, error, info }