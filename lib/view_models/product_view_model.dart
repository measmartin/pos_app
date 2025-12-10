import 'package:flutter/foundation.dart';
import '../models/product.dart';
import '../models/product_unit.dart';
import '../services/database_service.dart';

class ProductViewModel extends ChangeNotifier {
  List<Product> _products = [];
  List<Product> get products => _products;

  final DatabaseService _databaseService = DatabaseService();

  Future<List<Product>> fetchTrendingProducts() async {
    return await _databaseService.getTrendingProducts();
  }

  Future<void> fetchProducts() async {
    final db = await _databaseService.database;
    final List<Map<String, dynamic>> maps = await db.query('products');
    
    // We need to fetch units for each product
    _products = [];
    for (var map in maps) {
      var product = Product.fromMap(map);
      // Fetch units
      final unitsMap = await db.query('product_units', where: 'product_id = ?', whereArgs: [product.id]);
      product.additionalUnits = unitsMap.map((m) => ProductUnit.fromMap(m)).toList();
      _products.add(product);
    }
    notifyListeners();
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
