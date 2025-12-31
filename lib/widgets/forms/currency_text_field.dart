import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'custom_text_field.dart';

/// A specialized text field for currency input.
///
/// This widget provides a number input field with currency symbol prefix
/// and proper validation for monetary values.
///
/// Example:
/// ```dart
/// CurrencyTextField(
///   controller: priceController,
///   labelText: 'Selling Price',
///   validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
/// )
/// ```
class CurrencyTextField extends StatelessWidget {
  /// The controller for the text field
  final TextEditingController? controller;

  /// The label text displayed above the field
  final String labelText;

  /// Optional validation function
  final String? Function(String?)? validator;

  /// The currency symbol to display (defaults to '$')
  final String currencySymbol;

  /// Optional hint text
  final String? hintText;

  /// Callback when text changes
  final void Function(String)? onChanged;

  /// Whether to allow decimal values
  final bool allowDecimal;

  /// Whether the field is enabled
  final bool enabled;

  /// Optional initial value
  final String? initialValue;

  /// Creates a currency text field
  const CurrencyTextField({
    super.key,
    this.controller,
    required this.labelText,
    this.validator,
    this.currencySymbol = '\$ ',
    this.hintText,
    this.onChanged,
    this.allowDecimal = true,
    this.enabled = true,
    this.initialValue,
  });

  @override
  Widget build(BuildContext context) {
    return CustomTextField(
      controller: controller,
      initialValue: initialValue,
      labelText: labelText,
      hintText: hintText,
      prefixText: currencySymbol,
      keyboardType: TextInputType.numberWithOptions(decimal: allowDecimal),
      inputFormatters: [
        FilteringTextInputFormatter.allow(
          allowDecimal ? RegExp(r'^\d*\.?\d*') : RegExp(r'^\d*'),
        ),
      ],
      validator: validator,
      onChanged: onChanged,
      enabled: enabled,
    );
  }
}
