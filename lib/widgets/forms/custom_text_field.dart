import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// A customizable text field widget with consistent styling.
///
/// This widget provides a standardized text input field with validation,
/// optional icons, and consistent theming throughout the app.
///
/// Example:
/// ```dart
/// CustomTextField(
///   controller: nameController,
///   labelText: 'Product Name',
///   validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
/// )
/// ```
class CustomTextField extends StatelessWidget {
  /// The controller for the text field
  final TextEditingController? controller;

  /// The label text displayed above the field
  final String labelText;

  /// Optional hint text displayed when field is empty
  final String? hintText;

  /// Optional validation function
  final String? Function(String?)? validator;

  /// Keyboard type for the input
  final TextInputType? keyboardType;

  /// Optional prefix icon
  final Widget? prefixIcon;

  /// Optional suffix icon or widget
  final Widget? suffixIcon;

  /// Optional prefix text (e.g., currency symbol)
  final String? prefixText;

  /// Whether the field should be filled with background color
  final bool filled;

  /// Maximum number of lines (null for unlimited)
  final int? maxLines;

  /// Minimum number of lines
  final int minLines;

  /// Whether to obscure the text (for passwords)
  final bool obscureText;

  /// Callback when text changes
  final void Function(String)? onChanged;

  /// Whether the field is read-only
  final bool readOnly;

  /// Whether the field is enabled
  final bool enabled;

  /// Optional list of input formatters
  final List<TextInputFormatter>? inputFormatters;

  /// Optional initial value (only used if controller is null)
  final String? initialValue;

  /// Optional suffix text
  final String? suffixText;

  /// Creates a custom text field
  const CustomTextField({
    super.key,
    this.controller,
    required this.labelText,
    this.hintText,
    this.validator,
    this.keyboardType,
    this.prefixIcon,
    this.suffixIcon,
    this.prefixText,
    this.filled = true,
    this.maxLines = 1,
    this.minLines = 1,
    this.obscureText = false,
    this.onChanged,
    this.readOnly = false,
    this.enabled = true,
    this.inputFormatters,
    this.initialValue,
    this.suffixText,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      initialValue: initialValue,
      decoration: InputDecoration(
        labelText: labelText,
        hintText: hintText,
        prefixIcon: prefixIcon,
        suffixIcon: suffixIcon,
        prefixText: prefixText,
        suffixText: suffixText,
        filled: filled,
      ),
      validator: validator,
      keyboardType: keyboardType,
      maxLines: maxLines,
      minLines: minLines,
      obscureText: obscureText,
      onChanged: onChanged,
      readOnly: readOnly,
      enabled: enabled,
      inputFormatters: inputFormatters,
    );
  }
}
