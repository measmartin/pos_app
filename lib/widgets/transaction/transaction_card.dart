import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../theme/app_spacing.dart';

/// Type of transaction
enum TransactionType {
  /// Sale transaction
  sale,
  /// Purchase transaction
  purchase,
}

/// A card widget for displaying transaction history items.
///
/// Example:
/// ```dart
/// TransactionCard(
///   type: TransactionType.purchase,
///   productName: 'Widget',
///   quantity: 10,
///   price: 5.0,
///   total: 50.0,
///   date: DateTime.now(),
///   onDelete: () => deletePurchase(id),
/// )
/// ```
class TransactionCard extends StatelessWidget {
  /// The type of transaction
  final TransactionType type;

  /// Name of the product
  final String productName;

  /// Quantity purchased/sold
  final int quantity;

  /// Price per unit
  final double price;

  /// Total amount
  final double total;

  /// Date of the transaction
  final DateTime date;

  /// Optional callback to delete the transaction
  final VoidCallback? onDelete;

  /// Optional callback when card is tapped
  final VoidCallback? onTap;

  /// Optional unit name
  final String? unitName;

  /// Currency symbol
  final String currencySymbol;

  /// Creates a transaction card
  const TransactionCard({
    super.key,
    required this.type,
    required this.productName,
    required this.quantity,
    required this.price,
    required this.total,
    required this.date,
    this.onDelete,
    this.onTap,
    this.unitName,
    this.currencySymbol = '\$',
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final icon = type == TransactionType.purchase
        ? Icons.inventory_2
        : Icons.shopping_bag;
    
    return Card(
      margin: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm,
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: type == TransactionType.purchase
              ? theme.colorScheme.tertiaryContainer
              : theme.colorScheme.primaryContainer,
          foregroundColor: type == TransactionType.purchase
              ? theme.colorScheme.onTertiaryContainer
              : theme.colorScheme.onPrimaryContainer,
          child: Icon(icon),
        ),
        title: Text(productName),
        subtitle: Text(
          '$quantity ${unitName ?? 'units'} @ $currencySymbol${price.toStringAsFixed(2)}\n'
          '${DateFormat('MMM dd, hh:mm a').format(date)}',
        ),
        isThreeLine: true,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '$currencySymbol${total.toStringAsFixed(2)}',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            if (onDelete != null) ...[
              const SizedBox(width: AppSpacing.sm),
              IconButton(
                icon: Icon(
                  Icons.delete,
                  color: theme.colorScheme.error,
                ),
                onPressed: onDelete,
                tooltip: 'Delete transaction',
              ),
            ],
          ],
        ),
        onTap: onTap,
      ),
    );
  }
}
