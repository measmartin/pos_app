import 'package:flutter/material.dart';
import 'package:pos_app/models/product.dart';
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

  void _addToCart(Product product) {
    context.read<CartViewModel>().addToCart(product);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('POS Terminal')),
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
                         title: Text(product.name),
                         subtitle: Text('${product.stockQuantity} in stock'),
                         trailing: Text('\$${product.sellingPrice}'),
                         onTap: () {
                           _addToCart(product);
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
                    return ListTile(
                      title: Text(item.product.name),
                      subtitle: Text('${item.quantity} x \$${item.product.sellingPrice}'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('\$${item.subtotal.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                          IconButton(
                            icon: const Icon(Icons.remove_circle_outline),
                            onPressed: () => cart.removeFromCart(item.product),
                          ),
                          IconButton(
                            icon: const Icon(Icons.add_circle_outline),
                            onPressed: () => cart.addToCart(item.product),
                          ),
                        ],
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
                color: Colors.grey[200],
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Total:', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                        Text('\$${cart.totalAmount.toStringAsFixed(2)}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.green)),
                      ],
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          backgroundColor: Theme.of(context).primaryColor,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: cart.items.isEmpty ? null : () async {
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
