import 'package:flutter/material.dart';

/// Reusable confirmation dialog for destructive actions
class ConfirmationDialog extends StatelessWidget {
  final String title;
  final String message;
  final String confirmText;
  final String cancelText;
  final Color? confirmColor;
  final IconData? icon;
  final bool isDestructive;
  final bool isDangerous; // Legacy support

  const ConfirmationDialog({
    super.key,
    required this.title,
    required this.message,
    this.confirmText = 'Confirm',
    this.cancelText = 'Cancel',
    this.confirmColor,
    this.icon,
    this.isDestructive = false,
    this.isDangerous = false, // Legacy support
  });

  @override
  Widget build(BuildContext context) {
    final shouldHighlightDanger = isDestructive || isDangerous;
    final defaultConfirmColor = shouldHighlightDanger 
        ? Theme.of(context).colorScheme.error 
        : Theme.of(context).colorScheme.primary;

    return AlertDialog(
      icon: icon != null ? Icon(icon, size: 32) : null,
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(cancelText),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          style: FilledButton.styleFrom(
            backgroundColor: confirmColor ?? defaultConfirmColor,
          ),
          child: Text(confirmText),
        ),
      ],
    );
  }

  /// Show confirmation dialog and return true if confirmed, false otherwise
  static Future<bool> show(
    BuildContext context, {
    required String title,
    required String message,
    String confirmText = 'Confirm',
    String cancelText = 'Cancel',
    Color? confirmColor,
    IconData? icon,
    bool isDestructive = false,
    bool isDangerous = false, // Legacy support
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => ConfirmationDialog(
        title: title,
        message: message,
        confirmText: confirmText,
        cancelText: cancelText,
        confirmColor: confirmColor,
        icon: icon,
        isDestructive: isDestructive || isDangerous, // Support both
      ),
    );
    return result ?? false;
  }
}
