import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import '../../theme/app_spacing.dart';
import '../../widgets/common/empty_state.dart';

/// Dialog for viewing and recalling held transactions
class HeldTransactionsDialog extends StatelessWidget {
  final List<Map<String, dynamic>> heldTransactions;
  final Function(String holdId) onRecall;
  final Function(String holdId) onDelete;

  const HeldTransactionsDialog({
    super.key,
    required this.heldTransactions,
    required this.onRecall,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (heldTransactions.isEmpty) {
      return AlertDialog(
        title: const Text('Held Transactions'),
        content: const SizedBox(
          height: 200,
          child: EmptyState(
            message: 'No held transactions',
            icon: Icons.inbox_outlined,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      );
    }

    return AlertDialog(
      title: const Text('Held Transactions'),
      content: SizedBox(
        width: double.maxFinite,
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: heldTransactions.length,
          itemBuilder: (context, index) {
            final held = heldTransactions[index];
            final holdId = held['id'] as String;
            final customerName = held['customer_name'] as String?;
            final createdAt = DateTime.parse(held['created_at'] as String);
            final notes = held['notes'] as String?;
            final cartDataJson = held['cart_data'] as String;
            final cartData = jsonDecode(cartDataJson) as Map<String, dynamic>;
            final items = cartData['items'] as List;
            final itemCount = items.length;

            // Calculate total
            double total = 0;
            for (var item in items) {
              final quantity = item['quantity'] as int;
              final product = item['product'] as Map<String, dynamic>;
              final price = (product['sellingPrice'] as num).toDouble();
              total += quantity * price;
            }

            return Card(
              margin: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
              child: ListTile(
                leading: CircleAvatar(
                  child: Text('$itemCount'),
                ),
                title: Text(
                  customerName ?? 'No Customer',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(DateFormat('MMM d, yyyy h:mm a').format(createdAt)),
                    Text('\$${total.toStringAsFixed(2)}'),
                    if (notes != null && notes.isNotEmpty)
                      Text(
                        notes,
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                  ],
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.restore),
                      onPressed: () {
                        Navigator.pop(context);
                        onRecall(holdId);
                      },
                      tooltip: 'Recall',
                      color: theme.colorScheme.primary,
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () {
                        Navigator.pop(context);
                        onDelete(holdId);
                      },
                      tooltip: 'Delete',
                      color: theme.colorScheme.error,
                    ),
                  ],
                ),
                isThreeLine: true,
              ),
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    );
  }
}
