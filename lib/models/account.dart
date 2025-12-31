enum AccountType {
  asset,
  liability,
  equity,
  revenue,
  expense,
}

class Account {
  final int? id;
  final String code;
  final String name;
  final AccountType type;
  final int? parentId;
  final double balance;
  final bool isActive;

  Account({
    this.id,
    required this.code,
    required this.name,
    required this.type,
    this.parentId,
    this.balance = 0.0,
    this.isActive = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'code': code,
      'name': name,
      'type': type.name.toUpperCase(),
      'parent_id': parentId,
      'balance': balance,
      'is_active': isActive ? 1 : 0,
    };
  }

  factory Account.fromMap(Map<String, dynamic> map) {
    return Account(
      id: map['id'],
      code: map['code'],
      name: map['name'],
      type: AccountType.values.firstWhere(
        (e) => e.name.toUpperCase() == map['type'],
      ),
      parentId: map['parent_id'],
      balance: map['balance'] ?? 0.0,
      isActive: map['is_active'] == 1,
    );
  }

  Account copyWith({
    int? id,
    String? code,
    String? name,
    AccountType? type,
    int? parentId,
    double? balance,
    bool? isActive,
  }) {
    return Account(
      id: id ?? this.id,
      code: code ?? this.code,
      name: name ?? this.name,
      type: type ?? this.type,
      parentId: parentId ?? this.parentId,
      balance: balance ?? this.balance,
      isActive: isActive ?? this.isActive,
    );
  }
}
