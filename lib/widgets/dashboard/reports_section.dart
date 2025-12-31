import 'package:flutter/material.dart';
import '../../theme/app_spacing.dart';

class ReportsSection extends StatelessWidget {
  final VoidCallback onSalesReportTap;
  final VoidCallback onInventoryReportTap;
  final VoidCallback onFinancialReportTap;
  final VoidCallback? onAdjustmentHistoryTap;

  const ReportsSection({
    super.key,
    required this.onSalesReportTap,
    required this.onInventoryReportTap,
    required this.onFinancialReportTap,
    this.onAdjustmentHistoryTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Reports',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            Expanded(
              child: _ReportCard(
                icon: Icons.bar_chart,
                label: 'Sales',
                color: Colors.green,
                onTap: onSalesReportTap,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: _ReportCard(
                icon: Icons.inventory,
                label: 'Inventory',
                color: Colors.blue,
                onTap: onInventoryReportTap,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            Expanded(
              child: _ReportCard(
                icon: Icons.account_balance,
                label: 'Financial',
                color: Colors.purple,
                onTap: onFinancialReportTap,
              ),
            ),
            if (onAdjustmentHistoryTap != null) ...[
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: _ReportCard(
                  icon: Icons.history,
                  label: 'Adjustments',
                  color: Colors.orange,
                  onTap: onAdjustmentHistoryTap!,
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

class _ReportCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ReportCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            children: [
              CircleAvatar(
                backgroundColor: color.withValues(alpha: 0.15),
                radius: 24,
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                label,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
