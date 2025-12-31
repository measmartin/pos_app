import 'package:flutter/material.dart';
import '../../models/product.dart';
import '../../theme/app_spacing.dart';
import '../product/product_card.dart';

/// A horizontal carousel of trending products.
///
/// This widget displays a scrollable horizontal list of product cards
/// with loading and empty states.
///
/// Example:
/// ```dart
/// TrendingProductsCarousel(
///   productsFuture: viewModel.fetchTrendingProducts(),
///   onProductTap: (product) => Navigator.push(...),
///   height: 200,
/// )
/// ```
class TrendingProductsCarousel extends StatelessWidget {
  /// Future that provides the list of products
  final Future<List<Product>> productsFuture;

  /// Callback when a product is tapped
  final void Function(Product)? onProductTap;

  /// Height of the carousel
  final double height;

  /// Message to show when no products are available
  final String emptyMessage;

  /// Creates a trending products carousel
  const TrendingProductsCarousel({
    super.key,
    required this.productsFuture,
    this.onProductTap,
    this.height = 200,
    this.emptyMessage = 'No sales data yet to show trending products.',
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SizedBox(
      height: height,
      child: FutureBuilder<List<Product>>(
        future: productsFuture,
        builder: (context, snapshot) {
          // Loading state
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // Error state
          if (snapshot.hasError) {
            return Center(
              child: Card(
                elevation: 0,
                color: theme.colorScheme.errorContainer,
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  child: Text(
                    'Error loading products',
                    style: TextStyle(color: theme.colorScheme.onErrorContainer),
                  ),
                ),
              ),
            );
          }

          // Empty state
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Card(
                elevation: 0,
                color: theme.colorScheme.surfaceContainerHighest,
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  child: Text(emptyMessage),
                ),
              ),
            );
          }

          // Products list
          final products = snapshot.data!;
          return ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: products.length,
            itemBuilder: (context, index) {
              final product = products[index];
              return ProductCard(
                product: product,
                layout: ProductCardLayout.carousel,
                onTap: onProductTap != null ? () => onProductTap!(product) : null,
                showStock: false,
              );
            },
          );
        },
      ),
    );
  }
}
