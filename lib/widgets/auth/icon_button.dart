import 'package:flutter/material.dart';

/// Icon button component based on the Figma design
class CustomIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final IconButtonKind kind;
  final IconButtonState state;

  const CustomIconButton({
    Key? key,
    required this.icon,
    required this.onPressed,
    this.kind = IconButtonKind.primary,
    this.state = IconButtonState.enabled,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    // Determine colors based on kind and state
    Color backgroundColor;
    Color foregroundColor;

    switch (kind) {
      case IconButtonKind.primary:
        backgroundColor = state == IconButtonState.enabled
            ? colors.primary
            : colors.onSurface.withOpacity(0.12);
        foregroundColor = state == IconButtonState.enabled
            ? colors.onPrimary
            : colors.onSurface.withOpacity(0.38);
        break;
      case IconButtonKind.secondary:
        backgroundColor = state == IconButtonState.enabled
            ? colors.primary.withOpacity(0.12)
            : colors.onSurface.withOpacity(0.12);
        foregroundColor = state == IconButtonState.enabled
            ? colors.primary
            : colors.onSurface.withOpacity(0.38);
        break;
      case IconButtonKind.tertiary:
        backgroundColor = Colors.transparent;
        foregroundColor = state == IconButtonState.enabled
            ? colors.primary
            : colors.onSurface.withOpacity(0.38);
        break;
    }

    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: IconButton(
        icon: Icon(icon, color: foregroundColor, size: 20),
        onPressed: state == IconButtonState.enabled ? onPressed : null,
        padding: EdgeInsets.zero,
        splashRadius: 20,
      ),
    );
  }
}

enum IconButtonKind { primary, secondary, tertiary }
enum IconButtonState { enabled, disabled }