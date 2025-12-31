enum AdjustmentType {
  addition,
  subtraction,
  correction,
  damage,
  theft,
  returned,
  other,
}

enum AdjustmentReason {
  stockCount,
  damagedGoods,
  expiredGoods,
  theft,
  customerReturn,
  supplierReturn,
  transferIn,
  transferOut,
  correction,
  other,
}

class StockAdjustment {
  final int? id;
  final int productId;
  final int quantityChange; // Positive for addition, negative for subtraction
  final int oldQuantity;
  final int newQuantity;
  final AdjustmentType type;
  final AdjustmentReason reason;
  final String? notes;
  final DateTime date;
  final String? userId; // For multi-user support later

  StockAdjustment({
    this.id,
    required this.productId,
    required this.quantityChange,
    required this.oldQuantity,
    required this.newQuantity,
    required this.type,
    required this.reason,
    this.notes,
    DateTime? date,
    this.userId,
  }) : date = date ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'product_id': productId,
      'quantity_change': quantityChange,
      'old_quantity': oldQuantity,
      'new_quantity': newQuantity,
      'type': type.name.toUpperCase(),
      'reason': reason.name.toUpperCase(),
      'notes': notes,
      'date': date.toIso8601String(),
      'user_id': userId,
    };
  }

  factory StockAdjustment.fromMap(Map<String, dynamic> map) {
    return StockAdjustment(
      id: map['id'],
      productId: map['product_id'],
      quantityChange: map['quantity_change'],
      oldQuantity: map['old_quantity'],
      newQuantity: map['new_quantity'],
      type: AdjustmentType.values.firstWhere(
        (e) => e.name.toUpperCase() == map['type'],
      ),
      reason: AdjustmentReason.values.firstWhere(
        (e) => e.name.toUpperCase() == map['reason'],
      ),
      notes: map['notes'],
      date: DateTime.parse(map['date']),
      userId: map['user_id'],
    );
  }

  StockAdjustment copyWith({
    int? id,
    int? productId,
    int? quantityChange,
    int? oldQuantity,
    int? newQuantity,
    AdjustmentType? type,
    AdjustmentReason? reason,
    String? notes,
    DateTime? date,
    String? userId,
  }) {
    return StockAdjustment(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      quantityChange: quantityChange ?? this.quantityChange,
      oldQuantity: oldQuantity ?? this.oldQuantity,
      newQuantity: newQuantity ?? this.newQuantity,
      type: type ?? this.type,
      reason: reason ?? this.reason,
      notes: notes ?? this.notes,
      date: date ?? this.date,
      userId: userId ?? this.userId,
    );
  }
}

extension AdjustmentTypeExtension on AdjustmentType {
  String get displayName {
    switch (this) {
      case AdjustmentType.addition:
        return 'Addition';
      case AdjustmentType.subtraction:
        return 'Subtraction';
      case AdjustmentType.correction:
        return 'Correction';
      case AdjustmentType.damage:
        return 'Damage';
      case AdjustmentType.theft:
        return 'Theft';
      case AdjustmentType.returned:
        return 'Returned';
      case AdjustmentType.other:
        return 'Other';
    }
  }
}

extension AdjustmentReasonExtension on AdjustmentReason {
  String get displayName {
    switch (this) {
      case AdjustmentReason.stockCount:
        return 'Stock Count';
      case AdjustmentReason.damagedGoods:
        return 'Damaged Goods';
      case AdjustmentReason.expiredGoods:
        return 'Expired Goods';
      case AdjustmentReason.theft:
        return 'Theft';
      case AdjustmentReason.customerReturn:
        return 'Customer Return';
      case AdjustmentReason.supplierReturn:
        return 'Supplier Return';
      case AdjustmentReason.transferIn:
        return 'Transfer In';
      case AdjustmentReason.transferOut:
        return 'Transfer Out';
      case AdjustmentReason.correction:
        return 'Correction';
      case AdjustmentReason.other:
        return 'Other';
    }
  }
}
