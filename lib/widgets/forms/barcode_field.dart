import 'package:flutter/material.dart';
import 'custom_text_field.dart';

/// A specialized text field for barcode input with scanner button.
///
/// This widget combines a text field for manual barcode entry with
/// a scanner button to trigger barcode scanning.
///
/// Example:
/// ```dart
/// BarcodeField(
///   controller: barcodeController,
///   onScan: () async {
///     final result = await Navigator.push(...scanner screen...);
///     if (result != null) barcodeController.text = result;
///   },
/// )
/// ```
class BarcodeField extends StatelessWidget {
  /// The controller for the text field
  final TextEditingController controller;

  /// The label text displayed above the field
  final String labelText;

  /// Callback when scan button is pressed
  final VoidCallback onScan;

  /// Optional validation function
  final String? Function(String?)? validator;

  /// Optional hint text
  final String? hintText;

  /// Whether the field is enabled
  final bool enabled;

  /// Icon to display on the scan button
  final IconData scanIcon;

  /// Creates a barcode field
  const BarcodeField({
    super.key,
    required this.controller,
    this.labelText = 'Barcode',
    required this.onScan,
    this.validator,
    this.hintText,
    this.enabled = true,
    this.scanIcon = Icons.qr_code_scanner,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: CustomTextField(
            controller: controller,
            labelText: labelText,
            hintText: hintText,
            validator: validator,
            enabled: enabled,
          ),
        ),
        const SizedBox(width: 8),
        IconButton.filledTonal(
          icon: Icon(scanIcon),
          onPressed: enabled ? onScan : null,
          tooltip: 'Scan Barcode',
        ),
      ],
    );
  }
}
