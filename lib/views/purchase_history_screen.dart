import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../view_models/history_view_model.dart';
import '../widgets/transaction/transaction_card.dart';
import '../widgets/common/empty_state.dart';
import '../widgets/dialogs/confirmation_dialog.dart';

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

  Future<void> _handleDeletePurchase(int id, String productName, double total) async {
    final confirmed = await ConfirmationDialog.show(
      context,
      title: 'Void Purchase',
      message: 'Are you sure you want to void this purchase of $productName?\n\nAmount: \$${total.toStringAsFixed(2)}\n\nThis will remove the stock.',
      confirmText: 'Void',
      isDangerous: true,
    );

    if (confirmed == true && mounted) {
      await context.read<HistoryViewModel>().deletePurchase(id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Purchase Voided')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Purchase History')),
      body: Consumer<HistoryViewModel>(
        builder: (context, vm, child) {
          if (vm.purchases.isEmpty) {
            return const EmptyState(
              icon: Icons.inventory_2_outlined,
              message: 'No purchase history yet\n\nPurchases will appear here',
            );
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

              return TransactionCard(
                type: TransactionType.purchase,
                productName: productName,
                quantity: quantity,
                price: cost,
                total: total,
                date: date,
                onDelete: () => _handleDeletePurchase(id, productName, total),
              );
            },
          );
        },
      ),
    );
  }
}
