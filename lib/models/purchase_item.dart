class PurchaseItem {
  final int? id;
  final int productId;
  final int quantity; // In base units
  final double costPrice;
  final DateTime date;
  
  PurchaseItem({
    this.id,
    required this.productId,
    required this.quantity,
    required this.costPrice,
    required this.date,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'product_id': productId,
      'quantity': quantity,
      'cost_price': costPrice,
      'date': date.toIso8601String(),
    };
  }
}
