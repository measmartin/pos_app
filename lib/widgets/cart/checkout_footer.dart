import 'package:flutter/material.dart';
import '../../theme/app_spacing.dart';
import '../buttons/wide_action_button.dart';

/// A footer widget for the checkout area with total and action button.
///
/// This widget displays the cart total and checkout button at the bottom
/// of the POS screen.
///
/// Example:
/// ```dart
/// CheckoutFooter(
///   totalAmount: cart.totalAmount,
///   itemCount: cart.items.length,
///   onCheckout: () => handleCheckout(),
///   isEnabled: cart.items.isNotEmpty,
/// )
/// ```
class CheckoutFooter extends StatelessWidget {
  /// The total amount to display
  final double totalAmount;

  /// Callback when checkout button is pressed
  final VoidCallback? onCheckout;

  /// Whether the checkout button is enabled
  final bool isEnabled;

  /// Number of items in cart
  final int itemCount;

  /// Whether checkout is in progress
  final bool isLoading;

  /// Optional callback for applying cart discount
  final VoidCallback? onApplyCartDiscount;

  /// Optional subtotal before discount
  final double? subtotalBeforeDiscount;

  /// Optional discount amount
  final double? discountAmount;

  /// Currency symbol to display
  final String currencySymbol;

  /// Creates a checkout footer
  const CheckoutFooter({
    super.key,
    required this.totalAmount,
    this.onCheckout,
    this.isEnabled = true,
    this.itemCount = 0,
    this.isLoading = false,
    this.onApplyCartDiscount,
    this.subtotalBeforeDiscount,
    this.discountAmount,
    this.currencySymbol = '\$',
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainer,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Cart Discount Button
            if (onApplyCartDiscount != null && itemCount > 0)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: OutlinedButton.icon(
                  onPressed: onApplyCartDiscount,
                  icon: Icon(
                    discountAmount != null && discountAmount! > 0
                        ? Icons.discount
                        : Icons.local_offer_outlined,
                  ),
                  label: Text(
                    discountAmount != null && discountAmount! > 0
                        ? 'Edit Cart Discount'
                        : 'Apply Cart Discount',
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: discountAmount != null && discountAmount! > 0
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurface,
                  ),
                ),
              ),

            // Show discount breakdown if present
            if (subtotalBeforeDiscount != null && discountAmount != null && discountAmount! > 0) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Subtotal:',
                    style: theme.textTheme.bodyMedium,
                  ),
                  Text(
                    '$currencySymbol${subtotalBeforeDiscount!.toStringAsFixed(2)}',
                    style: theme.textTheme.bodyMedium,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Discount:',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.error,
                    ),
                  ),
                  Text(
                    '-$currencySymbol${discountAmount!.toStringAsFixed(2)}',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.error,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const Divider(height: AppSpacing.md),
            ],

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total:',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (itemCount > 0)
                      Text(
                        '$itemCount ${itemCount == 1 ? 'item' : 'items'}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
                Text(
                  '$currencySymbol${totalAmount.toStringAsFixed(2)}',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            WideActionButton(
              label: 'CHECKOUT',
              onPressed: isEnabled && !isLoading ? onCheckout : null,
              isLoading: isLoading,
            ),
          ],
        ),
      ),
    );
  }
}
