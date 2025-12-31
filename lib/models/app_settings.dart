class AppSettings {
  final String businessName;
  final String businessAddress;
  final String businessPhone;
  final String businessEmail;
  final String taxId;
  final double taxRate;
  final String currencySymbol;
  final String receiptHeader;
  final String receiptFooter;
  final bool enableLoyaltyProgram;
  final bool enableLowStockAlerts;
  final int lowStockThreshold;
  final bool printReceiptAutomatically;

  AppSettings({
    this.businessName = 'My Shop',
    this.businessAddress = '',
    this.businessPhone = '',
    this.businessEmail = '',
    this.taxId = '',
    this.taxRate = 0.0,
    this.currencySymbol = '\$',
    this.receiptHeader = 'Thank you for your purchase!',
    this.receiptFooter = 'Please come again',
    this.enableLoyaltyProgram = true,
    this.enableLowStockAlerts = true,
    this.lowStockThreshold = 10,
    this.printReceiptAutomatically = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'business_name': businessName,
      'business_address': businessAddress,
      'business_phone': businessPhone,
      'business_email': businessEmail,
      'tax_id': taxId,
      'tax_rate': taxRate,
      'currency_symbol': currencySymbol,
      'receipt_header': receiptHeader,
      'receipt_footer': receiptFooter,
      'enable_loyalty_program': enableLoyaltyProgram ? 1 : 0,
      'enable_low_stock_alerts': enableLowStockAlerts ? 1 : 0,
      'low_stock_threshold': lowStockThreshold,
      'print_receipt_automatically': printReceiptAutomatically ? 1 : 0,
    };
  }

  factory AppSettings.fromMap(Map<String, dynamic> map) {
    return AppSettings(
      businessName: map['business_name'] ?? 'My Shop',
      businessAddress: map['business_address'] ?? '',
      businessPhone: map['business_phone'] ?? '',
      businessEmail: map['business_email'] ?? '',
      taxId: map['tax_id'] ?? '',
      taxRate: map['tax_rate']?.toDouble() ?? 0.0,
      currencySymbol: map['currency_symbol'] ?? '\$',
      receiptHeader: map['receipt_header'] ?? 'Thank you for your purchase!',
      receiptFooter: map['receipt_footer'] ?? 'Please come again',
      enableLoyaltyProgram: (map['enable_loyalty_program'] ?? 1) == 1,
      enableLowStockAlerts: (map['enable_low_stock_alerts'] ?? 1) == 1,
      lowStockThreshold: map['low_stock_threshold'] ?? 10,
      printReceiptAutomatically: (map['print_receipt_automatically'] ?? 0) == 1,
    );
  }

  AppSettings copyWith({
    String? businessName,
    String? businessAddress,
    String? businessPhone,
    String? businessEmail,
    String? taxId,
    double? taxRate,
    String? currencySymbol,
    String? receiptHeader,
    String? receiptFooter,
    bool? enableLoyaltyProgram,
    bool? enableLowStockAlerts,
    int? lowStockThreshold,
    bool? printReceiptAutomatically,
  }) {
    return AppSettings(
      businessName: businessName ?? this.businessName,
      businessAddress: businessAddress ?? this.businessAddress,
      businessPhone: businessPhone ?? this.businessPhone,
      businessEmail: businessEmail ?? this.businessEmail,
      taxId: taxId ?? this.taxId,
      taxRate: taxRate ?? this.taxRate,
      currencySymbol: currencySymbol ?? this.currencySymbol,
      receiptHeader: receiptHeader ?? this.receiptHeader,
      receiptFooter: receiptFooter ?? this.receiptFooter,
      enableLoyaltyProgram: enableLoyaltyProgram ?? this.enableLoyaltyProgram,
      enableLowStockAlerts: enableLowStockAlerts ?? this.enableLowStockAlerts,
      lowStockThreshold: lowStockThreshold ?? this.lowStockThreshold,
      printReceiptAutomatically: printReceiptAutomatically ?? this.printReceiptAutomatically,
    );
  }
}
