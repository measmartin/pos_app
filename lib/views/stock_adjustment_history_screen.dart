import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/stock_adjustment.dart';
import '../models/product.dart';
import '../view_models/stock_adjustment_view_model.dart';
import '../view_models/product_view_model.dart';
import '../widgets/common/empty_state.dart';
import '../theme/app_spacing.dart';

class StockAdjustmentHistoryScreen extends StatefulWidget {
  final int? productId;

  const StockAdjustmentHistoryScreen({
    super.key,
    this.productId,
  });

  @override
  State<StockAdjustmentHistoryScreen> createState() =>
      _StockAdjustmentHistoryScreenState();
}

class _StockAdjustmentHistoryScreenState
    extends State<StockAdjustmentHistoryScreen> {
  AdjustmentType? _selectedType;
  AdjustmentReason? _selectedReason;
  DateTime? _startDate;
  DateTime? _endDate;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final adjustmentViewModel =
        Provider.of<StockAdjustmentViewModel>(context, listen: false);
    final productViewModel =
        Provider.of<ProductViewModel>(context, listen: false);

    await Future.wait([
      adjustmentViewModel.fetchAdjustments(),
      productViewModel.fetchProducts(),
    ]);

    setState(() => _isLoading = false);
  }

  List<_AdjustmentWithProduct> _getFilteredAdjustments(
    List<StockAdjustment> adjustments,
    List<Product> products,
  ) {
    // Filter by product ID if specified
    var filtered = widget.productId != null
        ? adjustments.where((a) => a.productId == widget.productId).toList()
        : adjustments;

    // Apply filters
    if (_selectedType != null) {
      filtered = filtered.where((a) => a.type == _selectedType).toList();
    }

    if (_selectedReason != null) {
      filtered = filtered.where((a) => a.reason == _selectedReason).toList();
    }

    if (_startDate != null) {
      filtered = filtered
          .where((a) => a.date.isAfter(_startDate!) || 
                       a.date.isAtSameMomentAs(_startDate!))
          .toList();
    }

    if (_endDate != null) {
      final endOfDay = DateTime(
        _endDate!.year,
        _endDate!.month,
        _endDate!.day,
        23,
        59,
        59,
      );
      filtered = filtered
          .where((a) => a.date.isBefore(endOfDay) || 
                       a.date.isAtSameMomentAs(endOfDay))
          .toList();
    }

    // Map to include product data
    return filtered.map((adjustment) {
      final product = products.firstWhere(
        (p) => p.id == adjustment.productId,
        orElse: () => Product(
          name: 'Unknown Product',
          barcode: '',
          costPrice: 0,
          sellingPrice: 0,
          stockQuantity: 0,
          unit: 'pcs',
        ),
      );
      return _AdjustmentWithProduct(adjustment, product);
    }).toList();
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => _FilterDialog(
        selectedType: _selectedType,
        selectedReason: _selectedReason,
        startDate: _startDate,
        endDate: _endDate,
        onApply: (type, reason, start, end) {
          setState(() {
            _selectedType = type;
            _selectedReason = reason;
            _startDate = start;
            _endDate = end;
          });
        },
      ),
    );
  }

  void _clearFilters() {
    setState(() {
      _selectedType = null;
      _selectedReason = null;
      _startDate = null;
      _endDate = null;
    });
  }

  bool get _hasActiveFilters =>
      _selectedType != null ||
      _selectedReason != null ||
      _startDate != null ||
      _endDate != null;

  @override
  Widget build(BuildContext context) {
    final adjustmentViewModel = Provider.of<StockAdjustmentViewModel>(context);
    final productViewModel = Provider.of<ProductViewModel>(context);

    final filteredAdjustments = _getFilteredAdjustments(
      adjustmentViewModel.adjustments,
      productViewModel.products,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.productId != null
            ? 'Product Adjustment History'
            : 'Stock Adjustment History'),
        actions: [
          if (_hasActiveFilters)
            IconButton(
              icon: const Icon(Icons.clear),
              onPressed: _clearFilters,
              tooltip: 'Clear Filters',
            ),
          IconButton(
            icon: Badge(
              isLabelVisible: _hasActiveFilters,
              child: const Icon(Icons.filter_list),
            ),
            onPressed: _showFilterDialog,
            tooltip: 'Filter',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: filteredAdjustments.isEmpty
                  ? EmptyState(
                      icon: Icons.history,
                      message: _hasActiveFilters
                          ? 'No adjustments match your filters'
                          : 'No stock adjustments yet',
                      actionLabel: _hasActiveFilters ? 'Clear Filters' : null,
                      onAction: _hasActiveFilters ? _clearFilters : null,
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      itemCount: filteredAdjustments.length,
                      itemBuilder: (context, index) {
                        final item = filteredAdjustments[index];
                        return _AdjustmentCard(
                          adjustment: item.adjustment,
                          product: item.product,
                        );
                      },
                    ),
            ),
    );
  }
}

class _AdjustmentWithProduct {
  final StockAdjustment adjustment;
  final Product product;

  _AdjustmentWithProduct(this.adjustment, this.product);
}

class _AdjustmentCard extends StatelessWidget {
  final StockAdjustment adjustment;
  final Product product;

  const _AdjustmentCard({
    required this.adjustment,
    required this.product,
  });

  IconData _getTypeIcon(AdjustmentType type) {
    switch (type) {
      case AdjustmentType.addition:
        return Icons.add_circle_outline;
      case AdjustmentType.subtraction:
        return Icons.remove_circle_outline;
      case AdjustmentType.correction:
        return Icons.edit;
      case AdjustmentType.damage:
        return Icons.broken_image;
      case AdjustmentType.theft:
        return Icons.warning;
      case AdjustmentType.returned:
        return Icons.undo;
      case AdjustmentType.other:
        return Icons.more_horiz;
    }
  }

  Color _getTypeColor(BuildContext context, AdjustmentType type) {
    final colorScheme = Theme.of(context).colorScheme;
    switch (type) {
      case AdjustmentType.addition:
      case AdjustmentType.returned:
        return colorScheme.primary;
      case AdjustmentType.subtraction:
      case AdjustmentType.damage:
      case AdjustmentType.theft:
        return colorScheme.error;
      case AdjustmentType.correction:
        return colorScheme.tertiary;
      case AdjustmentType.other:
        return colorScheme.secondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isPositive = adjustment.quantityChange > 0;
    final changeColor = isPositive ? theme.colorScheme.primary : theme.colorScheme.error;
    final changeIcon = isPositive ? Icons.arrow_upward : Icons.arrow_downward;
    final dateFormat = DateFormat('MMM d, y h:mm a');

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          // Could show details dialog here
        },
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: Product name and date
              Row(
                children: [
                  Expanded(
                    child: Text(
                      product.name,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Icon(
                    _getTypeIcon(adjustment.type),
                    color: _getTypeColor(context, adjustment.type),
                    size: 24,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              
              // Date
              Text(
                dateFormat.format(adjustment.date),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              
              const SizedBox(height: AppSpacing.sm),
              const Divider(),
              const SizedBox(height: AppSpacing.sm),
              
              // Adjustment details
              Row(
                children: [
                  // Type and Reason
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _InfoChip(
                          label: 'Type',
                          value: adjustment.type.displayName,
                          color: _getTypeColor(context, adjustment.type),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        _InfoChip(
                          label: 'Reason',
                          value: adjustment.reason.displayName,
                          color: theme.colorScheme.secondary,
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(width: AppSpacing.md),
                  
                  // Quantity change
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.sm,
                    ),
                    decoration: BoxDecoration(
                      color: changeColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              changeIcon,
                              color: changeColor,
                              size: 20,
                            ),
                            const SizedBox(width: AppSpacing.xs),
                            Text(
                              '${isPositive ? '+' : ''}${adjustment.quantityChange}',
                              style: theme.textTheme.titleLarge?.copyWith(
                                color: changeColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          product.unit,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: changeColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: AppSpacing.sm),
              
              // Stock levels
              Row(
                children: [
                  _StockBadge(
                    label: 'Old',
                    value: adjustment.oldQuantity,
                    unit: product.unit,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Icon(
                    Icons.arrow_forward,
                    size: 16,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  _StockBadge(
                    label: 'New',
                    value: adjustment.newQuantity,
                    unit: product.unit,
                  ),
                ],
              ),
              
              // Notes (if any)
              if (adjustment.notes != null && adjustment.notes!.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.sm),
                Container(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.note,
                        size: 16,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Expanded(
                        child: Text(
                          adjustment.notes!,
                          style: theme.textTheme.bodySmall,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _InfoChip({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Text(
          '$label: ',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: 2,
          ),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: color.withValues(alpha: 0.3)),
                  ),
          child: Text(
            value,
            style: theme.textTheme.bodySmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class _StockBadge extends StatelessWidget {
  final String label;
  final int value;
  final String unit;

  const _StockBadge({
    required this.label,
    required this.value,
    required this.unit,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        Text(
          '$value $unit',
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _FilterDialog extends StatefulWidget {
  final AdjustmentType? selectedType;
  final AdjustmentReason? selectedReason;
  final DateTime? startDate;
  final DateTime? endDate;
  final Function(
    AdjustmentType?,
    AdjustmentReason?,
    DateTime?,
    DateTime?,
  ) onApply;

  const _FilterDialog({
    this.selectedType,
    this.selectedReason,
    this.startDate,
    this.endDate,
    required this.onApply,
  });

  @override
  State<_FilterDialog> createState() => _FilterDialogState();
}

class _FilterDialogState extends State<_FilterDialog> {
  late AdjustmentType? _selectedType;
  late AdjustmentReason? _selectedReason;
  late DateTime? _startDate;
  late DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    _selectedType = widget.selectedType;
    _selectedReason = widget.selectedReason;
    _startDate = widget.startDate;
    _endDate = widget.endDate;
  }

  Future<void> _pickDate(bool isStart) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: (isStart ? _startDate : _endDate) ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
        } else {
          _endDate = picked;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('MMM d, y');

    return AlertDialog(
      title: const Text('Filter Adjustments'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Type filter
            Text(
              'Adjustment Type',
              style: theme.textTheme.titleSmall,
            ),
            const SizedBox(height: AppSpacing.xs),
            DropdownButtonFormField<AdjustmentType?>(
              initialValue: _selectedType,
              decoration: const InputDecoration(
                hintText: 'All Types',
                isDense: true,
              ),
              items: [
                const DropdownMenuItem(value: null, child: Text('All Types')),
                ...AdjustmentType.values.map((type) {
                  return DropdownMenuItem(
                    value: type,
                    child: Text(type.displayName),
                  );
                }),
              ],
              onChanged: (value) => setState(() => _selectedType = value),
            ),
            
            const SizedBox(height: AppSpacing.md),
            
            // Reason filter
            Text(
              'Adjustment Reason',
              style: theme.textTheme.titleSmall,
            ),
            const SizedBox(height: AppSpacing.xs),
            DropdownButtonFormField<AdjustmentReason?>(
              initialValue: _selectedReason,
              decoration: const InputDecoration(
                hintText: 'All Reasons',
                isDense: true,
              ),
              items: [
                const DropdownMenuItem(value: null, child: Text('All Reasons')),
                ...AdjustmentReason.values.map((reason) {
                  return DropdownMenuItem(
                    value: reason,
                    child: Text(reason.displayName),
                  );
                }),
              ],
              onChanged: (value) => setState(() => _selectedReason = value),
            ),
            
            const SizedBox(height: AppSpacing.md),
            
            // Date range
            Text(
              'Date Range',
              style: theme.textTheme.titleSmall,
            ),
            const SizedBox(height: AppSpacing.xs),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _pickDate(true),
                    icon: const Icon(Icons.calendar_today, size: 16),
                    label: Text(
                      _startDate != null
                          ? dateFormat.format(_startDate!)
                          : 'Start Date',
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _pickDate(false),
                    icon: const Icon(Icons.calendar_today, size: 16),
                    label: Text(
                      _endDate != null
                          ? dateFormat.format(_endDate!)
                          : 'End Date',
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                ),
              ],
            ),
            if (_startDate != null || _endDate != null) ...[
              const SizedBox(height: AppSpacing.xs),
              TextButton.icon(
                onPressed: () {
                  setState(() {
                    _startDate = null;
                    _endDate = null;
                  });
                },
                icon: const Icon(Icons.clear, size: 16),
                label: const Text('Clear Dates'),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            widget.onApply(
              _selectedType,
              _selectedReason,
              _startDate,
              _endDate,
            );
            Navigator.pop(context);
          },
          child: const Text('Apply'),
        ),
      ],
    );
  }
}
