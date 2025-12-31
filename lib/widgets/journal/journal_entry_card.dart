import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../theme/app_spacing.dart';
import 'accounting_table.dart';

/// A card widget for displaying a journal entry with its header and lines.
///
/// This widget displays a complete journal entry including date, description,
/// reference type, and the double-entry accounting table.
///
/// Example:
/// ```dart
/// JournalEntryCard(
///   date: DateTime.now(),
///   description: 'Sale Transaction #123',
///   referenceType: 'SALE',
///   lines: journalLines,
/// )
/// ```
class JournalEntryCard extends StatelessWidget {
  /// Date of the journal entry
  final DateTime date;

  /// Description of the transaction
  final String description;

  /// Reference type (e.g., 'SALE', 'PURCHASE', 'JOURNAL')
  final String? referenceType;

  /// List of journal line entries
  final List<Map<String, dynamic>> lines;

  /// Currency symbol to display
  final String currencySymbol;

  /// Optional callback when card is tapped
  final VoidCallback? onTap;

  /// Creates a journal entry card
  const JournalEntryCard({
    super.key,
    required this.date,
    required this.description,
    this.referenceType,
    required this.lines,
    this.currencySymbol = '\$',
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Card(
      margin: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row with date and reference type
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    DateFormat('MMM dd, yyyy - hh:mm a').format(date),
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  if (referenceType != null)
                    Chip(
                      label: Text(
                        referenceType!,
                        style: theme.textTheme.labelSmall,
                      ),
                      visualDensity: VisualDensity.compact,
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              // Description
              Text(
                description,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              const Divider(),
              const SizedBox(height: AppSpacing.sm),
              // Accounting table with lines
              AccountingTable(
                lines: lines,
                currencySymbol: currencySymbol,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
