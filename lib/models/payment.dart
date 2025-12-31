/// Represents different payment methods
enum PaymentMethodType {
  cash,
  card,
  mobile,
  bankTransfer,
}

/// Model for payment information
class Payment {
  final int? id;
  final PaymentMethodType method;
  final double amount;
  final String? reference; // Transaction reference, check number, etc.
  final String? notes;
  final DateTime paidAt;

  Payment({
    this.id,
    required this.method,
    required this.amount,
    this.reference,
    this.notes,
    DateTime? paidAt,
  }) : paidAt = paidAt ?? DateTime.now();

  /// Get display name for payment method
  String get methodName {
    switch (method) {
      case PaymentMethodType.cash:
        return 'Cash';
      case PaymentMethodType.card:
        return 'Card';
      case PaymentMethodType.mobile:
        return 'Mobile Payment';
      case PaymentMethodType.bankTransfer:
        return 'Bank Transfer';
    }
  }

  /// Get icon for payment method
  String get methodIcon {
    switch (method) {
      case PaymentMethodType.cash:
        return '💵';
      case PaymentMethodType.card:
        return '💳';
      case PaymentMethodType.mobile:
        return '📱';
      case PaymentMethodType.bankTransfer:
        return '🏦';
    }
  }

  /// Copy with method
  Payment copyWith({
    int? id,
    PaymentMethodType? method,
    double? amount,
    String? reference,
    String? notes,
    DateTime? paidAt,
  }) {
    return Payment(
      id: id ?? this.id,
      method: method ?? this.method,
      amount: amount ?? this.amount,
      reference: reference ?? this.reference,
      notes: notes ?? this.notes,
      paidAt: paidAt ?? this.paidAt,
    );
  }

  /// Convert to Map for database storage
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'method': method.name,
      'amount': amount,
      'reference': reference,
      'notes': notes,
      'paid_at': paidAt.toIso8601String(),
    };
  }

  /// Create from Map
  factory Payment.fromMap(Map<String, dynamic> map) {
    return Payment(
      id: map['id'] as int?,
      method: PaymentMethodType.values.firstWhere((e) => e.name == map['method']),
      amount: (map['amount'] as num).toDouble(),
      reference: map['reference'] as String?,
      notes: map['notes'] as String?,
      paidAt: DateTime.parse(map['paid_at'] as String),
    );
  }
}

/// Model for a complete transaction with multiple payments
class Transaction {
  final String id; // UUID or timestamp-based ID
  final List<Payment> payments;
  final double totalAmount;
  final double paidAmount;
  final DateTime createdAt;

  Transaction({
    required this.id,
    required this.payments,
    required this.totalAmount,
    DateTime? createdAt,
  })  : paidAmount = payments.fold(0, (sum, payment) => sum + payment.amount),
        createdAt = createdAt ?? DateTime.now();

  /// Check if transaction is fully paid
  bool get isFullyPaid => paidAmount >= totalAmount;

  /// Get remaining balance
  double get balance => totalAmount - paidAmount;

  /// Get change (overpayment)
  double get change => paidAmount > totalAmount ? paidAmount - totalAmount : 0;
}
