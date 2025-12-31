import 'package:flutter/material.dart';
import '../../models/cart_item.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_radius.dart';
import '../product/product_image.dart';

/// A card widget that displays a cart item with quantity controls.
///
/// This widget shows product information, quantity controls, and stock warnings.
///
/// Example:
/// ```dart
/// CartItemCard(
///   item: cartItem,
///   onIncrement: () => cart.addToCart(item.product, unit: item.unit),
///   onDecrement: () => cart.removeFromCart(item.product, unit: item.unit),
///   showStockWarning: true,
/// )
/// ```
class CartItemCard extends StatelessWidget {
  /// The cart item to display
  final CartItem item;

  /// Callback when increment button is pressed
  final VoidCallback onIncrement;

  /// Callback when decrement button is pressed
  final VoidCallback onDecrement;

  /// Optional callback to remove item completely
  final VoidCallback? onRemove;

  /// Optional callback to apply discount to item
  final VoidCallback? onDiscount;

  /// Whether to show stock warning
  final bool showStockWarning;

  /// Size of the product image
  final double imageSize;

  /// Creates a cart item card
  const CartItemCard({
    super.key,
    required this.item,
    required this.onIncrement,
    required this.onDecrement,
    this.onRemove,
    this.onDiscount,
    this.showStockWarning = true,
    this.imageSize = 50.0,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    // Calculate available stock in the selected unit
    final double stockInSelectedUnit = item.product.getStockInUnit(item.unit);
    final String unitName = item.unit?.name ?? item.product.unit;
    final double stockLeft = stockInSelectedUnit - item.quantity;
    final bool isOutOfStock = stockLeft < 0;
    
    return Card(
      margin: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      child: ListTile(
        leading: ProductImage(
          imagePath: item.product.imagePath,
          width: imageSize,
          height: imageSize,
          borderRadius: BorderRadius.circular(AppRadius.sm),
          fallbackIcon: Icons.shopping_bag,
          fallbackIconSize: 24,
        ),
        title: Text('${item.product.name} ($unitName)'),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Show original price if discounted
            if (item.hasDiscount) ...[
              Text(
                '\$${item.subtotalBeforeDiscount.toStringAsFixed(2)}',
                style: theme.textTheme.bodySmall?.copyWith(
                  decoration: TextDecoration.lineThrough,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              Row(
                children: [
                  Text(
                    '\$${item.subtotal.toStringAsFixed(2)}',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.xs,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.errorContainer,
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                    ),
                    child: Text(
                      item.discount!.displayValue,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onErrorContainer,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ] else
              Text(
                '\$${item.subtotal.toStringAsFixed(2)}',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            if (showStockWarning) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Stock Left: ${stockLeft.toStringAsFixed(1)} $unitName',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: isOutOfStock ? theme.colorScheme.error : Colors.green,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Discount button
            if (onDiscount != null)
              IconButton(
                icon: Icon(
                  item.hasDiscount ? Icons.discount : Icons.local_offer_outlined,
                  color: item.hasDiscount
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurfaceVariant,
                ),
                onPressed: onDiscount,
                tooltip: item.hasDiscount ? 'Edit Discount' : 'Apply Discount',
              ),
            IconButton(
              icon: const Icon(Icons.remove_circle_outline),
              onPressed: onDecrement,
              tooltip: 'Decrease quantity',
            ),
            SizedBox(
              width: 30,
              child: Text(
                '${item.quantity}',
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.add_circle_outline),
              onPressed: onIncrement,
              tooltip: 'Increase quantity',
            ),
          ],
        ),
        isThreeLine: showStockWarning,
      ),
    );
  }
}
