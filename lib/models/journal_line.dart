class JournalLine {
  final int? id;
  final int headerId;
  final int accountId;
  final double debit;
  final double credit;
  final String? description;

  JournalLine({
    this.id,
    required this.headerId,
    required this.accountId,
    this.debit = 0.0,
    this.credit = 0.0,
    this.description,
  }) : assert(
          debit >= 0 && credit >= 0,
          'Debit and credit must be non-negative',
        ),
        assert(
          !(debit > 0 && credit > 0),
          'A line cannot have both debit and credit',
        );

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'header_id': headerId,
      'account_id': accountId,
      'debit': debit,
      'credit': credit,
      'description': description,
    };
  }

  factory JournalLine.fromMap(Map<String, dynamic> map) {
    return JournalLine(
      id: map['id'],
      headerId: map['header_id'],
      accountId: map['account_id'],
      debit: map['debit'] ?? 0.0,
      credit: map['credit'] ?? 0.0,
      description: map['description'],
    );
  }

  JournalLine copyWith({
    int? id,
    int? headerId,
    int? accountId,
    double? debit,
    double? credit,
    String? description,
  }) {
    return JournalLine(
      id: id ?? this.id,
      headerId: headerId ?? this.headerId,
      accountId: accountId ?? this.accountId,
      debit: debit ?? this.debit,
      credit: credit ?? this.credit,
      description: description ?? this.description,
    );
  }

  // Helper to get the amount (non-zero value)
  double get amount => debit > 0 ? debit : credit;

  // Helper to check if this is a debit entry
  bool get isDebit => debit > 0;

  // Helper to check if this is a credit entry
  bool get isCredit => credit > 0;
}
