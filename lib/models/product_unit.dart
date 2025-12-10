class ProductUnit {
  final int? id;
  final int productId;
  final String name;      // e.g., "Pack", "Box"
  final double factor;    // e.g., 6.0 (means 1 Pack = 6 base units)
  final double? sellingPrice; // Optional override price for this unit

  ProductUnit({
    this.id,
    required this.productId,
    required this.name,
    required this.factor,
    this.sellingPrice,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'product_id': productId,
      'name': name,
      'factor': factor,
      'selling_price': sellingPrice,
    };
  }

  factory ProductUnit.fromMap(Map<String, dynamic> map) {
    return ProductUnit(
      id: map['id'],
      productId: map['product_id'],
      name: map['name'],
      factor: map['factor'],
      sellingPrice: map['selling_price'],
    );
  }
}
