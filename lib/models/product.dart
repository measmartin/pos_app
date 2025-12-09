class Product {
  final int? id;
  final String name;
  final String barcode;
  final double costPrice;
  final double sellingPrice;
  final int stockQuantity;
  final String unit;

  Product({
    this.id,
    required this.name,
    required this.barcode,
    required this.costPrice,
    required this.sellingPrice,
    required this.stockQuantity,
    required this.unit,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'barcode': barcode,
      'costPrice': costPrice,
      'sellingPrice': sellingPrice,
      'stockQuantity': stockQuantity,
      'unit': unit,
    };
  }

  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      id: map['id'],
      name: map['name'],
      barcode: map['barcode'],
      costPrice: map['costPrice'],
      sellingPrice: map['sellingPrice'],
      stockQuantity: map['stockQuantity'],
      unit: map['unit'],
    );
  }
}
