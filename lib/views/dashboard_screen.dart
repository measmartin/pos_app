import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../view_models/journal_view_model.dart';
import '../view_models/product_view_model.dart';
import '../models/product.dart';
import 'purchase_screen.dart';
import 'pos_screen.dart';
import 'global_unit_manager_screen.dart';
import 'sale_history_screen.dart';
import 'purchase_history_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    // Refresh data when dashboard opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<JournalViewModel>().fetchEntries();
      context.read<ProductViewModel>().fetchProducts();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: 'Sales History',
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const SaleHistoryScreen()));
            },
          ),
          IconButton(
            icon: const Icon(Icons.receipt_long),
            tooltip: 'Purchase History',
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const PurchaseHistoryScreen()));
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'Manage Units',
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const GlobalUnitManagerScreen()));
            },
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Quick Actions
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () {
                      // Navigate to Sales (POS)
                      // Since we use bottom nav, this might be tricky if we want to switch tab.
                      // For now, push as a new screen or use global navigation key to switch tab.
                      // Given current structure, we can push the POSScreen directly for a "Quick Sale" mode
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const POSScreen()));
                    }, 
                    icon: const Icon(Icons.point_of_sale), 
                    label: const Text('New Sale'),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Theme.of(context).colorScheme.onPrimary,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const PurchaseScreen()));
                    }, 
                    icon: const Icon(Icons.shopping_cart_checkout), 
                    label: const Text('Purchase Stock'),
                     style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: Theme.of(context).colorScheme.tertiary,
                      foregroundColor: Theme.of(context).colorScheme.onTertiary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            Text(
              'Sales Overview',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16.0),
            _buildSalesCards(context),
            const SizedBox(height: 32.0),
            Text(
              'Trending Products',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16.0),
            _buildTrendingCarousel(context),
          ],
        ),
      ),
    );
  }

  Widget _buildSalesCards(BuildContext context) {
    return Consumer<JournalViewModel>(
      builder: (context, viewModel, child) {
        return Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: _buildSalesMetricCard(
                    context,
                    'Today\'s Sales',
                    viewModel.getSalesToday(),
                    Icons.today,
                    Theme.of(context).colorScheme.primaryContainer,
                    Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildSalesMetricCard(
                    context,
                    'This Week',
                    viewModel.getSalesThisWeek(),
                    Icons.date_range,
                    Theme.of(context).colorScheme.tertiaryContainer,
                    Theme.of(context).colorScheme.onTertiaryContainer,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildSalesMetricCard(
                    context,
                    'This Month',
                    viewModel.getSalesThisMonth(),
                    Icons.calendar_view_month,
                    Theme.of(context).colorScheme.secondaryContainer,
                    Theme.of(context).colorScheme.onSecondaryContainer,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildSalesMetricCard(
                    context,
                    'This Year',
                    viewModel.getSalesThisYear(),
                    Icons.calendar_today,
                    // Use a different color or reuse one
                    Theme.of(context).colorScheme.errorContainer,
                    Theme.of(context).colorScheme.onErrorContainer,
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildSalesMetricCard(
    BuildContext context, 
    String title, 
    Future<double> futureValue, 
    IconData icon,
    Color backgroundColor,
    Color foregroundColor,
  ) {
    return FutureBuilder<double>(
      future: futureValue,
      builder: (context, snapshot) {
        final amount = snapshot.data ?? 0.0;
        final formattedAmount = NumberFormat.currency(symbol: '\$').format(amount);

        return Card(
          elevation: 0,
          color: backgroundColor,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, color: foregroundColor),
                const SizedBox(height: 12),
                Text(
                  title,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: foregroundColor.withOpacity(0.8),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  formattedAmount,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: foregroundColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTrendingCarousel(BuildContext context) {
    return SizedBox(
      height: 200,
      child: FutureBuilder<List<Product>>(
        future: context.read<ProductViewModel>().fetchTrendingProducts(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Card(
                elevation: 0,
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                child: const Padding(
                  padding: EdgeInsets.all(32.0),
                  child: Text('No sales data yet to show trending products.'),
                ),
              ),
            );
          }

          final products = snapshot.data!;
          return ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: products.length,
            itemBuilder: (context, index) {
              final product = products[index];
              return Container(
                width: 160,
                margin: const EdgeInsets.only(right: 16.0),
                child: Card(
                  elevation: 2,
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.secondaryContainer,
                          ),
                          child: product.imagePath != null
                              ? Image.file(
                                  File(product.imagePath!),
                                  fit: BoxFit.cover,
                                )
                              : Center(
                                  child: Icon(
                                    Icons.shopping_bag,
                                    size: 48,
                                    color: Theme.of(context).colorScheme.onSecondaryContainer,
                                  ),
                                ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(12.0),
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
                              NumberFormat.currency(symbol: '\$').format(product.sellingPrice),
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
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
    );
  }
}
