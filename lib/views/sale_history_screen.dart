import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../view_models/history_view_model.dart';

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

  void _showDeleteConfirmation(String date, double amount) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Void Sale'),
        content: Text('Are you sure you want to delete this sale of \$${amount.toStringAsFixed(2)}? \n\nThis will restore the items to stock and reverse the revenue.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await context.read<HistoryViewModel>().deleteSale(date);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Sale Voided')));
              }
            },
            child: const Text('Void', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showSaleDetails(String date) {
    showModalBottomSheet(
      context: context,
      builder: (context) => FutureBuilder<List<Map<String, dynamic>>>(
        future: context.read<HistoryViewModel>().getSaleDetails(date),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          
          final items = snapshot.data!;
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text('Sale Details', style: Theme.of(context).textTheme.headlineSmall),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return ListTile(
                      title: Text(item['product_name']),
                      subtitle: Text('${item['quantity']} items'),
                      trailing: Text('\$${item['selling_price']} each'),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sales History')),
      body: Consumer<HistoryViewModel>(
        builder: (context, vm, child) {
          if (vm.sales.isEmpty) {
            return const Center(child: Text('No sales history.'));
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
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  leading: const CircleAvatar(child: Icon(Icons.receipt)),
                  title: Text(DateFormat('MMM dd, yyyy - hh:mm a').format(date)),
                  subtitle: Text('$count items'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('\$${amount.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      PopupMenuButton(
                        itemBuilder: (context) => [
                          const PopupMenuItem(value: 'details', child: Text('View Details')),
                          const PopupMenuItem(value: 'delete', child: Text('Void Sale', style: TextStyle(color: Colors.red))),
                        ],
                        onSelected: (value) {
                          if (value == 'delete') {
                            _showDeleteConfirmation(dateStr, amount);
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
