/// File Overview:
/// - Purpose: Reusable text field widget that exposes a built-in clear action
///   to simplify form inputs across the UI.
/// - Backend Migration: Keep; this is purely presentation logic and can remain
///   unchanged when backend-driven data is introduced.
import 'package:flutter/material.dart';

class ClearTextField extends StatefulWidget {
  final TextEditingController controller;
  final String hintText;
  final bool obscureText;
  final Function(String)? onChanged;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final FocusNode? focusNode;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;
  final AutovalidateMode? autovalidateMode;

  const ClearTextField({
    Key? key,
    required this.controller,
    required this.hintText,
    this.obscureText = false,
    this.onChanged,
    this.keyboardType,
    this.validator,
    this.focusNode,
    this.textInputAction,
    this.onSubmitted,
    this.autovalidateMode,
  }) : super(key: key);

  @override
  State<ClearTextField> createState() => _ClearTextFieldState();
}

class _ClearTextFieldState extends State<ClearTextField> {
  bool _showClear = false;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    super.dispose();
  }

  void _onTextChanged() {
    setState(() {
      _showClear = widget.controller.text.isNotEmpty;
    });
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controller,
      obscureText: widget.obscureText,
      keyboardType: widget.keyboardType,
      focusNode: widget.focusNode,
      textInputAction: widget.textInputAction,
      autovalidateMode: widget.autovalidateMode,
      validator: widget.validator,
      onFieldSubmitted: widget.onSubmitted,
      onChanged: (value) {
        if (widget.onChanged != null) {
          widget.onChanged!(value);
        }
      },
      decoration: InputDecoration(
        hintText: widget.hintText,
        filled: true,
        fillColor: Colors.grey[200],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        suffixIcon: _showClear
            ? IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () {
                  widget.controller.clear();
                  if (widget.onChanged != null) {
                    widget.onChanged!('');
                  }
                },
              )
            : null,
      ),
    );
  }
}