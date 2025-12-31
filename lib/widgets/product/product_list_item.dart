import 'package:flutter/material.dart';
import '../../models/product.dart';
import '../../theme/app_radius.dart';
import 'product_image.dart';

/// A list item widget for displaying products in a list view.
///
/// Example:
/// ```dart
/// ProductListItem(
///   product: product,
///   onTap: () => addToCart(product),
///   trailing: Text('\$${product.sellingPrice}'),
/// )
/// ```
class ProductListItem extends StatelessWidget {
  /// The product to display
  final Product product;

  /// Callback when the item is tapped
  final VoidCallback? onTap;

  /// Optional trailing widget (e.g., price, button)
  final Widget? trailing;

  /// Optional custom subtitle
  final String? subtitle;

  /// Size of the leading image
  final double imageSize;

  /// Creates a product list item
  const ProductListItem({
    super.key,
    required this.product,
    this.onTap,
    this.trailing,
    this.subtitle,
    this.imageSize = 50.0,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: ProductImage(
        imagePath: product.imagePath,
        width: imageSize,
        height: imageSize,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        fallbackIcon: Icons.inventory_2,
        fallbackIconSize: 24,
      ),
      title: Text(product.name),
      subtitle: subtitle != null 
          ? Text(subtitle!)
          : Text('${product.stockQuantity} in stock'),
      trailing: trailing ?? Text('\$${product.sellingPrice}'),
      onTap: onTap,
    );
  }
}
