import 'package:flutter/material.dart';

/// Custom text field component based on the Figma design
/// Supports different states and types
class CustomTextField extends StatefulWidget {
  final String? label;
  final String? hintText;
  final TextEditingController? controller;
  final TextInputType? keyboardType;
  final bool obscureText;
  final TextInputAction? textInputAction;
  final FormFieldValidator<String>? validator;
  final void Function(String)? onChanged;
  final void Function(String)? onSubmitted;
  final FocusNode? focusNode;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final int? maxLines;
  final String? helperText;
  final String? errorText;
  final bool enabled;
  final TextFieldType type;
  final TextFieldState state;

  const CustomTextField({
    Key? key,
    this.label,
    this.hintText,
    this.controller,
    this.keyboardType,
    this.obscureText = false,
    this.textInputAction,
    this.validator,
    this.onChanged,
    this.onSubmitted,
    this.focusNode,
    this.prefixIcon,
    this.suffixIcon,
    this.maxLines = 1,
    this.helperText,
    this.errorText,
    this.enabled = true,
    this.type = TextFieldType.text,
    this.state = TextFieldState.defaultState,
  }) : super(key: key);

  @override
  State<CustomTextField> createState() => _CustomTextFieldState();
}

class _CustomTextFieldState extends State<CustomTextField> {
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    // Determine border and background colors based on state
    Color borderColor;
    Color backgroundColor;
    double borderWidth;

    switch (widget.state) {
      case TextFieldState.defaultState:
        borderColor = _isFocused ? colors.primary : colors.outline;
        backgroundColor = colors.surface;
        borderWidth = _isFocused ? 2.0 : 1.0;
        break;
      case TextFieldState.focused:
        borderColor = colors.primary;
        backgroundColor = colors.surface;
        borderWidth = 2.0;
        break;
      case TextFieldState.error:
        borderColor = colors.error;
        backgroundColor = colors.surface;
        borderWidth = 2.0;
        break;
      case TextFieldState.disabled:
        borderColor = colors.outline.withOpacity(0.12);
        backgroundColor = colors.surface.withOpacity(0.12);
        borderWidth = 1.0;
        break;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.label != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              widget.label!,
              style: theme.textTheme.labelMedium?.copyWith(
                color: widget.state == TextFieldState.disabled
                    ? colors.onSurface.withOpacity(0.38)
                    : colors.onSurface,
              ),
            ),
          ),
        TextFormField(
          controller: widget.controller,
          keyboardType: widget.keyboardType,
          obscureText: widget.obscureText,
          textInputAction: widget.textInputAction,
          validator: widget.validator,
          onChanged: widget.onChanged,
          onFieldSubmitted: widget.onSubmitted,
          focusNode: widget.focusNode,
          enabled: widget.enabled,
          maxLines: widget.maxLines,
          decoration: InputDecoration(
            hintText: widget.hintText,
            hintStyle: theme.textTheme.bodyLarge?.copyWith(
              color: widget.state == TextFieldState.disabled
                  ? colors.onSurface.withOpacity(0.38)
                  : colors.onSurfaceVariant,
            ),
            prefixIcon: widget.prefixIcon,
            suffixIcon: widget.suffixIcon,
            filled: true,
            fillColor: backgroundColor,
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: borderColor,
                width: borderWidth,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: widget.state == TextFieldState.defaultState
                    ? colors.outline
                    : borderColor,
                width: borderWidth,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: colors.primary,
                width: 2.0,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: colors.error,
                width: 2.0,
              ),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: colors.error,
                width: 2.0,
              ),
            ),
            errorText: widget.errorText,
          ),
        ),
        if (widget.helperText != null || widget.errorText != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              widget.errorText ?? widget.helperText!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: widget.errorText != null
                    ? colors.error
                    : colors.onSurfaceVariant,
              ),
            ),
          ),
      ],
    );
  }
}

enum TextFieldType { text, email, password, search }
enum TextFieldState { defaultState, focused, error, disabled }