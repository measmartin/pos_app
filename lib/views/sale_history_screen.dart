import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../view_models/history_view_model.dart';
import '../widgets/common/empty_state.dart';
import '../widgets/dialogs/confirmation_dialog.dart';
import '../theme/app_spacing.dart';
import 'return_screen.dart';

class SaleHistoryScreen extends StatefulWidget {
  const SaleHistoryScreen({super.key});

  @override
  State<SaleHistoryScreen> createState() => _SaleHistoryScreenState();
}

class _SaleHistoryScreenState extends State<SaleHistoryScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<HistoryViewModel>().fetchSales();
    });
  }

  Future<void> _handleDeleteSale(String date, double amount) async {
    final confirmed = await ConfirmationDialog.show(
      context,
      title: 'Void Sale',
      message: 'Are you sure you want to delete this sale of \$${amount.toStringAsFixed(2)}? \n\nThis will restore the items to stock and reverse the revenue.',
      confirmText: 'Void',
      isDangerous: true,
    );

    if (confirmed == true && mounted) {
      await context.read<HistoryViewModel>().deleteSale(date);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sale Voided')),
        );
      }
    }
  }

  void _showSaleDetails(String date) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => FutureBuilder<List<Map<String, dynamic>>>(
          future: context.read<HistoryViewModel>().getSaleDetails(date),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(AppSpacing.xl),
                  child: CircularProgressIndicator(),
                ),
              );
            }
            
            final items = snapshot.data!;
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Text(
                    'Sale Details',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    controller: scrollController,
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final item = items[index];
                      final productName = item['product_name'] as String;
                      final quantity = item['quantity'] as int;
                      final returnedQty = (item['returned_quantity'] as int?) ?? 0;
                      final availableToReturn = quantity - returnedQty;
                      final price = item['selling_price'] as double;
                      final total = quantity * price;
                      
                      return Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                          vertical: AppSpacing.xs,
                        ),
                        child: ListTile(
                          title: Text(productName),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('$quantity items × \$${price.toStringAsFixed(2)}'),
                              if (returnedQty > 0)
                                Text(
                                  'Returned: $returnedQty',
                                  style: TextStyle(
                                    color: Theme.of(context).colorScheme.error,
                                    fontSize: 12,
                                  ),
                                ),
                            ],
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    '\$${total.toStringAsFixed(2)}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                              if (availableToReturn > 0) ...[
                                const SizedBox(width: AppSpacing.sm),
                                IconButton(
                                  icon: const Icon(Icons.keyboard_return),
                                  onPressed: () async {
                                    if (!context.mounted) return;
                                    Navigator.pop(context); // Close bottom sheet
                                    final result = await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => ReturnScreen(saleItem: item),
                                      ),
                                    );
                                    if (result == true && context.mounted) {
                                      // Refresh the sale history
                                      if (context.mounted) {
                                        context.read<HistoryViewModel>().fetchSales();
                                      }
                                    }
                                  },
                                  tooltip: 'Return Item',
                                  color: Theme.of(context).colorScheme.error,
                                ),
                              ],
                            ],
                          ),
                          isThreeLine: returnedQty > 0,
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(title: const Text('Sales History')),
      body: Consumer<HistoryViewModel>(
        builder: (context, vm, child) {
          if (vm.sales.isEmpty) {
            return const EmptyState(
              icon: Icons.receipt_long_outlined,
              message: 'No sales history yet\n\nCompleted sales will appear here',
            );
          }
          return ListView.builder(
            itemCount: vm.sales.length,
            itemBuilder: (context, index) {
              final sale = vm.sales[index];
              final dateStr = sale['date'] as String;
              final amount = sale['total_amount'] as double;
              final count = sale['item_count'] as int;
              final date = DateTime.tryParse(dateStr) ?? DateTime.now();

              return Card(
                margin: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.sm,
                ),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: theme.colorScheme.primaryContainer,
                    foregroundColor: theme.colorScheme.onPrimaryContainer,
                    child: const Icon(Icons.receipt),
                  ),
                  title: Text(DateFormat('MMM dd, yyyy - hh:mm a').format(date)),
                  subtitle: Text('$count items'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '\$${amount.toStringAsFixed(2)}',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      PopupMenuButton(
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: 'details',
                            child: Text('View Details'),
                          ),
                          PopupMenuItem(
                            value: 'delete',
                            child: Text(
                              'Void Sale',
                              style: TextStyle(color: theme.colorScheme.error),
                            ),
                          ),
                        ],
                        onSelected: (value) {
                          if (value == 'delete') {
                            _handleDeleteSale(dateStr, amount);
                          } else if (value == 'details') {
                            _showSaleDetails(dateStr);
                          }
                        },
                      ),
                    ],
                  ),
                  onTap: () => _showSaleDetails(dateStr),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
