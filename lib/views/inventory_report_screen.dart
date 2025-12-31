import 'package:flutter/material.dart';
import '../models/report_models.dart';
import '../services/report_service.dart';
import '../theme/app_spacing.dart';
import '../widgets/common/empty_state.dart';
import 'stock_adjustment_history_screen.dart';

class InventoryReportScreen extends StatefulWidget {
  const InventoryReportScreen({super.key});

  @override
  State<InventoryReportScreen> createState() => _InventoryReportScreenState();
}

class _InventoryReportScreenState extends State<InventoryReportScreen> {
  final ReportService _reportService = ReportService();
  
  List<InventoryReportData> _inventoryData = [];
  bool _showLowStockOnly = false;
  bool _isLoading = false;
  final int _lowStockThreshold = 10;

  String _sortBy = 'name'; // name, stock, value
  bool _sortAscending = true;

  @override
  void initState() {
    super.initState();
    _loadReport();
  }

  Future<void> _loadReport() async {
    setState(() => _isLoading = true);

    try {
      final data = await _reportService.getInventoryReport(
        lowStockOnly: _showLowStockOnly,
        lowStockThreshold: _lowStockThreshold,
      );

      setState(() {
        _inventoryData = _sortInventoryData(data);
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading report: $e')),
        );
      }
    }
  }

  List<InventoryReportData> _sortInventoryData(List<InventoryReportData> data) {
    final sorted = List<InventoryReportData>.from(data);
    
    sorted.sort((a, b) {
      int comparison;
      switch (_sortBy) {
        case 'stock':
          comparison = a.currentStock.compareTo(b.currentStock);
          break;
        case 'value':
          comparison = a.stockValue.compareTo(b.stockValue);
          break;
        case 'name':
        default:
          comparison = a.productName.compareTo(b.productName);
      }
      return _sortAscending ? comparison : -comparison;
    });

    return sorted;
  }

  void _changeSortBy(String newSortBy) {
    setState(() {
      if (_sortBy == newSortBy) {
        _sortAscending = !_sortAscending;
      } else {
        _sortBy = newSortBy;
        _sortAscending = true;
      }
      _inventoryData = _sortInventoryData(_inventoryData);
    });
  }

  @override
  Widget build(BuildContext context) {
    final totalValue = _inventoryData.fold<double>(
      0.0,
      (sum, item) => sum + item.stockValue,
    );
    final lowStockCount = _inventoryData.where((item) => item.isLowStock).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Inventory Report'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const StockAdjustmentHistoryScreen(),
                ),
              );
            },
            tooltip: 'Adjustment History',
          ),
          IconButton(
            icon: const Icon(Icons.file_download),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Export feature coming soon')),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          _buildFilterBar(),
          _buildSummaryBar(totalValue, lowStockCount),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _inventoryData.isEmpty
                    ? const EmptyState(message: 'No inventory data available')
                    : _buildInventoryList(),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Row(
        children: [
          FilterChip(
            label: const Text('Low Stock Only'),
            selected: _showLowStockOnly,
            onSelected: (selected) {
              setState(() => _showLowStockOnly = selected);
              _loadReport();
            },
          ),
          const Spacer(),
          PopupMenuButton<String>(
            onSelected: _changeSortBy,
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'name', child: Text('Product Name')),
              const PopupMenuItem(value: 'stock', child: Text('Stock Level')),
              const PopupMenuItem(value: 'value', child: Text('Stock Value')),
            ],
            child: Chip(
              avatar: Icon(
                _sortAscending ? Icons.arrow_upward : Icons.arrow_downward,
                size: 16,
              ),
              label: Text('Sort: ${_getSortLabel(_sortBy)}'),
            ),
          ),
        ],
      ),
    );
  }

  String _getSortLabel(String sortBy) {
    switch (sortBy) {
      case 'stock':
        return 'Stock';
      case 'value':
        return 'Value';
      case 'name':
      default:
        return 'Name';
    }
  }

  Widget _buildSummaryBar(double totalValue, int lowStockCount) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      color: Theme.of(context).colorScheme.surfaceContainer,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildSummaryItem(
            'Total Items',
            '${_inventoryData.length}',
            Icons.inventory_2,
          ),
          _buildSummaryItem(
            'Total Value',
            _reportService.formatCurrency(totalValue),
            Icons.attach_money,
          ),
          if (lowStockCount > 0)
            _buildSummaryItem(
              'Low Stock',
              '$lowStockCount',
              Icons.warning,
              color: Colors.orange,
            ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value, IconData icon,
      {Color? color}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: AppSpacing.xs),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              value,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
            ),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildInventoryList() {
    return RefreshIndicator(
      onRefresh: _loadReport,
      child: ListView.separated(
        padding: const EdgeInsets.all(AppSpacing.md),
        itemCount: _inventoryData.length,
        separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
        itemBuilder: (context, index) {
          final item = _inventoryData[index];
          return _buildInventoryCard(item);
        },
      ),
    );
  }

  Widget _buildInventoryCard(InventoryReportData item) {
    final potentialProfit = 
        (item.sellingPrice - item.costPrice) * item.currentStock;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.productName,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Row(
                        children: [
                          Icon(
                            item.isLowStock
                                ? Icons.warning_amber
                                : Icons.check_circle,
                            size: 16,
                            color: item.isLowStock ? Colors.orange : Colors.green,
                          ),
                          const SizedBox(width: AppSpacing.xs),
                          Text(
                            '${item.currentStock} ${item.unit}',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: item.isLowStock
                                      ? Colors.orange
                                      : Theme.of(context).colorScheme.onSurface,
                                  fontWeight: item.isLowStock
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                          ),
                          if (item.isLowStock) ...[
                            const SizedBox(width: AppSpacing.xs),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.xs,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.orange.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'LOW',
                                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                      color: Colors.orange.shade800,
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: AppSpacing.md),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildInfoColumn(
                  context,
                  'Cost Price',
                  _reportService.formatCurrency(item.costPrice),
                ),
                _buildInfoColumn(
                  context,
                  'Selling Price',
                  _reportService.formatCurrency(item.sellingPrice),
                ),
                _buildInfoColumn(
                  context,
                  'Stock Value',
                  _reportService.formatCurrency(item.stockValue),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Potential Profit: ${_reportService.formatCurrency(potentialProfit)}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: potentialProfit >= 0 ? Colors.green : Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoColumn(BuildContext context, String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
      ],
    );
  }
}
