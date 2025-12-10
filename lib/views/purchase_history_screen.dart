import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../view_models/history_view_model.dart';

class PurchaseHistoryScreen extends StatefulWidget {
  const PurchaseHistoryScreen({super.key});

  @override
  State<PurchaseHistoryScreen> createState() => _PurchaseHistoryScreenState();
}

class _PurchaseHistoryScreenState extends State<PurchaseHistoryScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<HistoryViewModel>().fetchPurchases();
    });
  }

  void _showDeleteConfirmation(int id, String productName, double total) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Void Purchase'),
        content: Text('Are you sure you want to void this purchase of $productName?\n\nAmount: \$${total.toStringAsFixed(2)}\n\nThis will remove the stock.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await context.read<HistoryViewModel>().deletePurchase(id);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Purchase Voided')));
              }
            },
            child: const Text('Void', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Purchase History')),
      body: Consumer<HistoryViewModel>(
        builder: (context, vm, child) {
          if (vm.purchases.isEmpty) {
            return const Center(child: Text('No purchase history.'));
          }
          return ListView.builder(
            itemCount: vm.purchases.length,
            itemBuilder: (context, index) {
              final purchase = vm.purchases[index];
              final id = purchase['id'] as int;
              final dateStr = purchase['date'] as String;
              final date = DateTime.tryParse(dateStr) ?? DateTime.now();
              final productName = purchase['product_name'] as String;
              final quantity = purchase['quantity'] as int;
              final cost = purchase['cost_price'] as double;
              final total = quantity * cost;

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  leading: const CircleAvatar(child: Icon(Icons.inventory_2)),
                  title: Text(productName),
                  subtitle: Text('$quantity units @ \$$cost\n${DateFormat('MMM dd, hh:mm a').format(date)}'),
                  isThreeLine: true,
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('\$${total.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _showDeleteConfirmation(id, productName, total),
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
