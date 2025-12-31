import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/product.dart';
import '../models/product_unit.dart';
import '../view_models/product_view_model.dart';
import '../view_models/unit_view_model.dart';
import '../widgets/forms/custom_text_field.dart';
import '../widgets/forms/currency_text_field.dart';
import '../widgets/common/empty_state.dart';
import '../widgets/common/spacing.dart';
import '../theme/app_spacing.dart';

class UnitManagementScreen extends StatefulWidget {
  final Product product;
  const UnitManagementScreen({super.key, required this.product});

  @override
  State<UnitManagementScreen> createState() => _UnitManagementScreenState();
}

class _UnitManagementScreenState extends State<UnitManagementScreen> {
  late Product _currentProduct;

  @override
  void initState() {
    super.initState();
    _currentProduct = widget.product;
    // Fetch global units when screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<UnitViewModel>().fetchUnitDefinitions();
    });
  }

  void _showAddUnitDialog(BuildContext context) {
    final nameController = TextEditingController();
    final factorController = TextEditingController();
    final priceController = TextEditingController();
    
    // We will list available global units that match this product's base unit
    final globalUnits = context.read<UnitViewModel>().unitDefinitions
      .where((u) => u.baseUnit.toLowerCase() == _currentProduct.unit.toLowerCase())
      .toList();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('Add Unit'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (globalUnits.isNotEmpty) ...[
                    DropdownButtonFormField<int>(
                      decoration: const InputDecoration(
                        labelText: 'Select Pre-defined Unit',
                        border: OutlineInputBorder(),
                      ),
                      items: globalUnits.map((u) => DropdownMenuItem(
                        value: u.id,
                        child: Text('${u.name} (${u.factor} ${_currentProduct.unit})'),
                      )).toList(),
                      onChanged: (id) {
                        final selected = globalUnits.firstWhere((u) => u.id == id);
                        setDialogState(() {
                          nameController.text = selected.name;
                          factorController.text = selected.factor.toString();
                        });
                      },
                    ),
                    const VerticalSpace.lg(),
                    Text(
                      'Or define custom:',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const VerticalSpace.md(),
                  ],
                  
                  CustomTextField(
                    controller: nameController,
                    labelText: 'Unit Name (e.g. Pack)',
                  ),
                  const VerticalSpace.lg(),
                  
                  CustomTextField(
                    controller: factorController,
                    labelText: 'Quantity in ${_currentProduct.unit}',
                    keyboardType: TextInputType.number,
                  ),
                  const VerticalSpace.lg(),

                  CurrencyTextField(
                    controller: priceController,
                    labelText: 'Selling Price (Optional Override)',
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () async {
                  if (nameController.text.isNotEmpty && factorController.text.isNotEmpty) {
                    final unit = ProductUnit(
                      productId: _currentProduct.id!,
                      name: nameController.text,
                      factor: double.parse(factorController.text),
                      sellingPrice: double.tryParse(priceController.text),
                    );
                    
                    await context.read<ProductViewModel>().addProductUnit(unit);
                    if (context.mounted) {
                      Navigator.pop(context);
                    }
                  }
                },
                child: const Text('Add'),
              ),
            ],
          );
        }
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    // Re-fetch product from VM to get latest units
    final product = context.select<ProductViewModel, Product?>(
      (vm) => vm.products.firstWhere((p) => p.id == widget.product.id, orElse: () => widget.product)
    );

    if (product == null) {
      return const Scaffold(
        body: Center(child: Text("Product not found")),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Units for ${product.name}'),
      ),
      body: ListView(
        children: [
          ListTile(
            leading: Icon(
              Icons.check_circle,
              color: theme.colorScheme.primary,
            ),
            title: Text('Base Unit: ${product.unit}'),
            subtitle: const Text('Factor: 1.0 (Standard)'),
          ),
          const Divider(),
          if (product.additionalUnits.isEmpty)
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: EmptyState(
                icon: Icons.inventory_2_outlined,
                message: 'No additional units defined',
                actionLabel: 'Add Unit',
                onAction: () => _showAddUnitDialog(context),
              ),
            ),
          ...product.additionalUnits.map((unit) => ListTile(
            leading: const Icon(Icons.category),
            title: Text(unit.name),
            subtitle: Text('Contains ${unit.factor} ${product.unit}'),
            trailing: IconButton(
              icon: Icon(
                Icons.delete,
                color: theme.colorScheme.error,
              ),
              onPressed: () {
                context.read<ProductViewModel>().deleteProductUnit(unit.id!, product.id!);
              },
              tooltip: 'Delete unit',
            ),
          )),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddUnitDialog(context),
        tooltip: 'Add unit',
        child: const Icon(Icons.add),
      ),
    );
  }
}
