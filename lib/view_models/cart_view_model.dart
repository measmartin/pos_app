import 'package:flutter/foundation.dart';
import '../models/product.dart';
import '../models/cart_item.dart';
import '../models/journal_entry.dart';
import '../services/database_service.dart';
import '../services/notification_service.dart';

class CartViewModel extends ChangeNotifier {
  final List<CartItem> _items = [];
  List<CartItem> get items => _items;

  double get totalAmount => _items.fold(0, (sum, item) => sum + item.subtotal);

  void addToCart(Product product) {
    // Check if product already exists in cart
    final index = _items.indexWhere((item) => item.product.id == product.id);
    if (index >= 0) {
      _items[index].quantity++;
    } else {
      _items.add(CartItem(product: product));
    }
    notifyListeners();
  }

  void removeFromCart(Product product) {
    final index = _items.indexWhere((item) => item.product.id == product.id);
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
        // 1. Update Inventory
        await txn.rawUpdate(
          'UPDATE products SET stockQuantity = stockQuantity - ? WHERE id = ?',
          [item.quantity, item.product.id],
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
             // Schedule/Show notification (Needs to be outside transaction loop ideally or safe to call)
             // We can't await async notification nicely inside transaction if it takes time, 
             // but fire and forget is okay.
             NotificationService().showNotification(
               item.product.id ?? 0, 
               'Low Stock Alert', 
               '$productName is running low ($newStock left)!'
             );
          }
        }
      }

      // 2. Create Journal Entries
      // Debit Cash (Asset)
      await txn.insert('journal_entries', JournalEntry(
        date: date,
        type: 'DEBIT',
        description: 'Cash Sale - ${items.length} items',
        amount: total,
      ).toMap());

      // Credit Sales (Income)
      await txn.insert('journal_entries', JournalEntry(
        date: date,
        type: 'CREDIT',
        description: 'Sales Revenue',
        amount: total,
      ).toMap());
    });

    clearCart();
    return true;
  }
}
