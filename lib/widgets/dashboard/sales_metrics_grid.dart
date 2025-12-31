import 'package:flutter/material.dart';
import '../../view_models/journal_view_model.dart';
import '../../theme/app_spacing.dart';
import 'metric_card.dart';

/// A 2x2 grid of sales metric cards for the dashboard.
///
/// This widget displays Today, Week, Month, and Year sales metrics
/// in a consistent grid layout.
///
/// Example:
/// ```dart
/// SalesMetricsGrid(
///   viewModel: context.watch<JournalViewModel>(),
/// )
/// ```
class SalesMetricsGrid extends StatelessWidget {
  /// The journal view model that provides sales data
  final JournalViewModel viewModel;

  /// Creates a sales metrics grid
  const SalesMetricsGrid({
    super.key,
    required this.viewModel,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: MetricCard(
                title: 'Today\'s Sales',
                valueFuture: viewModel.getSalesToday(),
                icon: Icons.today,
                backgroundColor: theme.colorScheme.primaryContainer,
                foregroundColor: theme.colorScheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: MetricCard(
                title: 'This Week',
                valueFuture: viewModel.getSalesThisWeek(),
                icon: Icons.date_range,
                backgroundColor: theme.colorScheme.tertiaryContainer,
                foregroundColor: theme.colorScheme.onTertiaryContainer,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            Expanded(
              child: MetricCard(
                title: 'This Month',
                valueFuture: viewModel.getSalesThisMonth(),
                icon: Icons.calendar_view_month,
                backgroundColor: theme.colorScheme.secondaryContainer,
                foregroundColor: theme.colorScheme.onSecondaryContainer,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: MetricCard(
                title: 'This Year',
                valueFuture: viewModel.getSalesThisYear(),
                icon: Icons.calendar_today,
                backgroundColor: theme.colorScheme.errorContainer,
                foregroundColor: theme.colorScheme.onErrorContainer,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
