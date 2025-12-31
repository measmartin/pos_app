/// Represents different types of discounts
enum DiscountType {
  percentage, // e.g., 10% off
  fixed, // e.g., $5 off
}

/// Represents the scope of a discount application
enum DiscountScope {
  item, // Applies to a specific cart item
  cart, // Applies to the entire cart
}

/// Model for discount information
class Discount {
  final int? id;
  final DiscountType type;
  final DiscountScope scope;
  final double value; // percentage (0-100) or fixed amount
  final String? reason; // Why discount was applied
  final String? itemKey; // For item-level discounts: "productId_unitName"
  final DateTime appliedAt;

  Discount({
    this.id,
    required this.type,
    required this.scope,
    required this.value,
    this.reason,
    this.itemKey,
    DateTime? appliedAt,
  }) : appliedAt = appliedAt ?? DateTime.now();

  /// Calculate discount amount based on subtotal
  double calculateAmount(double subtotal) {
    if (type == DiscountType.percentage) {
      return subtotal * (value / 100);
    } else {
      // Fixed amount discount
      return value > subtotal ? subtotal : value; // Don't exceed subtotal
    }
  }

  /// Format discount display string
  String get displayValue {
    if (type == DiscountType.percentage) {
      return '${value.toStringAsFixed(0)}% OFF';
    } else {
      return '\$${value.toStringAsFixed(2)} OFF';
    }
  }

  /// Copy with method
  Discount copyWith({
    int? id,
    DiscountType? type,
    DiscountScope? scope,
    double? value,
    String? reason,
    String? itemKey,
    DateTime? appliedAt,
  }) {
    return Discount(
      id: id ?? this.id,
      type: type ?? this.type,
      scope: scope ?? this.scope,
      value: value ?? this.value,
      reason: reason ?? this.reason,
      itemKey: itemKey ?? this.itemKey,
      appliedAt: appliedAt ?? this.appliedAt,
    );
  }

  /// Convert to Map for database storage
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type.name,
      'scope': scope.name,
      'value': value,
      'reason': reason,
      'item_key': itemKey,
      'applied_at': appliedAt.toIso8601String(),
    };
  }

  /// Create from Map
  factory Discount.fromMap(Map<String, dynamic> map) {
    return Discount(
      id: map['id'] as int?,
      type: DiscountType.values.firstWhere((e) => e.name == map['type']),
      scope: DiscountScope.values.firstWhere((e) => e.name == map['scope']),
      value: (map['value'] as num).toDouble(),
      reason: map['reason'] as String?,
      itemKey: map['item_key'] as String?,
      appliedAt: DateTime.parse(map['applied_at'] as String),
    );
  }
}
