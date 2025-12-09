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
          return ListView.builder(
            itemCount: viewModel.products.length,
            itemBuilder: (context, index) {
              final product = viewModel.products[index];
              return ListTile(
                title: Text(product.name),
                subtitle: Text('Stock: ${product.stockQuantity} ${product.unit} | Price: \$${product.sellingPrice}'),
                trailing: IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () {
                    viewModel.deleteProduct(product.id!);
                  },
                ),
                onTap: () {
                  // Navigate to edit (reuse add screen with arguments)
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AddProductScreen(product: product),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddProductScreen()),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
