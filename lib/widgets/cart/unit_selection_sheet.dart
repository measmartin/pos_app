import 'package:flutter/material.dart';
import '../../models/product.dart';
import '../../models/product_unit.dart';
import '../../theme/app_spacing.dart';

/// A bottom sheet for selecting product units.
///
/// This widget displays a list of available units for a product,
/// including the base unit and any additional units.
///
/// Example:
/// ```dart
/// final unit = await UnitSelectionSheet.show(
///   context,
///   product: product,
/// );
/// if (unit != null) {
///   addToCart(product, unit: unit);
/// }
/// ```
class UnitSelectionSheet extends StatelessWidget {
  /// The product to select units for
  final Product product;

  /// Callback when a unit is selected
  final void Function(ProductUnit?) onUnitSelected;

  /// Creates a unit selection sheet
  const UnitSelectionSheet({
    super.key,
    required this.product,
    required this.onUnitSelected,
  });

  /// Shows the unit selection bottom sheet and returns the selected unit.
  ///
  /// Returns null if the sheet is dismissed without selection.
  static Future<ProductUnit?> show(
    BuildContext context,
    Product product,
  ) {
    return showModalBottomSheet<ProductUnit>(
      context: context,
      builder: (context) => UnitSelectionSheet(
        product: product,
        onUnitSelected: (unit) {
          Navigator.pop(context, unit);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Text(
              'Select Unit for ${product.name}',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const Divider(height: 1),
          
          // Base unit
          ListTile(
            leading: const Icon(Icons.circle, size: 10),
            title: Text('${product.unit} (Base)'),
            subtitle: Text('\$${product.sellingPrice.toStringAsFixed(2)}'),
            onTap: () => onUnitSelected(null),
          ),
          
          // Additional units
          if (product.additionalUnits.isNotEmpty) ...[
            const Divider(height: 1),
            ...product.additionalUnits.map((unit) {
              final price = unit.sellingPrice ?? 
                           (product.sellingPrice * unit.factor);
              return ListTile(
                leading: const Icon(Icons.circle_outlined, size: 10),
                title: Text(unit.name),
                subtitle: Text(
                  '\$${price.toStringAsFixed(2)} (${unit.factor} ${product.unit})',
                ),
                onTap: () => onUnitSelected(unit),
              );
            }),
          ],
          
          const SizedBox(height: AppSpacing.md),
        ],
      ),
    );
  }
}
