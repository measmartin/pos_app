import 'package:flutter/material.dart';
import '../../theme/app_spacing.dart';

class LowStockAlert extends StatelessWidget {
  final int lowStockCount;
  final VoidCallback onTap;

  const LowStockAlert({
    super.key,
    required this.lowStockCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (lowStockCount == 0) return const SizedBox.shrink();

    return Card(
      color: Colors.orange.shade50,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              Icon(
                Icons.warning_amber_rounded,
                color: Colors.orange.shade800,
                size: 32,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Low Stock Alert',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.orange.shade900,
                          ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      '$lowStockCount ${lowStockCount == 1 ? 'product needs' : 'products need'} restocking',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.orange.shade800,
                          ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: Colors.orange.shade800,
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
