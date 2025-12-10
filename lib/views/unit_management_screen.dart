import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/product.dart';
import '../models/product_unit.dart';
import '../view_models/product_view_model.dart';
import '../view_models/unit_view_model.dart'; // Import UnitViewModel

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
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Add Unit'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (globalUnits.isNotEmpty)
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
                      nameController.text = selected.name;
                      factorController.text = selected.factor.toString();
                    },
                  ),
                const SizedBox(height: 16),
                const Text('Or define custom:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Unit Name (e.g. Pack)'),
                ),
                const SizedBox(height: 16),
                
                TextField(
                  controller: factorController,
                  decoration: InputDecoration(
                    labelText: 'Quantity in ${_currentProduct.unit}',
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),

                TextField(
                  controller: priceController,
                  decoration: const InputDecoration(
                    labelText: 'Selling Price (Optional Override)',
                    prefixText: '\$',
                  ),
                  keyboardType: TextInputType.number,
                ),
              ],
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
                    if (mounted) Navigator.pop(context);
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
    // Re-fetch product from VM to get latest units
    final product = context.select<ProductViewModel, Product?>(
      (vm) => vm.products.firstWhere((p) => p.id == widget.product.id, orElse: () => widget.product)
    );

    if (product == null) return const Scaffold(body: Center(child: Text("Product not found")));

    return Scaffold(
      appBar: AppBar(
        title: Text('Units for ${product.name}'),
      ),
      body: ListView(
        children: [
          ListTile(
            title: Text('Base Unit: ${product.unit}'),
            subtitle: const Text('Factor: 1.0 (Standard)'),
            leading: const Icon(Icons.check_circle),
          ),
          const Divider(),
          if (product.additionalUnits.isEmpty)
             const Padding(
               padding: EdgeInsets.all(16.0),
               child: Text('No additional units defined. Add one to sell in packs or boxes.'),
             ),
          ...product.additionalUnits.map((unit) => ListTile(
            title: Text(unit.name),
            subtitle: Text('Contains ${unit.factor} ${product.unit}'),
            trailing: IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () {
                context.read<ProductViewModel>().deleteProductUnit(unit.id!, product.id!);
              },
            ),
          )),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddUnitDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }
}
