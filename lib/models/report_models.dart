class SalesReportData {
  final DateTime date;
  final double totalAmount;
  final int itemCount;
  final int transactionCount;

  SalesReportData({
    required this.date,
    required this.totalAmount,
    required this.itemCount,
    this.transactionCount = 1,
  });

  factory SalesReportData.fromMap(Map<String, dynamic> map) {
    return SalesReportData(
      date: DateTime.parse(map['date']),
      totalAmount: map['total_amount'] ?? 0.0,
      itemCount: map['item_count'] ?? 0,
      transactionCount: map['transaction_count'] ?? 1,
    );
  }
}

class SalesReportSummary {
  final double totalRevenue;
  final int totalTransactions;
  final int totalItemsSold;
  final double averageTransactionValue;
  final DateTime startDate;
  final DateTime endDate;
  final List<SalesReportData> dailyData;

  SalesReportSummary({
    required this.totalRevenue,
    required this.totalTransactions,
    required this.totalItemsSold,
    required this.averageTransactionValue,
    required this.startDate,
    required this.endDate,
    required this.dailyData,
  });
}

class ProductSalesData {
  final int productId;
  final String productName;
  final int quantitySold;
  final double totalRevenue;
  final double averagePrice;

  ProductSalesData({
    required this.productId,
    required this.productName,
    required this.quantitySold,
    required this.totalRevenue,
    required this.averagePrice,
  });

  factory ProductSalesData.fromMap(Map<String, dynamic> map) {
    return ProductSalesData(
      productId: map['product_id'],
      productName: map['product_name'],
      quantitySold: map['quantity_sold'],
      totalRevenue: map['total_revenue'],
      averagePrice: map['average_price'],
    );
  }
}

class InventoryReportData {
  final int productId;
  final String productName;
  final String unit;
  final int currentStock;
  final double costPrice;
  final double sellingPrice;
  final double stockValue;
  final bool isLowStock;

  InventoryReportData({
    required this.productId,
    required this.productName,
    required this.unit,
    required this.currentStock,
    required this.costPrice,
    required this.sellingPrice,
    required this.stockValue,
    this.isLowStock = false,
  });

  factory InventoryReportData.fromMap(Map<String, dynamic> map) {
    final currentStock = map['stockQuantity'] ?? 0;
    final costPrice = map['costPrice'] ?? 0.0;
    return InventoryReportData(
      productId: map['id'],
      productName: map['name'],
      unit: map['unit'],
      currentStock: currentStock,
      costPrice: costPrice,
      sellingPrice: map['sellingPrice'] ?? 0.0,
      stockValue: currentStock * costPrice,
      isLowStock: currentStock < 10, // Configurable threshold
    );
  }
}

class FinancialStatement {
  final String title;
  final DateTime startDate;
  final DateTime endDate;
  final Map<String, double> sections;
  final double totalAssets;
  final double totalLiabilities;
  final double totalEquity;
  final double totalRevenue;
  final double totalExpenses;
  final double netIncome;

  FinancialStatement({
    required this.title,
    required this.startDate,
    required this.endDate,
    required this.sections,
    this.totalAssets = 0.0,
    this.totalLiabilities = 0.0,
    this.totalEquity = 0.0,
    this.totalRevenue = 0.0,
    this.totalExpenses = 0.0,
    this.netIncome = 0.0,
  });
}

enum ReportPeriod {
  today,
  yesterday,
  thisWeek,
  lastWeek,
  thisMonth,
  lastMonth,
  custom,
}

extension ReportPeriodExtension on ReportPeriod {
  String get displayName {
    switch (this) {
      case ReportPeriod.today:
        return 'Today';
      case ReportPeriod.yesterday:
        return 'Yesterday';
      case ReportPeriod.thisWeek:
        return 'This Week';
      case ReportPeriod.lastWeek:
        return 'Last Week';
      case ReportPeriod.thisMonth:
        return 'This Month';
      case ReportPeriod.lastMonth:
        return 'Last Month';
      case ReportPeriod.custom:
        return 'Custom Range';
    }
  }

  (DateTime, DateTime) getDateRange() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    switch (this) {
      case ReportPeriod.today:
        return (today, today.add(const Duration(days: 1)));
      case ReportPeriod.yesterday:
        final yesterday = today.subtract(const Duration(days: 1));
        return (yesterday, today);
      case ReportPeriod.thisWeek:
        final weekStart = today.subtract(Duration(days: now.weekday - 1));
        return (weekStart, today.add(const Duration(days: 1)));
      case ReportPeriod.lastWeek:
        final lastWeekEnd = today.subtract(Duration(days: now.weekday));
        final lastWeekStart = lastWeekEnd.subtract(const Duration(days: 6));
        return (lastWeekStart, lastWeekEnd.add(const Duration(days: 1)));
      case ReportPeriod.thisMonth:
        final monthStart = DateTime(now.year, now.month, 1);
        return (monthStart, today.add(const Duration(days: 1)));
      case ReportPeriod.lastMonth:
        final lastMonthStart = DateTime(now.year, now.month - 1, 1);
        final lastMonthEnd = DateTime(now.year, now.month, 1);
        return (lastMonthStart, lastMonthEnd);
      case ReportPeriod.custom:
        return (today, today.add(const Duration(days: 1)));
    }
  }
}
