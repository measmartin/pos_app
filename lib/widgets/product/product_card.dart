import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/product.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_elevation.dart';
import 'product_image.dart';

/// Layout options for the product card
enum ProductCardLayout {
  /// Grid layout for product list screens
  grid,
  /// Horizontal carousel layout for dashboard
  carousel,
}

/// A reusable product card widget that can be displayed in grid or carousel layout.
///
/// Example:
/// ```dart
/// ProductCard(
///   product: product,
///   layout: ProductCardLayout.grid,
///   onTap: () => Navigator.push(...),
///   showStock: true,
/// )
/// ```
class ProductCard extends StatelessWidget {
  /// The product to display
  final Product product;

  /// The layout style for the card
  final ProductCardLayout layout;

  /// Callback when the card is tapped
  final VoidCallback? onTap;

  /// Optional callback for delete action
  final VoidCallback? onDelete;

  /// Optional callback for stock adjustment
  final VoidCallback? onAdjustStock;

  /// Whether to show stock information
  final bool showStock;

  /// Whether to show price information
  final bool showPrice;

  /// Creates a product card
  const ProductCard({
    super.key,
    required this.product,
    this.layout = ProductCardLayout.grid,
    this.onTap,
    this.onDelete,
    this.onAdjustStock,
    this.showStock = true,
    this.showPrice = true,
  });

  @override
  Widget build(BuildContext context) {
    return layout == ProductCardLayout.grid
        ? _buildGridCard(context)
        : _buildCarouselCard(context);
  }

  Widget _buildGridCard(BuildContext context) {
    final theme = Theme.of(context);
    
    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: AppElevation.low,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Product Image
            Expanded(
              child: ProductImage(
                imagePath: product.imagePath,
                fit: BoxFit.cover,
                fallbackIcon: Icons.inventory_2,
                fallbackIconSize: 48,
              ),
            ),
            // Product Details
            Padding(
              padding: const EdgeInsets.all(AppSpacing.sm),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: theme.textTheme.titleMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  if (showPrice)
                    Text(
                      NumberFormat.currency(symbol: '\$').format(product.sellingPrice),
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  if (showStock) ...[
                    const SizedBox(height: 2),
                    Text(
                      'Stock: ${product.stockQuantity} ${product.unit}',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ],
              ),
            ),
            // Actions (Delete & Adjust Stock)
            if (onDelete != null || onAdjustStock != null)
              Padding(
                padding: const EdgeInsets.only(right: AppSpacing.xs, bottom: AppSpacing.xs),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (onAdjustStock != null)
                      IconButton(
                        icon: const Icon(Icons.inventory),
                        onPressed: onAdjustStock,
                        tooltip: 'Adjust Stock',
                      ),
                    if (onDelete != null)
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: onDelete,
                        tooltip: 'Delete',
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCarouselCard(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      width: 160,
      margin: const EdgeInsets.only(right: AppSpacing.lg),
      child: Card(
        elevation: AppElevation.low,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: ProductImage(
                  imagePath: product.imagePath,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  fallbackIcon: Icons.shopping_bag,
                  fallbackIconSize: 48,
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      style: theme.textTheme.titleMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    if (showPrice)
                      Text(
                        NumberFormat.currency(symbol: '\$').format(product.sellingPrice),
                        style: theme.textTheme.bodyMedium,
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
