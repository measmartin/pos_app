import 'package:flutter/material.dart';
import '../../theme/app_spacing.dart';

/// A full-width action button for primary actions.
///
/// This widget provides a consistent full-width button used for
/// checkout, submit, and other primary actions.
///
/// Example:
/// ```dart
/// WideActionButton(
///   label: 'CHECKOUT',
///   onPressed: () => handleCheckout(),
///   icon: Icons.shopping_cart,
/// )
/// ```
class WideActionButton extends StatelessWidget {
  /// The button label text
  final String label;

  /// Callback when button is pressed
  final VoidCallback? onPressed;

  /// Optional icon to display before label
  final IconData? icon;

  /// Whether the button is in loading state
  final bool isLoading;

  /// Optional background color (overrides theme)
  final Color? backgroundColor;

  /// Optional foreground color (overrides theme)
  final Color? foregroundColor;

  /// Optional vertical padding (defaults to 16)
  final double verticalPadding;

  /// Whether the button should be styled as filled (default) or outlined
  final bool isOutlined;

  /// Creates a wide action button
  const WideActionButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.isLoading = false,
    this.backgroundColor,
    this.foregroundColor,
    this.verticalPadding = AppSpacing.lg,
    this.isOutlined = false,
  });

  @override
  Widget build(BuildContext context) {
    final ButtonStyle style = isOutlined
        ? OutlinedButton.styleFrom(
            padding: EdgeInsets.symmetric(vertical: verticalPadding),
            foregroundColor: foregroundColor,
          )
        : FilledButton.styleFrom(
            padding: EdgeInsets.symmetric(vertical: verticalPadding),
            backgroundColor: backgroundColor,
            foregroundColor: foregroundColor,
          );

    final Widget content = isLoading
        ? SizedBox(
            height: 20,
            width: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: foregroundColor ?? Theme.of(context).colorScheme.onPrimary,
            ),
          )
        : icon != null
            ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon),
                  const SizedBox(width: AppSpacing.sm),
                  Text(label),
                ],
              )
            : Text(label);

    return SizedBox(
      width: double.infinity,
      child: isOutlined
          ? OutlinedButton(
              style: style,
              onPressed: isLoading ? null : onPressed,
              child: content,
            )
          : FilledButton(
              style: style,
              onPressed: isLoading ? null : onPressed,
              child: content,
            ),
    );
  }
}
