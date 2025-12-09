import 'package:flutter/foundation.dart';
import '../models/product.dart';
import '../services/database_service.dart';

class ProductViewModel extends ChangeNotifier {
  List<Product> _products = [];
  List<Product> get products => _products;

  final DatabaseService _databaseService = DatabaseService();

  Future<void> fetchProducts() async {
    final db = await _databaseService.database;
    final List<Map<String, dynamic>> maps = await db.query('products');
    _products = List.generate(maps.length, (i) => Product.fromMap(maps[i]));
    notifyListeners();
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
