import 'package:flutter/material.dart';

/// Custom checkbox component based on the Figma design
class CustomCheckbox extends StatelessWidget {
  final bool value;
  final void Function(bool?) onChanged;
  final String? label;
  final CheckboxState state;
  final bool tristate;

  const CustomCheckbox({
    Key? key,
    required this.value,
    required this.onChanged,
    this.label,
    this.state = CheckboxState.enabled,
    this.tristate = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    // Determine checkbox colors based on state
    Color activeColor;
    Color checkColor;
    Color? fillColor;

    switch (state) {
      case CheckboxState.enabled:
        activeColor = colors.primary;
        checkColor = colors.onPrimary;
        fillColor = null;
        break;
      case CheckboxState.disabled:
        activeColor = colors.onSurface.withOpacity(0.38);
        checkColor = colors.surface;
        fillColor = colors.onSurface.withOpacity(0.12);
        break;
    }

    final checkbox = Checkbox(
      value: value,
      onChanged: state == CheckboxState.enabled ? onChanged : null,
      activeColor: activeColor,
      checkColor: checkColor,
      fillColor: fillColor != null ? MaterialStateProperty.all(fillColor) : null,
      tristate: tristate,
    );

    if (label != null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          checkbox,
          const SizedBox(width: 8),
          Text(
            label!,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: state == CheckboxState.disabled
                  ? colors.onSurface.withOpacity(0.38)
                  : colors.onSurface,
            ),
          ),
        ],
      );
    }

    return checkbox;
  }
}

enum CheckboxState { enabled, disabled }