import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/product.dart';
import '../models/product_unit.dart';
import '../models/purchase_item.dart';
import '../models/journal_entry.dart';
import '../view_models/product_view_model.dart';
import '../services/database_service.dart';
import 'add_product_screen.dart';

class PurchaseScreen extends StatefulWidget {
  const PurchaseScreen({super.key});

  @override
  State<PurchaseScreen> createState() => _PurchaseScreenState();
}

class _PurchaseScreenState extends State<PurchaseScreen> {
  final TextEditingController _searchController = TextEditingController();
  Product? _selectedProduct;
  ProductUnit? _selectedUnit;
  final TextEditingController _quantityController = TextEditingController();
  final TextEditingController _costPriceController = TextEditingController();

  void _onSearchChanged() {
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProductViewModel>().fetchProducts();
    });
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _quantityController.dispose();
    _costPriceController.dispose();
    super.dispose();
  }

  void _selectProduct(Product product) {
    setState(() {
      _selectedProduct = product;
      _selectedUnit = null; // Reset unit
      _quantityController.clear();
      // Pre-fill cost price if available
      _costPriceController.text = product.costPrice.toString();
    });
    _searchController.clear();
  }

  Future<void> _processPurchase() async {
    if (_selectedProduct == null || _quantityController.text.isEmpty || _costPriceController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill all fields')));
      return;
    }

    final double enteredQuantity = double.tryParse(_quantityController.text) ?? 0;
    final double costPrice = double.tryParse(_costPriceController.text) ?? 0;

    if (enteredQuantity <= 0) return;

    // Calculate actual quantity in base units
    double factor = 1.0;
    if (_selectedUnit != null) {
      factor = _selectedUnit!.factor;
    }
    
    // Total base units = entered quantity * factor (e.g., 2 packs * 6 = 12 cans)
    // We treat stockQuantity as INTEGER in database, so we round if needed.
    // Usually stock is integer based.
    final int totalBaseUnits = (enteredQuantity * factor).round();

    final purchaseItem = PurchaseItem(
      productId: _selectedProduct!.id!,
      quantity: totalBaseUnits,
      costPrice: costPrice, // This is unit cost price entered
      date: DateTime.now(),
    );

    final dbService = DatabaseService();
    final db = await dbService.database;
    final date = DateTime.now();

    await db.transaction((txn) async {
      // 1. Insert Purchase Item Log
      await txn.insert('purchase_items', purchaseItem.toMap());

      // 2. Update Product Stock
      await txn.rawUpdate(
        'UPDATE products SET stockQuantity = stockQuantity + ? WHERE id = ?',
        [totalBaseUnits, _selectedProduct!.id],
      );
      
      // Update cost price if changed (optional business logic, usually Weighted Average Cost or FIFO)
      // For simplicity, we just update the 'current' cost price for next time
      await txn.rawUpdate(
        'UPDATE products SET costPrice = ? WHERE id = ?',
        [costPrice, _selectedProduct!.id],
      );

      // 3. Create Journal Page (Transaction)
      final totalCost = costPrice * enteredQuantity;
      
      final headerId = await txn.insert('journal_headers', {
        'date': date.toIso8601String(),
        'description': 'Purchase Stock: ${_selectedProduct!.name} x $enteredQuantity ${_selectedUnit?.name ?? _selectedProduct!.unit}',
        'reference_type': 'PURCHASE',
      });

      // Get Account IDs
      final cashAccount = await txn.query('accounts', where: 'name = ?', whereArgs: ['Cash on Hand - USD']);
      final inventoryAccount = await txn.query('accounts', where: 'name = ?', whereArgs: ['Inventory - USD']);
      
      final cashId = cashAccount.first['id'];
      final inventoryId = inventoryAccount.first['id'];

      // Post 1: Debit Inventory (Asset Increases)
      await txn.insert('journal_lines', {
        'header_id': headerId,
        'account_id': inventoryId,
        'debit': totalCost,
        'credit': 0,
      });

      // Post 2: Credit Cash (Asset Decreases)
      await txn.insert('journal_lines', {
        'header_id': headerId,
        'account_id': cashId,
        'debit': 0,
        'credit': totalCost,
      });
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Purchase Recorded Successfully')));
      setState(() {
        _selectedProduct = null;
        _selectedUnit = null;
        _quantityController.clear();
        _costPriceController.clear();
      });
      context.read<ProductViewModel>().fetchProducts();
    }
  }

  @override
  Widget build(BuildContext context) {
    final products = context.watch<ProductViewModel>().products;

    return Scaffold(
      appBar: AppBar(title: const Text('Purchase (Incoming Stock)')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // 1. Search or Add Product
            if (_selectedProduct == null) ...[
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  labelText: 'Search Product to Restock',
                  prefixIcon: const Icon(Icons.search),
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.add_circle),
                    onPressed: () {
                       // Quick Add Product
                       Navigator.push(
                         context, 
                         MaterialPageRoute(builder: (_) => const AddProductScreen(product: null), fullscreenDialog: true)
                       );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 10),
              if (_searchController.text.isNotEmpty)
                Expanded(
                  child: ListView(
                    children: products.where((p) => 
                      p.name.toLowerCase().contains(_searchController.text.toLowerCase())
                    ).map((product) => ListTile(
                      title: Text(product.name),
                      subtitle: Text('Current Stock: ${product.stockQuantity} ${product.unit}'),
                      onTap: () => _selectProduct(product),
                    )).toList(),
                  ),
                )
              else 
                const Expanded(child: Center(child: Text('Search for a product or add a new one.'))),
            ] else ...[
              // 2. Product Selected - Entry Form
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Row(
                        children: [
                           Text(_selectedProduct!.name, style: Theme.of(context).textTheme.headlineSmall),
                           const Spacer(),
                           IconButton(
                             icon: const Icon(Icons.close), 
                             onPressed: () => setState(() => _selectedProduct = null),
                           )
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Unit Selection
                      DropdownButtonFormField<ProductUnit?>(
                        initialValue: _selectedUnit,
                        decoration: const InputDecoration(labelText: 'Unit', border: OutlineInputBorder()),
                        items: [
                          DropdownMenuItem(
                            value: null, 
                            child: Text('Base Unit (${_selectedProduct!.unit})'),
                          ),
                          ..._selectedProduct!.additionalUnits.map((u) => DropdownMenuItem(
                            value: u,
                            child: Text('${u.name} (x${u.factor.toInt()})'),
                          ))
                        ],
                        onChanged: (value) {
                          setState(() {
                            _selectedUnit = value;
                          });
                        },
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _quantityController,
                        decoration: const InputDecoration(labelText: 'Quantity', border: OutlineInputBorder()),
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _costPriceController,
                        decoration: const InputDecoration(labelText: 'Cost Price (Per Unit)', border: OutlineInputBorder(), prefixText: '\$'),
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: _processPurchase, 
                          child: const Text('CONFIRM PURCHASE')
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ]
          ],
        ),
      ),
    );
  }
}
