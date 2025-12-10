import 'product_unit.dart';

class Product {
  final int? id;
  final String name;
  final String barcode;
  final double costPrice;
  final double sellingPrice;
  final int stockQuantity; // Base unit quantity
  final String unit; // Base unit name (e.g., "pcs")
  final String? imagePath;
  List<ProductUnit> additionalUnits;

  Product({
    this.id,
    required this.name,
    required this.barcode,
    required this.costPrice,
    required this.sellingPrice,
    required this.stockQuantity,
    required this.unit,
    this.imagePath,
    this.additionalUnits = const [],
  });
  
  // Helper to get total stock in a specific unit representation
  double getStockInUnit(ProductUnit? targetUnit) {
    if (targetUnit == null) return stockQuantity.toDouble();
    return stockQuantity / targetUnit.factor;
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'barcode': barcode,
      'costPrice': costPrice,
      'sellingPrice': sellingPrice,
      'stockQuantity': stockQuantity,
      'unit': unit,
      'image_path': imagePath,
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
      imagePath: map['image_path'],
    );
  }
}
