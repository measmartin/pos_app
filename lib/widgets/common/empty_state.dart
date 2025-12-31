import 'package:flutter/material.dart';
import '../../theme/app_spacing.dart';

/// A widget that displays an empty state with an optional icon, message, and action button.
///
/// Use this widget to provide feedback when there's no data to display.
///
/// Example:
/// ```dart
/// EmptyState(
///   message: 'No products found',
///   icon: Icons.inventory_2,
///   actionLabel: 'Add Product',
///   onAction: () => Navigator.push(...),
/// )
/// ```
class EmptyState extends StatelessWidget {
  /// The message to display
  final String message;

  /// Optional icon to display above the message
  final IconData? icon;

  /// Optional action button label
  final String? actionLabel;

  /// Optional action button callback
  final VoidCallback? onAction;

  /// Optional icon size (defaults to 64)
  final double iconSize;

  /// Optional text style for the message
  final TextStyle? messageStyle;

  /// Creates an empty state widget
  const EmptyState({
    super.key,
    required this.message,
    this.icon,
    this.actionLabel,
    this.onAction,
    this.iconSize = 64.0,
    this.messageStyle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: iconSize,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(height: AppSpacing.lg),
            ],
            Text(
              message,
              style: messageStyle ??
                  theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
              textAlign: TextAlign.center,
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: AppSpacing.xl),
              FilledButton.icon(
                onPressed: onAction,
                icon: const Icon(Icons.add),
                label: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
