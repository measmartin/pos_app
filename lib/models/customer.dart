/// Customer model representing a customer in the POS system
class Customer {
  final int? id;
  final String name;
  final String? phone;
  final String? email;
  final String? address;
  final double loyaltyPoints;
  final double totalSpent;
  final DateTime createdAt;
  final DateTime? lastPurchaseDate;
  final String? notes;
  final bool isActive;

  Customer({
    this.id,
    required this.name,
    this.phone,
    this.email,
    this.address,
    this.loyaltyPoints = 0.0,
    this.totalSpent = 0.0,
    DateTime? createdAt,
    this.lastPurchaseDate,
    this.notes,
    this.isActive = true,
  }) : createdAt = createdAt ?? DateTime.now();

  /// Create Customer from database map
  factory Customer.fromMap(Map<String, dynamic> map) {
    return Customer(
      id: map['id'] as int?,
      name: map['name'] as String,
      phone: map['phone'] as String?,
      email: map['email'] as String?,
      address: map['address'] as String?,
      loyaltyPoints: (map['loyalty_points'] as num?)?.toDouble() ?? 0.0,
      totalSpent: (map['total_spent'] as num?)?.toDouble() ?? 0.0,
      createdAt: DateTime.parse(map['created_at'] as String),
      lastPurchaseDate: map['last_purchase_date'] != null
          ? DateTime.parse(map['last_purchase_date'] as String)
          : null,
      notes: map['notes'] as String?,
      isActive: (map['is_active'] as int?) == 1,
    );
  }

  /// Convert Customer to database map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'email': email,
      'address': address,
      'loyalty_points': loyaltyPoints,
      'total_spent': totalSpent,
      'created_at': createdAt.toIso8601String(),
      'last_purchase_date': lastPurchaseDate?.toIso8601String(),
      'notes': notes,
      'is_active': isActive ? 1 : 0,
    };
  }

  /// Create a copy with modified fields
  Customer copyWith({
    int? id,
    String? name,
    String? phone,
    String? email,
    String? address,
    double? loyaltyPoints,
    double? totalSpent,
    DateTime? createdAt,
    DateTime? lastPurchaseDate,
    String? notes,
    bool? isActive,
  }) {
    return Customer(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      address: address ?? this.address,
      loyaltyPoints: loyaltyPoints ?? this.loyaltyPoints,
      totalSpent: totalSpent ?? this.totalSpent,
      createdAt: createdAt ?? this.createdAt,
      lastPurchaseDate: lastPurchaseDate ?? this.lastPurchaseDate,
      notes: notes ?? this.notes,
      isActive: isActive ?? this.isActive,
    );
  }

  /// Get customer initials for avatar display
  String get initials {
    final parts = name.trim().split(' ');
    if (parts.isEmpty) return '?';
    if (parts.length == 1) {
      return parts[0].substring(0, 1).toUpperCase();
    }
    return '${parts[0].substring(0, 1)}${parts[parts.length - 1].substring(0, 1)}'.toUpperCase();
  }

  /// Format phone number for display
  String get formattedPhone {
    if (phone == null || phone!.isEmpty) return 'No phone';
    return phone!;
  }

  /// Check if customer has email
  bool get hasEmail => email != null && email!.isNotEmpty;

  /// Check if customer has phone
  bool get hasPhone => phone != null && phone!.isNotEmpty;

  /// Check if customer has made any purchases
  bool get hasPurchaseHistory => totalSpent > 0;

  /// Get customer tier based on total spent
  CustomerTier get tier {
    if (totalSpent >= 10000) return CustomerTier.platinum;
    if (totalSpent >= 5000) return CustomerTier.gold;
    if (totalSpent >= 1000) return CustomerTier.silver;
    return CustomerTier.bronze;
  }

  @override
  String toString() {
    return 'Customer(id: $id, name: $name, phone: $phone, totalSpent: $totalSpent)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Customer && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

/// Customer tier/level based on spending
enum CustomerTier {
  bronze,
  silver,
  gold,
  platinum;

  String get displayName {
    switch (this) {
      case CustomerTier.bronze:
        return 'Bronze';
      case CustomerTier.silver:
        return 'Silver';
      case CustomerTier.gold:
        return 'Gold';
      case CustomerTier.platinum:
        return 'Platinum';
    }
  }

  String get description {
    switch (this) {
      case CustomerTier.bronze:
        return 'New Customer';
      case CustomerTier.silver:
        return 'Regular Customer';
      case CustomerTier.gold:
        return 'Valued Customer';
      case CustomerTier.platinum:
        return 'VIP Customer';
    }
  }

  /// Minimum spending required for this tier
  double get minSpending {
    switch (this) {
      case CustomerTier.bronze:
        return 0;
      case CustomerTier.silver:
        return 1000;
      case CustomerTier.gold:
        return 5000;
      case CustomerTier.platinum:
        return 10000;
    }
  }
}
