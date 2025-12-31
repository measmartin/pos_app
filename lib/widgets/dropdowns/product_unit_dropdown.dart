import 'package:flutter/material.dart';
import '../../models/product.dart';
import '../../models/product_unit.dart';

/// A dropdown for selecting product units (base unit or additional units).
///
/// This widget displays the base unit and any additional units with their conversion factors.
///
/// Example:
/// ```dart
/// ProductUnitDropdown(
///   product: selectedProduct,
///   selectedUnit: currentUnit,
///   onChanged: (unit) => setState(() => currentUnit = unit),
/// )
/// ```
class ProductUnitDropdown extends StatelessWidget {
  /// The product whose units to display
  final Product product;

  /// The currently selected unit (null means base unit)
  final ProductUnit? selectedUnit;

  /// Callback when unit selection changes
  final ValueChanged<ProductUnit?> onChanged;

  /// Label text for the dropdown
  final String labelText;

  /// Whether the dropdown is enabled
  final bool enabled;

  /// Creates a product unit dropdown
  const ProductUnitDropdown({
    super.key,
    required this.product,
    required this.selectedUnit,
    required this.onChanged,
    this.labelText = 'Unit',
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<ProductUnit?>(
      initialValue: selectedUnit,
      decoration: InputDecoration(
        labelText: labelText,
        border: const OutlineInputBorder(),
      ),
      items: [
        // Base unit option
        DropdownMenuItem(
          value: null,
          child: Text('Base Unit (${product.unit})'),
        ),
        // Additional units with conversion factors
        ...product.additionalUnits.map((unit) => DropdownMenuItem(
          value: unit,
          child: Text('${unit.name} (×${unit.factor.toInt()})'),
        )),
      ],
      onChanged: enabled ? onChanged : null,
    );
  }
}
