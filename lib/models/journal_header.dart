enum ReferenceType {
  sale,
  purchase,
  adjustment,
  opening,
  voidEntry,
}

class JournalHeader {
  final int? id;
  final DateTime date;
  final String description;
  final ReferenceType? referenceType;
  final int? referenceId;
  final DateTime createdAt;
  final bool isVoided;

  JournalHeader({
    this.id,
    required this.date,
    required this.description,
    this.referenceType,
    this.referenceId,
    DateTime? createdAt,
    this.isVoided = false,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'description': description,
      'reference_type': referenceType?.name.toUpperCase(),
      'reference_id': referenceId,
      'created_at': createdAt.toIso8601String(),
      'is_voided': isVoided ? 1 : 0,
    };
  }

  factory JournalHeader.fromMap(Map<String, dynamic> map) {
    return JournalHeader(
      id: map['id'],
      date: DateTime.parse(map['date']),
      description: map['description'],
      referenceType: map['reference_type'] != null
          ? ReferenceType.values.firstWhere(
              (e) => e.name.toUpperCase() == map['reference_type'],
            )
          : null,
      referenceId: map['reference_id'],
      createdAt: DateTime.parse(map['created_at']),
      isVoided: map['is_voided'] == 1,
    );
  }

  JournalHeader copyWith({
    int? id,
    DateTime? date,
    String? description,
    ReferenceType? referenceType,
    int? referenceId,
    DateTime? createdAt,
    bool? isVoided,
  }) {
    return JournalHeader(
      id: id ?? this.id,
      date: date ?? this.date,
      description: description ?? this.description,
      referenceType: referenceType ?? this.referenceType,
      referenceId: referenceId ?? this.referenceId,
      createdAt: createdAt ?? this.createdAt,
      isVoided: isVoided ?? this.isVoided,
    );
  }
}
