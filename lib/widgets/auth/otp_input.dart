import 'package:flutter/material.dart';

/// OTP input component based on the Figma design
class OTPInput extends StatefulWidget {
  final int length;
  final void Function(String) onCompleted;
  final void Function(String)? onChanged;
  final OTPInputState state;

  const OTPInput({
    Key? key,
    this.length = 6,
    required this.onCompleted,
    this.onChanged,
    this.state = OTPInputState.defaultState,
  }) : super(key: key);

  @override
  State<OTPInput> createState() => _OTPInputState();
}

class _OTPInputState extends State<OTPInput> {
  late List<TextEditingController> _controllers;
  late List<FocusNode> _focusNodes;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(widget.length, (index) => TextEditingController());
    _focusNodes = List.generate(widget.length, (index) => FocusNode());
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var focusNode in _focusNodes) {
      focusNode.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    // Determine border colors based on state
    Color borderColor;
    double borderWidth;

    switch (widget.state) {
      case OTPInputState.defaultState:
        borderColor = colors.outline;
        borderWidth = 1.0;
        break;
      case OTPInputState.focused:
        borderColor = colors.primary;
        borderWidth = 2.0;
        break;
      case OTPInputState.error:
        borderColor = colors.error;
        borderWidth = 2.0;
        break;
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(widget.length, (index) {
        return SizedBox(
          width: 44,
          height: 44,
          child: TextField(
            controller: _controllers[index],
            focusNode: _focusNodes[index],
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineSmall,
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: borderColor,
                  width: borderWidth,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: borderColor,
                  width: borderWidth,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: colors.primary,
                  width: 2.0,
                ),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: colors.error,
                  width: 2.0,
                ),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: colors.error,
                  width: 2.0,
                ),
              ),
              filled: true,
              fillColor: colors.surface,
            ),
            onChanged: (value) {
              if (value.length == 1) {
                // Move to next field
                if (index < widget.length - 1) {
                  FocusScope.of(context).requestFocus(_focusNodes[index + 1]);
                } else {
                  // Last field, unfocus and trigger completion
                  _focusNodes[index].unfocus();
                  _onCompleted();
                }
              } else if (value.isEmpty) {
                // Move to previous field
                if (index > 0) {
                  FocusScope.of(context).requestFocus(_focusNodes[index - 1]);
                }
              }
                            
              // Call onChanged callback if provided
              if (widget.onChanged != null) {
                String code = '';
                for (var controller in _controllers) {
                  code += controller.text;
                }
                widget.onChanged!(code);
              }
            },
          ),
        );
      }),
    );
  }

  void _onCompleted() {
    String code = '';
    for (var controller in _controllers) {
      code += controller.text;
    }
    widget.onCompleted(code);
  }
  
  /// Clear all input fields
  void clear() {
    for (var controller in _controllers) {
      controller.clear();
    }
    // Focus on the first field
    if (_focusNodes.isNotEmpty) {
      FocusScope.of(_focusNodes.first.context!).requestFocus(_focusNodes.first);
    }
  }
  
  /// Get the current code
  String getCode() {
    String code = '';
    for (var controller in _controllers) {
      code += controller.text;
    }
    return code;
  }
}

enum OTPInputState { defaultState, focused, error }