/// Represents a product return/refund
class ProductReturn {
  final int? id;
  final int saleItemId; // Reference to original sale_items
  final int productId;
  final String productName;
  final int quantityReturned;
  final double refundAmount;
  final String reason;
  final String? notes;
  final DateTime returnDate;
  final String? transactionId; // Original transaction ID

  ProductReturn({
    this.id,
    required this.saleItemId,
    required this.productId,
    required this.productName,
    required this.quantityReturned,
    required this.refundAmount,
    required this.reason,
    this.notes,
    DateTime? returnDate,
    this.transactionId,
  }) : returnDate = returnDate ?? DateTime.now();

  /// Convert to Map for database storage
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'sale_item_id': saleItemId,
      'product_id': productId,
      'product_name': productName,
      'quantity_returned': quantityReturned,
      'refund_amount': refundAmount,
      'reason': reason,
      'notes': notes,
      'return_date': returnDate.toIso8601String(),
      'transaction_id': transactionId,
    };
  }

  /// Create from Map
  factory ProductReturn.fromMap(Map<String, dynamic> map) {
    return ProductReturn(
      id: map['id'] as int?,
      saleItemId: map['sale_item_id'] as int,
      productId: map['product_id'] as int,
      productName: map['product_name'] as String,
      quantityReturned: map['quantity_returned'] as int,
      refundAmount: (map['refund_amount'] as num).toDouble(),
      reason: map['reason'] as String,
      notes: map['notes'] as String?,
      returnDate: DateTime.parse(map['return_date'] as String),
      transactionId: map['transaction_id'] as String?,
    );
  }

  /// Copy with method
  ProductReturn copyWith({
    int? id,
    int? saleItemId,
    int? productId,
    String? productName,
    int? quantityReturned,
    double? refundAmount,
    String? reason,
    String? notes,
    DateTime? returnDate,
    String? transactionId,
  }) {
    return ProductReturn(
      id: id ?? this.id,
      saleItemId: saleItemId ?? this.saleItemId,
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      quantityReturned: quantityReturned ?? this.quantityReturned,
      refundAmount: refundAmount ?? this.refundAmount,
      reason: reason ?? this.reason,
      notes: notes ?? this.notes,
      returnDate: returnDate ?? this.returnDate,
      transactionId: transactionId ?? this.transactionId,
    );
  }
}

/// Common return reasons
class ReturnReasons {
  static const String defective = 'Defective/Damaged';
  static const String wrongItem = 'Wrong Item';
  static const String customerRequest = 'Customer Request';
  static const String expired = 'Expired';
  static const String other = 'Other';

  static List<String> get all => [
        defective,
        wrongItem,
        customerRequest,
        expired,
        other,
      ];
}
