import 'package:flutter/material.dart';
import '../../theme/app_spacing.dart';

/// A button for quick actions with icon and label.
///
/// This widget provides a consistent button style for quick actions
/// like those shown on the dashboard.
///
/// Example:
/// ```dart
/// QuickActionButton(
///   label: 'New Sale',
///   icon: Icons.point_of_sale,
///   onPressed: () => Navigator.push(...),
/// )
/// ```
class QuickActionButton extends StatelessWidget {
  /// The button label text
  final String label;

  /// The icon to display
  final IconData icon;

  /// Callback when button is pressed
  final VoidCallback onPressed;

  /// Optional background color (overrides theme)
  final Color? backgroundColor;

  /// Optional foreground color (overrides theme)
  final Color? foregroundColor;

  /// Whether the button is in loading state
  final bool isLoading;

  /// Creates a quick action button
  const QuickActionButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onPressed,
    this.backgroundColor,
    this.foregroundColor,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      onPressed: isLoading ? null : onPressed,
      icon: isLoading
          ? SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: foregroundColor ?? Theme.of(context).colorScheme.onPrimary,
              ),
            )
          : Icon(icon),
      label: Text(label),
      style: FilledButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
        backgroundColor: backgroundColor,
        foregroundColor: foregroundColor,
      ),
    );
  }
}
