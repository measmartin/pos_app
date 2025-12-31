import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// A widget that displays journal entries in a double-entry accounting table format.
///
/// This widget shows accounts with their corresponding debit and credit amounts.
///
/// Example:
/// ```dart
/// AccountingTable(
///   lines: journalLines,
///   currencySymbol: '\$',
/// )
/// ```
class AccountingTable extends StatelessWidget {
  /// List of journal line entries
  final List<Map<String, dynamic>> lines;

  /// Currency symbol to display
  final String currencySymbol;

  /// Creates an accounting table
  const AccountingTable({
    super.key,
    required this.lines,
    this.currencySymbol = '\$',
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Table(
      columnWidths: const {
        0: FlexColumnWidth(2), // Account Name
        1: FlexColumnWidth(1), // Debit
        2: FlexColumnWidth(1), // Credit
      },
      children: [
        // Header row
        TableRow(
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Text(
                'Account',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Text(
                'Debit',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.right,
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Text(
                'Credit',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.right,
              ),
            ),
          ],
        ),
        // Data rows
        ...lines.map((line) {
          final accountName = line['account_name'] as String;
          final debit = (line['debit'] as num).toDouble();
          final credit = (line['credit'] as num).toDouble();
          
          return TableRow(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: Text(accountName),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: Text(
                  debit > 0
                      ? NumberFormat.currency(symbol: currencySymbol).format(debit)
                      : '',
                  textAlign: TextAlign.right,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: Text(
                  credit > 0
                      ? NumberFormat.currency(symbol: currencySymbol).format(credit)
                      : '',
                  textAlign: TextAlign.right,
                ),
              ),
            ],
          );
        }),
      ],
    );
  }
}
