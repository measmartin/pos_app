import 'dart:io';
import 'package:flutter/material.dart';
import 'package:pos_app/models/product.dart';
import 'package:pos_app/models/product_unit.dart';
import 'package:pos_app/views/add_product_screen.dart';
import 'package:provider/provider.dart';
import '../view_models/product_view_model.dart';
import '../view_models/cart_view_model.dart';
import '../utils/pdf_generator.dart';
import '../models/cart_item.dart';

class POSScreen extends StatefulWidget {
  const POSScreen({super.key});

  @override
  State<POSScreen> createState() => _POSScreenState();
}

class _POSScreenState extends State<POSScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Ensure we have products loaded
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProductViewModel>().fetchProducts();
    });
  }

  void _onScanBarcode() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SimpleScannerScreen()),
    );
    
    if (result != null && result is String && mounted) {
      _addToCartByBarcode(result);
    }
  }

  void _addToCartByBarcode(String barcode) {
    final productViewModel = context.read<ProductViewModel>();
    try {
      final product = productViewModel.products.firstWhere(
        (p) => p.barcode == barcode,
      );
      // Quick add base unit
      context.read<CartViewModel>().addToCart(product);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Added ${product.name}')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Product not found!')),
      );
    }
  }

  void _addToCart(Product product, {ProductUnit? unit}) {
    context.read<CartViewModel>().addToCart(product, unit: unit);
  }

  void _showUnitSelectionDialog(Product product) {
    if (product.sellingPrice == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please set selling price first!')),
      );
      return;
    }
    
    // If no extra units, just add base
    if (product.additionalUnits.isEmpty) {
      _addToCart(product);
      return;
    }

    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            title: Text('Select Unit for ${product.name}', style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
          ListTile(
            leading: const Icon(Icons.circle, size: 10),
            title: Text('${product.unit} (Base)'),
            subtitle: Text('\$${product.sellingPrice}'),
            onTap: () {
              Navigator.pop(context);
              _addToCart(product);
            },
          ),
          ...product.additionalUnits.map((unit) {
            final price = unit.sellingPrice ?? (product.sellingPrice * unit.factor);
            return ListTile(
              leading: const Icon(Icons.circle_outlined, size: 10),
              title: Text(unit.name),
              subtitle: Text('$price (${unit.factor} ${product.unit})'),
              onTap: () {
                Navigator.pop(context);
                _addToCart(product, unit: unit);
              },
            );
          }),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('POS Terminal / Sales')),
      body: Column(
        children: [
          // Search and Scan Area
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      hintText: 'Search Product...',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) {
                      setState(() {}); // Simple rebuild to filter list below
                    },
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  onPressed: _onScanBarcode,
                  icon: const Icon(Icons.qr_code_scanner),
                  tooltip: 'Scan Barcode',
                ),
              ],
            ),
          ),
          
          // Product Suggestion List (Visible when searching or empty cart)
          if (_searchController.text.isNotEmpty)
             Expanded(
               flex: 1,
               child: Consumer<ProductViewModel>(
                 builder: (context, viewModel, child) {
                   final filtered = viewModel.products.where((p) => 
                     p.name.toLowerCase().contains(_searchController.text.toLowerCase()) || 
                     p.barcode.contains(_searchController.text)
                   ).toList();
                   
                   return ListView.builder(
                     itemCount: filtered.length,
                     itemBuilder: (context, index) {
                       final product = filtered[index];
                       return ListTile(
                         leading: ClipRRect(
                           borderRadius: BorderRadius.circular(8.0),
                           child: product.imagePath != null 
                             ? Image.file(File(product.imagePath!), width: 50, height: 50, fit: BoxFit.cover) 
                             : Container(
                                 width: 50, height: 50,
                                 color: Theme.of(context).colorScheme.surfaceContainerHighest,
                                 child: const Icon(Icons.inventory_2),
                               ),
                         ),
                         title: Text(product.name),
                         subtitle: Text('${product.stockQuantity} in stock'),
                         trailing: Text('\$${product.sellingPrice}'),
                         onTap: () {
                           _showUnitSelectionDialog(product);
                           _searchController.clear();
                           setState(() {});
                         },
                       );
                     },
                   );
                 },
               ),
             ),

          const Divider(),
          const Padding(
            padding: EdgeInsets.all(8.0),
            child: Text('Current Cart', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          ),
          
          // Cart List
          Expanded(
            flex: 2,
            child: Consumer<CartViewModel>(
              builder: (context, cart, child) {
                if (cart.items.isEmpty) {
                  return const Center(child: Text('Cart is empty'));
                }
                return ListView.builder(
                  itemCount: cart.items.length,
                  itemBuilder: (context, index) {
                    final item = cart.items[index];
                    // Calculate available stock in the selected unit
                    final double stockInSelectedUnit = item.product.getStockInUnit(item.unit);
                    final String unitName = item.unit?.name ?? item.product.unit;
                    
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      child: ListTile(
                        leading: ClipRRect(
                           borderRadius: BorderRadius.circular(8.0),
                           child: item.product.imagePath != null 
                             ? Image.file(File(item.product.imagePath!), width: 50, height: 50, fit: BoxFit.cover) 
                             : Container(
                                 width: 50, height: 50,
                                 color: Theme.of(context).colorScheme.surfaceContainerHighest,
                                 child: const Icon(Icons.shopping_bag),
                               ),
                        ),
                        title: Text('${item.product.name} ($unitName)'),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('\$${item.subtotal.toStringAsFixed(2)}'),
                            // Stock Left Display (Requested Feature)
                            Text(
                              'Stock Left: ${(stockInSelectedUnit - item.quantity).toStringAsFixed(1)} $unitName',
                              style: TextStyle(
                                color: (stockInSelectedUnit - item.quantity) < 0 ? Colors.red : Colors.green,
                                fontWeight: FontWeight.bold,
                                fontSize: 12
                              ),
                            ),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.remove_circle_outline),
                              onPressed: () => cart.removeFromCart(item.product, unit: item.unit),
                            ),
                            SizedBox(
                              width: 30, // Fixed width for quantity
                              child: Text('${item.quantity}', textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold)),
                            ),
                            IconButton(
                              icon: const Icon(Icons.add_circle_outline),
                              onPressed: () {
                                // Check stock before adding visually?
                                // Logic in VM handles updates, but UI feedback is good.
                                cart.addToCart(item.product, unit: item.unit);
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          
          // Checkout Area
          Consumer<CartViewModel>(
            builder: (context, cart, child) {
              return Container(
                padding: const EdgeInsets.all(16.0),
                color: Theme.of(context).colorScheme.surfaceContainer,
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Total:', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                        Text('\$${cart.totalAmount.toStringAsFixed(2)}', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary)),
                      ],
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        onPressed: cart.items.isEmpty ? null : () async {
                           // Validate selling price
                           for(var item in cart.items) {
                             if(item.product.sellingPrice <= 0 && (item.unit == null || (item.unit!.sellingPrice == null || item.unit!.sellingPrice! <= 0))) {
                               ScaffoldMessenger.of(context).showSnackBar(
                                 SnackBar(content: Text('Cannot checkout: ${item.product.name} has no selling price!')),
                               );
                               return;
                             }
                           }

                           // Capture items before checkout clears them if we want to print
                           final currentItems = List<CartItem>.from(cart.items);
                           final total = cart.totalAmount;

                           bool success = await cart.checkout();
                           if (success && context.mounted) {
                             ScaffoldMessenger.of(context).showSnackBar(
                               const SnackBar(content: Text('Transaction Completed!')),
                             );
                             context.read<ProductViewModel>().fetchProducts();
                             
                             // Ask for receipt
                             showDialog(
                               context: context,
                               builder: (context) => AlertDialog(
                                 title: const Text('Transaction Successful'),
                                 content: const Text('Do you want to print a receipt?'),
                                 actions: [
                                   TextButton(
                                     onPressed: () => Navigator.pop(context),
                                     child: const Text('No'),
                                   ),
                                   TextButton(
                                     onPressed: () {
                                       Navigator.pop(context);
                                       PdfGenerator.generateAndPrintReceipt(currentItems, total);
                                     },
                                     child: const Text('Print'),
                                   ),
                                 ],
                               ),
                             );
                           }
                        },
                        child: const Text('CHECKOUT', style: TextStyle(fontSize: 18)),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
