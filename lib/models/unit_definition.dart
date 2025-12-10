class UnitDefinition {
  final int? id;
  final String name;      // e.g. "Pack"
  final String baseUnit;  // e.g. "Can"
  final double factor;    // e.g. 6.0

  UnitDefinition({
    this.id,
    required this.name,
    required this.baseUnit,
    required this.factor,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'base_unit': baseUnit,
      'factor': factor,
    };
  }

  factory UnitDefinition.fromMap(Map<String, dynamic> map) {
    return UnitDefinition(
      id: map['id'],
      name: map['name'],
      baseUnit: map['base_unit'],
      factor: map['factor'],
    );
  }
}
