class JournalEntry {
  final int? id;
  final DateTime date;
  final String type; // 'DEBIT' or 'CREDIT'
  final String description;
  final double amount;

  JournalEntry({
    this.id,
    required this.date,
    required this.type,
    required this.description,
    required this.amount,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'type': type,
      'description': description,
      'amount': amount,
    };
  }

  factory JournalEntry.fromMap(Map<String, dynamic> map) {
    return JournalEntry(
      id: map['id'],
      date: DateTime.parse(map['date']),
      type: map['type'],
      description: map['description'],
      amount: map['amount'],
    );
  }
}
