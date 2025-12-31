import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../view_models/product_view_model.dart';
import '../widgets/product/product_card.dart';
import '../widgets/common/empty_state.dart';
import '../widgets/dialogs/confirmation_dialog.dart';
import '../widgets/dialogs/stock_adjustment_dialog.dart';
import '../theme/app_spacing.dart';
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
            return EmptyState(
              message: 'No products found. Add one!',
              icon: Icons.inventory_2,
              actionLabel: 'Add Product',
              onAction: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const AddProductScreen(),
                    fullscreenDialog: true,
                  ),
                );
              },
            );
          }
          
          return GridView.builder(
            padding: const EdgeInsets.all(AppSpacing.sm),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.75,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            itemCount: viewModel.products.length,
            itemBuilder: (context, index) {
              final product = viewModel.products[index];
              return ProductCard(
                product: product,
                layout: ProductCardLayout.grid,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AddProductScreen(product: product),
                      fullscreenDialog: true,
                    ),
                  );
                },
                onAdjustStock: () async {
                  await showDialog(
                    context: context,
                    builder: (_) => StockAdjustmentDialog(product: product),
                  );
                },
                onDelete: () async {
                  final confirmed = await ConfirmationDialog.show(
                    context,
                    title: 'Delete Product',
                    message: 'Are you sure you want to delete "${product.name}"? This action cannot be undone.',
                    confirmText: 'Delete',
                    icon: Icons.delete_outline,
                    isDestructive: true,
                  );
                  
                  if (confirmed && context.mounted) {
                    await viewModel.deleteProduct(product.id!);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('${product.name} deleted')),
                      );
                    }
                  }
                },
                showStock: true,
                showPrice: true,
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
