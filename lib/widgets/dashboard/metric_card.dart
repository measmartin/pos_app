import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_elevation.dart';

/// A card widget that displays a sales metric with icon and value.
///
/// Example:
/// ```dart
/// MetricCard(
///   title: 'Today\'s Sales',
///   valueFuture: viewModel.getSalesToday(),
///   icon: Icons.today,
///   backgroundColor: theme.colorScheme.primaryContainer,
///   foregroundColor: theme.colorScheme.onPrimaryContainer,
/// )
/// ```
class MetricCard extends StatelessWidget {
  /// The title of the metric
  final String title;

  /// Future that provides the metric value
  final Future<double> valueFuture;

  /// Icon to display
  final IconData icon;

  /// Background color for the card
  final Color? backgroundColor;

  /// Foreground color for text and icon
  final Color? foregroundColor;

  /// Currency symbol to use (defaults to '$')
  final String currencySymbol;

  /// Whether to show loading indicator
  final bool showLoading;

  /// Creates a metric card
  const MetricCard({
    super.key,
    required this.title,
    required this.valueFuture,
    required this.icon,
    this.backgroundColor,
    this.foregroundColor,
    this.currencySymbol = '\$',
    this.showLoading = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bgColor = backgroundColor ?? theme.colorScheme.primaryContainer;
    final fgColor = foregroundColor ?? theme.colorScheme.onPrimaryContainer;

    return FutureBuilder<double>(
      future: valueFuture,
      builder: (context, snapshot) {
        final amount = snapshot.data ?? 0.0;
        final formattedAmount = NumberFormat.currency(symbol: currencySymbol).format(amount);
        final isLoading = snapshot.connectionState == ConnectionState.waiting;

        return Card(
          elevation: AppElevation.none,
          color: bgColor,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, color: fgColor),
                const SizedBox(height: AppSpacing.md),
                Text(
                  title,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: fgColor.withValues(alpha: 0.8),
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                if (isLoading && showLoading)
                  SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: fgColor,
                    ),
                  )
                else
                  Text(
                    formattedAmount,
                    style: theme.textTheme.headlineMedium?.copyWith(
                      color: fgColor,
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
}
