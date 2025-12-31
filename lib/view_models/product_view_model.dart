import 'package:flutter/foundation.dart';
import '../models/product.dart';
import '../models/product_unit.dart';
import '../services/database_service.dart';

class ProductViewModel extends ChangeNotifier {
  List<Product> _products = [];
  List<Product> get products => _products;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  final DatabaseService _databaseService = DatabaseService();

  Future<List<Product>> fetchTrendingProducts() async {
    return await _databaseService.getTrendingProducts();
  }

  /// Fetch products with optimized single-query approach
  /// Uses LEFT JOIN to avoid N+1 query problem
  Future<void> fetchProducts() async {
    _isLoading = true;
    notifyListeners();

    try {
      final db = await _databaseService.database;
      
      // Single query with LEFT JOIN instead of N+1 queries
      final result = await db.rawQuery('''
        SELECT 
          p.id as product_id,
          p.name as product_name,
          p.barcode,
          p.costPrice,
          p.sellingPrice,
          p.stockQuantity,
          p.unit,
          p.image_path,
          pu.id as unit_id,
          pu.name as unit_name,
          pu.factor as unit_factor,
          pu.selling_price as unit_selling_price
        FROM products p
        LEFT JOIN product_units pu ON p.id = pu.product_id
        ORDER BY p.name ASC
      ''');
      
      // Group results by product
      final productMap = <int, Product>{};
      
      for (var row in result) {
        final productId = row['product_id'] as int;
        
        // Create product if not already in map
        if (!productMap.containsKey(productId)) {
          productMap[productId] = Product(
            id: productId,
            name: row['product_name'] as String,
            barcode: (row['barcode'] as String?) ?? '',
            costPrice: (row['costPrice'] as num?)?.toDouble() ?? 0.0,
            sellingPrice: (row['sellingPrice'] as num?)?.toDouble() ?? 0.0,
            stockQuantity: (row['stockQuantity'] as int?) ?? 0,
            unit: (row['unit'] as String?) ?? '',
            imagePath: row['image_path'] as String?,
            additionalUnits: [],
          );
        }
        
        // Add unit if present
        if (row['unit_id'] != null) {
          productMap[productId]!.additionalUnits.add(ProductUnit(
            id: row['unit_id'] as int,
            productId: productId,
            name: row['unit_name'] as String,
            factor: (row['unit_factor'] as num).toDouble(),
            sellingPrice: (row['unit_selling_price'] as num?)?.toDouble(),
          ));
        }
      }
      
      _products = productMap.values.toList();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  Future<void> addProductUnit(ProductUnit unit) async {
    final db = await _databaseService.database;
    await db.insert('product_units', unit.toMap());
    await fetchProducts(); // Refresh all to update the specific product
  }

  Future<void> deleteProductUnit(int unitId, int productId) async {
    final db = await _databaseService.database;
    await db.delete('product_units', where: 'id = ?', whereArgs: [unitId]);
    await fetchProducts();
  }

  Future<void> addProduct(Product product) async {
    final db = await _databaseService.database;
    await db.insert('products', product.toMap());
    await fetchProducts();
  }

  Future<void> updateProduct(Product product) async {
    final db = await _databaseService.database;
    await db.update(
      'products',
      product.toMap(),
      where: 'id = ?',
      whereArgs: [product.id],
    );
    await fetchProducts();
  }

  Future<void> deleteProduct(int id) async {
    final db = await _databaseService.database;
    await db.delete(
      'products',
      where: 'id = ?',
      whereArgs: [id],
    );
    await fetchProducts();
  }
}
