import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../view_models/product_view_model.dart';
import 'add_product_screen.dart';

class ProductListScreen extends StatefulWidget {
  const ProductListScreen({super.key});

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  @override
  void initState() {
    super.initState();
    // Fetch products when screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProductViewModel>().fetchProducts();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Products'),
      ),
      body: Consumer<ProductViewModel>(
        builder: (context, viewModel, child) {
          if (viewModel.products.isEmpty) {
            return const Center(child: Text('No products found. Add one!'));
          }
          return GridView.builder(
            padding: const EdgeInsets.all(8.0),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.75, // Adjust based on content
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            itemCount: viewModel.products.length,
            itemBuilder: (context, index) {
              final product = viewModel.products[index];
              return Card(
                clipBehavior: Clip.antiAlias,
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: InkWell(
                  onTap: () {
                    // Navigate to edit (reuse add screen with arguments)
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AddProductScreen(product: product),
                        fullscreenDialog: true,
                      ),
                    );
                  },
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Product Image
                      Expanded(
                        child: product.imagePath != null
                            ? Image.file(
                                File(product.imagePath!),
                                fit: BoxFit.cover,
                              )
                            : Container(
                                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                                child: Icon(
                                  Icons.inventory_2,
                                  size: 48,
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                ),
                              ),
                      ),
                      // Product Details
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              product.name,
                              style: Theme.of(context).textTheme.titleMedium,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '\$${product.sellingPrice.toStringAsFixed(2)}',
                              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(context).colorScheme.primary,
                                  ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Stock: ${product.stockQuantity} ${product.unit}',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                      // Actions (Delete)
                      Align(
                        alignment: Alignment.centerRight,
                        child: Padding(
                          padding: const EdgeInsets.only(right: 4.0, bottom: 4.0),
                          child: IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () {
                              viewModel.deleteProduct(product.id!);
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const AddProductScreen(),
              fullscreenDialog: true,
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
