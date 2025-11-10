import 'package:flutter/material.dart';

/// Custom button component based on the Figma design
/// Supports filled, tonal, and text variants with different sizes
class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final ButtonVariant variant;
  final ButtonSize size;
  final bool enabled;
  final IconData? icon;

  const CustomButton({
    Key? key,
    required this.text,
    required this.onPressed,
    this.variant = ButtonVariant.filled,
    this.size = ButtonSize.medium,
    this.enabled = true,
    this.icon,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    // Determine button style based on variant
    Color backgroundColor;
    Color foregroundColor;
    BorderSide? side;

    switch (variant) {
      case ButtonVariant.filled:
        backgroundColor = enabled ? colors.primary : colors.onSurface.withOpacity(0.12);
        foregroundColor = enabled ? colors.onPrimary : colors.onSurface.withOpacity(0.38);
        side = null;
        break;
      case ButtonVariant.tonal:
        backgroundColor = enabled 
            ? colors.primary.withOpacity(0.12) 
            : colors.onSurface.withOpacity(0.12);
        foregroundColor = enabled ? colors.primary : colors.onSurface.withOpacity(0.38);
        side = null;
        break;
      case ButtonVariant.text:
        backgroundColor = Colors.transparent;
        foregroundColor = enabled ? colors.primary : colors.onSurface.withOpacity(0.38);
        side = null;
        break;
    }

    // Determine padding and text style based on size
    EdgeInsets padding;
    TextStyle textStyle;

    switch (size) {
      case ButtonSize.small:
        padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 6);
        textStyle = theme.textTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.w500,
          fontSize: 12,
        ) ?? const TextStyle(fontSize: 12, fontWeight: FontWeight.w500);
        break;
      case ButtonSize.medium:
        padding = const EdgeInsets.symmetric(horizontal: 24, vertical: 10);
        textStyle = theme.textTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.w500,
          fontSize: 14,
        ) ?? const TextStyle(fontSize: 14, fontWeight: FontWeight.w500);
        break;
      case ButtonSize.large:
        padding = const EdgeInsets.symmetric(horizontal: 32, vertical: 14);
        textStyle = theme.textTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.w500,
          fontSize: 14,
        ) ?? const TextStyle(fontSize: 14, fontWeight: FontWeight.w500);
        break;
    }

    final buttonChild = icon != null
        ? Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18, color: foregroundColor),
              const SizedBox(width: 8),
              Text(text, style: textStyle),
            ],
          )
        : Text(text, style: textStyle);

    return SizedBox(
      height: _getHeightForSize(size),
      child: ElevatedButton(
        onPressed: enabled ? onPressed : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: foregroundColor,
          disabledBackgroundColor: colors.onSurface.withOpacity(0.12),
          disabledForegroundColor: colors.onSurface.withOpacity(0.38),
          padding: padding,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: side ?? BorderSide.none,
          ),
          elevation: variant == ButtonVariant.filled ? 1 : 0,
        ),
        child: buttonChild,
      ),
    );
  }

  double _getHeightForSize(ButtonSize size) {
    switch (size) {
      case ButtonSize.small:
        return 28.0;
      case ButtonSize.medium:
        return 36.0;
      case ButtonSize.large:
        return 44.0;
    }
  }
}

enum ButtonVariant { filled, tonal, text }
enum ButtonSize { small, medium, large }