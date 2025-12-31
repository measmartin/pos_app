import 'package:flutter/material.dart';
import '../models/report_models.dart';
import '../services/report_service.dart';
import '../theme/app_spacing.dart';
import '../widgets/common/empty_state.dart';

class FinancialReportScreen extends StatefulWidget {
  const FinancialReportScreen({super.key});

  @override
  State<FinancialReportScreen> createState() => _FinancialReportScreenState();
}

class _FinancialReportScreenState extends State<FinancialReportScreen> {
  final ReportService _reportService = ReportService();
  
  ReportPeriod _selectedPeriod = ReportPeriod.thisMonth;
  DateTime? _customStartDate;
  DateTime? _customEndDate;
  
  FinancialStatement? _profitLossStatement;
  FinancialStatement? _balanceSheet;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadReports();
  }

  Future<void> _loadReports() async {
    setState(() => _isLoading = true);

    try {
      final (startDate, endDate) = _getDateRange();
      
      final pl = await _reportService.getProfitAndLossStatement(startDate, endDate);
      final bs = await _reportService.getBalanceSheet(endDate);

      setState(() {
        _profitLossStatement = pl;
        _balanceSheet = bs;
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

  (DateTime, DateTime) _getDateRange() {
    if (_selectedPeriod == ReportPeriod.custom && 
        _customStartDate != null && 
        _customEndDate != null) {
      return (_customStartDate!, _customEndDate!);
    }
    return _selectedPeriod.getDateRange();
  }

  Future<void> _selectCustomDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _customStartDate != null && _customEndDate != null
          ? DateTimeRange(start: _customStartDate!, end: _customEndDate!)
          : null,
    );

    if (picked != null) {
      setState(() {
        _customStartDate = picked.start;
        _customEndDate = picked.end;
        _selectedPeriod = ReportPeriod.custom;
      });
      _loadReports();
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Financial Reports'),
          actions: [
            IconButton(
              icon: const Icon(Icons.file_download),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Export feature coming soon')),
                );
              },
            ),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Profit & Loss'),
              Tab(text: 'Balance Sheet'),
            ],
          ),
        ),
        body: Column(
          children: [
            _buildPeriodSelector(),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : TabBarView(
                      children: [
                        _buildProfitLossView(),
                        _buildBalanceSheetView(),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPeriodSelector() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Row(
        children: [
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SegmentedButton<ReportPeriod>(
                segments: ReportPeriod.values.map((period) {
                  return ButtonSegment(
                    value: period,
                    label: Text(period.displayName),
                  );
                }).toList(),
                selected: {_selectedPeriod},
                onSelectionChanged: (Set<ReportPeriod> newSelection) {
                  setState(() => _selectedPeriod = newSelection.first);
                  if (newSelection.first == ReportPeriod.custom) {
                    _selectCustomDateRange();
                  } else {
                    _loadReports();
                  }
                },
              ),
            ),
          ),
          if (_selectedPeriod == ReportPeriod.custom) ...[
            const SizedBox(width: AppSpacing.sm),
            IconButton(
              icon: const Icon(Icons.calendar_today),
              onPressed: _selectCustomDateRange,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildProfitLossView() {
    if (_profitLossStatement == null) {
      return const EmptyState(message: 'No financial data available');
    }

    final statement = _profitLossStatement!;
    final (startDate, endDate) = _getDateRange();

    return RefreshIndicator(
      onRefresh: _loadReports,
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          _buildStatementHeader(
            'Profit & Loss Statement',
            _reportService.formatDateRange(startDate, endDate),
          ),
          const SizedBox(height: AppSpacing.lg),
          
          // Revenue Section
          _buildSectionHeader('Revenue'),
          ...statement.sections.entries
              .where((e) => statement.sections.keys.any((k) => k.contains('Revenue') || k.contains('Sales')))
              .map((e) => _buildLineItem(e.key, e.value, isRevenue: true)),
          const Divider(),
          _buildLineItem(
            'Total Revenue',
            statement.totalRevenue,
            isBold: true,
            isRevenue: true,
          ),
          const SizedBox(height: AppSpacing.lg),

          // Expenses Section
          _buildSectionHeader('Expenses'),
          ...statement.sections.entries
              .where((e) => statement.sections.keys.any((k) => 
                  k.contains('Expense') || 
                  k.contains('Cost') || 
                  k.contains('Utilities') || 
                  k.contains('Rent')))
              .map((e) => _buildLineItem(e.key, e.value)),
          const Divider(),
          _buildLineItem(
            'Total Expenses',
            statement.totalExpenses,
            isBold: true,
          ),
          const SizedBox(height: AppSpacing.lg),

          // Net Income
          Card(
            color: statement.netIncome >= 0
                ? Colors.green.shade50
                : Colors.red.shade50,
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Net Income',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  Text(
                    _reportService.formatCurrency(statement.netIncome),
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: statement.netIncome >= 0
                              ? Colors.green.shade800
                              : Colors.red.shade800,
                        ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBalanceSheetView() {
    if (_balanceSheet == null) {
      return const EmptyState(message: 'No financial data available');
    }

    final statement = _balanceSheet!;
    final (_, asOfDate) = _getDateRange();

    return RefreshIndicator(
      onRefresh: _loadReports,
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          _buildStatementHeader(
            'Balance Sheet',
            'As of ${_reportService.formatDate(asOfDate)}',
          ),
          const SizedBox(height: AppSpacing.lg),
          
          // Assets Section
          _buildSectionHeader('Assets'),
          ...statement.sections.entries
              .where((e) {
                // Find asset accounts
                return e.key.contains('Cash') || 
                       e.key.contains('Inventory') || 
                       e.key.contains('Receivable') || 
                       e.key.contains('Equipment');
              })
              .map((e) => _buildLineItem(e.key, e.value)),
          const Divider(),
          _buildLineItem(
            'Total Assets',
            statement.totalAssets,
            isBold: true,
          ),
          const SizedBox(height: AppSpacing.lg),

          // Liabilities Section
          _buildSectionHeader('Liabilities'),
          ...statement.sections.entries
              .where((e) => e.key.contains('Payable') || e.key.contains('Tax'))
              .map((e) => _buildLineItem(e.key, e.value)),
          const Divider(),
          _buildLineItem(
            'Total Liabilities',
            statement.totalLiabilities,
            isBold: true,
          ),
          const SizedBox(height: AppSpacing.lg),

          // Equity Section
          _buildSectionHeader('Equity'),
          ...statement.sections.entries
              .where((e) => e.key.contains('Equity') || e.key.contains('Earnings'))
              .map((e) => _buildLineItem(e.key, e.value)),
          const Divider(),
          _buildLineItem(
            'Total Equity',
            statement.totalEquity,
            isBold: true,
          ),
          const SizedBox(height: AppSpacing.lg),

          // Balance Check
          Card(
            color: Theme.of(context).colorScheme.primaryContainer,
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Balance Check',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Total Liabilities + Equity'),
                      Text(
                        _reportService.formatCurrency(
                          statement.totalLiabilities + statement.totalEquity,
                        ),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Assets should equal Liabilities + Equity',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatementHeader(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          subtitle,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
      ),
    );
  }

  Widget _buildLineItem(
    String label,
    double amount, {
    bool isBold = false,
    bool isRevenue = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
                  ),
            ),
          ),
          Text(
            _reportService.formatCurrency(amount),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
                ),
          ),
        ],
      ),
    );
  }
}
