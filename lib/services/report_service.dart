import 'package:intl/intl.dart';
import '../models/report_models.dart';
import 'database_service.dart';

class ReportService {
  final DatabaseService _databaseService = DatabaseService();

  /// Get sales report summary for a date range
  Future<SalesReportSummary> getSalesReport(
    DateTime startDate,
    DateTime endDate,
  ) async {
    final db = await _databaseService.database;

    // Get daily sales data
    final dailyResults = await db.rawQuery('''
      SELECT 
        date(s.date) as date,
        SUM(s.selling_price * s.quantity) as total_amount,
        SUM(s.quantity) as item_count,
        COUNT(DISTINCT s.date) as transaction_count
      FROM sale_items s
      WHERE s.is_deleted = 0
        AND date(s.date) >= date(?)
        AND date(s.date) < date(?)
      GROUP BY date(s.date)
      ORDER BY date(s.date) ASC
    ''', [startDate.toIso8601String(), endDate.toIso8601String()]);

    final dailyData = dailyResults.map((map) {
      return SalesReportData(
        date: DateTime.parse(map['date'] as String),
        totalAmount: (map['total_amount'] as num?)?.toDouble() ?? 0.0,
        itemCount: (map['item_count'] as num?)?.toInt() ?? 0,
        transactionCount: (map['transaction_count'] as num?)?.toInt() ?? 1,
      );
    }).toList();

    // Calculate summary
    final totalRevenue = dailyData.fold<double>(
      0.0,
      (sum, data) => sum + data.totalAmount,
    );
    final totalTransactions = dailyData.fold<int>(
      0,
      (sum, data) => sum + data.transactionCount,
    );
    final totalItemsSold = dailyData.fold<int>(
      0,
      (sum, data) => sum + data.itemCount,
    );
    final averageTransactionValue =
        totalTransactions > 0 ? totalRevenue / totalTransactions : 0.0;

    return SalesReportSummary(
      totalRevenue: totalRevenue,
      totalTransactions: totalTransactions,
      totalItemsSold: totalItemsSold,
      averageTransactionValue: averageTransactionValue,
      startDate: startDate,
      endDate: endDate,
      dailyData: dailyData,
    );
  }

  /// Get top selling products for a date range
  Future<List<ProductSalesData>> getTopSellingProducts(
    DateTime startDate,
    DateTime endDate, {
    int limit = 10,
  }) async {
    final db = await _databaseService.database;

    final results = await db.rawQuery('''
      SELECT 
        p.id as product_id,
        p.name as product_name,
        SUM(s.quantity) as quantity_sold,
        SUM(s.selling_price * s.quantity) as total_revenue,
        AVG(s.selling_price) as average_price
      FROM sale_items s
      JOIN products p ON s.product_id = p.id
      WHERE s.is_deleted = 0
        AND date(s.date) >= date(?)
        AND date(s.date) < date(?)
      GROUP BY p.id, p.name
      ORDER BY quantity_sold DESC
      LIMIT ?
    ''', [startDate.toIso8601String(), endDate.toIso8601String(), limit]);

    return results.map((map) {
      return ProductSalesData(
        productId: map['product_id'] as int,
        productName: map['product_name'] as String,
        quantitySold: (map['quantity_sold'] as num).toInt(),
        totalRevenue: (map['total_revenue'] as num).toDouble(),
        averagePrice: (map['average_price'] as num).toDouble(),
      );
    }).toList();
  }

  /// Get inventory report
  Future<List<InventoryReportData>> getInventoryReport({
    bool lowStockOnly = false,
    int lowStockThreshold = 10,
  }) async {
    final db = await _databaseService.database;

    final results = await db.query('products');

    final inventoryData = results.map((map) {
      final currentStock = (map['stockQuantity'] as int?) ?? 0;
      final costPrice = (map['costPrice'] as num?)?.toDouble() ?? 0.0;
      return InventoryReportData(
        productId: map['id'] as int,
        productName: map['name'] as String,
        unit: map['unit'] as String,
        currentStock: currentStock,
        costPrice: costPrice,
        sellingPrice: (map['sellingPrice'] as num?)?.toDouble() ?? 0.0,
        stockValue: currentStock * costPrice,
        isLowStock: currentStock < lowStockThreshold,
      );
    }).toList();

    if (lowStockOnly) {
      return inventoryData.where((item) => item.isLowStock).toList();
    }

    return inventoryData;
  }

  /// Get low stock count
  Future<int> getLowStockCount({int threshold = 10}) async {
    final db = await _databaseService.database;
    final result = await db.rawQuery('''
      SELECT COUNT(*) as count
      FROM products
      WHERE stockQuantity < ?
    ''', [threshold]);

    return (result.first['count'] as int?) ?? 0;
  }

  /// Get profit & loss statement
  Future<FinancialStatement> getProfitAndLossStatement(
    DateTime startDate,
    DateTime endDate,
  ) async {
    final db = await _databaseService.database;

    // Get revenue accounts
    final revenueResults = await db.rawQuery('''
      SELECT 
        a.name,
        SUM(jl.credit - jl.debit) as balance
      FROM accounts a
      LEFT JOIN journal_lines jl ON a.id = jl.account_id
      LEFT JOIN journal_headers jh ON jl.header_id = jh.id
      WHERE a.type = 'REVENUE'
        AND a.is_active = 1
        AND (jh.date IS NULL OR (date(jh.date) >= date(?) AND date(jh.date) < date(?)))
      GROUP BY a.name
    ''', [startDate.toIso8601String(), endDate.toIso8601String()]);

    // Get expense accounts
    final expenseResults = await db.rawQuery('''
      SELECT 
        a.name,
        SUM(jl.debit - jl.credit) as balance
      FROM accounts a
      LEFT JOIN journal_lines jl ON a.id = jl.account_id
      LEFT JOIN journal_headers jh ON jl.header_id = jh.id
      WHERE a.type = 'EXPENSE'
        AND a.is_active = 1
        AND (jh.date IS NULL OR (date(jh.date) >= date(?) AND date(jh.date) < date(?)))
      GROUP BY a.name
    ''', [startDate.toIso8601String(), endDate.toIso8601String()]);

    final sections = <String, double>{};

    double totalRevenue = 0.0;
    for (var row in revenueResults) {
      final balance = (row['balance'] as num?)?.toDouble() ?? 0.0;
      sections[row['name'] as String] = balance;
      totalRevenue += balance;
    }

    double totalExpenses = 0.0;
    for (var row in expenseResults) {
      final balance = (row['balance'] as num?)?.toDouble() ?? 0.0;
      sections[row['name'] as String] = balance;
      totalExpenses += balance;
    }

    final netIncome = totalRevenue - totalExpenses;

    return FinancialStatement(
      title: 'Profit & Loss Statement',
      startDate: startDate,
      endDate: endDate,
      sections: sections,
      totalRevenue: totalRevenue,
      totalExpenses: totalExpenses,
      netIncome: netIncome,
    );
  }

  /// Get balance sheet
  Future<FinancialStatement> getBalanceSheet(DateTime asOfDate) async {
    final db = await _databaseService.database;

    final sections = <String, double>{};

    // Get all accounts with their balances
    final results = await db.query('accounts', where: 'is_active = 1');

    double totalAssets = 0.0;
    double totalLiabilities = 0.0;
    double totalEquity = 0.0;

    for (var row in results) {
      final balance = (row['balance'] as num?)?.toDouble() ?? 0.0;
      final name = row['name'] as String;
      final type = row['type'] as String;

      sections[name] = balance;

      if (type == 'ASSET') {
        totalAssets += balance;
      } else if (type == 'LIABILITY') {
        totalLiabilities += balance;
      } else if (type == 'EQUITY') {
        totalEquity += balance;
      }
    }

    return FinancialStatement(
      title: 'Balance Sheet',
      startDate: asOfDate,
      endDate: asOfDate,
      sections: sections,
      totalAssets: totalAssets,
      totalLiabilities: totalLiabilities,
      totalEquity: totalEquity,
    );
  }

  /// Get total inventory value
  Future<double> getTotalInventoryValue() async {
    final db = await _databaseService.database;
    final result = await db.rawQuery('''
      SELECT SUM(stockQuantity * costPrice) as total_value
      FROM products
    ''');

    return (result.first['total_value'] as num?)?.toDouble() ?? 0.0;
  }

  /// Get sales comparison (current vs previous period)
  Future<Map<String, dynamic>> getSalesComparison(
    DateTime currentStart,
    DateTime currentEnd,
  ) async {
    final periodDuration = currentEnd.difference(currentStart);
    final previousStart = currentStart.subtract(periodDuration);
    final previousEnd = currentStart;

    final currentSales = await getSalesReport(currentStart, currentEnd);
    final previousSales = await getSalesReport(previousStart, previousEnd);

    final revenueChange = currentSales.totalRevenue - previousSales.totalRevenue;
    final revenueChangePercent = previousSales.totalRevenue > 0
        ? (revenueChange / previousSales.totalRevenue) * 100
        : 0.0;

    return {
      'current_revenue': currentSales.totalRevenue,
      'previous_revenue': previousSales.totalRevenue,
      'revenue_change': revenueChange,
      'revenue_change_percent': revenueChangePercent,
      'current_transactions': currentSales.totalTransactions,
      'previous_transactions': previousSales.totalTransactions,
    };
  }

  /// Format currency
  String formatCurrency(double amount) {
    final formatter = NumberFormat.currency(symbol: '\$', decimalDigits: 2);
    return formatter.format(amount);
  }

  /// Format date
  String formatDate(DateTime date) {
    return DateFormat('MMM dd, yyyy').format(date);
  }

  /// Format date range
  String formatDateRange(DateTime start, DateTime end) {
    return '${formatDate(start)} - ${formatDate(end)}';
  }
}
