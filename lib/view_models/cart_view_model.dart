import 'package:flutter/foundation.dart';
import '../models/product_unit.dart';
import '../models/product.dart';
import '../models/cart_item.dart';
import '../models/journal_entry.dart';
import '../services/database_service.dart';
import '../services/notification_service.dart';

class CartViewModel extends ChangeNotifier {
  final List<CartItem> _items = [];
  List<CartItem> get items => _items;

  double get totalAmount => _items.fold(0, (sum, item) => sum + item.subtotal);

  void addToCart(Product product, {ProductUnit? unit}) {
    // Check if product with this specific unit already exists in cart
    final index = _items.indexWhere((item) => 
      item.product.id == product.id && 
      item.unit?.id == unit?.id
    );

    if (index >= 0) {
      _items[index].quantity++;
    } else {
      _items.add(CartItem(product: product, unit: unit));
    }
    notifyListeners();
  }

  void removeFromCart(Product product, {ProductUnit? unit}) {
    final index = _items.indexWhere((item) => 
      item.product.id == product.id && 
      item.unit?.id == unit?.id
    );

    if (index >= 0) {
      if (_items[index].quantity > 1) {
        _items[index].quantity--;
      } else {
        _items.removeAt(index);
      }
      notifyListeners();
    }
  }

  void clearCart() {
    _items.clear();
    notifyListeners();
  }

  // Checkout will return true if successful
  Future<bool> checkout() async {
    if (_items.isEmpty) return false;

    final dbService = DatabaseService();
    final db = await dbService.database;
    final total = totalAmount;
    final date = DateTime.now();

    // Start a transaction
    await db.transaction((txn) async {
      for (var item in _items) {
        // Calculate factor (how many base units)
        double factor = item.unit?.factor ?? 1.0;
        int totalBaseUnitsDeducted = (item.quantity * factor).round();

        // 1. Update Inventory
        await txn.rawUpdate(
          'UPDATE products SET stockQuantity = stockQuantity - ? WHERE id = ?',
          [totalBaseUnitsDeducted, item.product.id],
        );

        // Check for low stock
        final List<Map<String, dynamic>> result = await txn.query(
          'products', 
          columns: ['stockQuantity', 'name'], 
          where: 'id = ?', 
          whereArgs: [item.product.id]
        );
        
        if (result.isNotEmpty) {
          final newStock = result.first['stockQuantity'] as int;
          final productName = result.first['name'] as String;
          if (newStock < 5) { // Threshold 5
             // Notification logic (fire and forget)
             NotificationService().showNotification(
               item.product.id ?? 0, 
               'Low Stock Alert', 
               '$productName is running low ($newStock left)!'
             );
          }
        }
      }

      // 2. Record Sale Items
      for (var item in _items) {
        await txn.insert('sale_items', {
          'product_id': item.product.id,
          'quantity': item.quantity, // We store COUNT of units sold
          'date': date.toIso8601String(),
          // Store the price it was sold at (unit price or calculated)
          'selling_price': item.subtotal / item.quantity, 
        });
      }

      // 3. Create Journal Page (Transaction)
      final headerId = await txn.insert('journal_headers', {
        'date': date.toIso8601String(),
        'description': 'Sale - ${items.length} items',
        'reference_type': 'SALE',
      });

      // Get Account IDs
      final cashAccount = await txn.query('accounts', where: 'name = ?', whereArgs: ['Cash on Hand - USD']);
      final salesAccount = await txn.query('accounts', where: 'name = ?', whereArgs: ['Sales Revenue - USD']);
      
      final cashId = cashAccount.first['id'];
      final salesId = salesAccount.first['id'];

      // Post 1: Debit Cash (Asset Increases)
      await txn.insert('journal_lines', {
        'header_id': headerId,
        'account_id': cashId,
        'debit': total,
        'credit': 0,
      });

      // Post 2: Credit Sales Revenue (Income Increases)
      await txn.insert('journal_lines', {
        'header_id': headerId,
        'account_id': salesId,
        'debit': 0,
        'credit': total,
      });
    });

    clearCart();
    return true;
  }
}
