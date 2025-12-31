import 'package:flutter/foundation.dart';
import 'dart:convert';
import '../models/product_unit.dart';
import '../models/product.dart';
import '../models/cart_item.dart';
import '../models/discount.dart';
import '../models/payment.dart';
import '../services/database_service.dart';
import '../services/notification_service.dart';

class CartViewModel extends ChangeNotifier {
  final List<CartItem> _items = [];
  List<CartItem> get items => _items;

  int? _selectedCustomerId;
  int? get selectedCustomerId => _selectedCustomerId;

  Discount? _cartDiscount; // Cart-level discount
  Discount? get cartDiscount => _cartDiscount;

  /// Get subtotal before any discounts
  double get subtotalBeforeDiscount => _items.fold(
        0,
        (sum, item) => sum + item.subtotalBeforeDiscount,
      );

  /// Get total item-level discount amount
  double get itemDiscountAmount => _items.fold(
        0,
        (sum, item) => sum + item.discountAmount,
      );

  /// Get subtotal after item discounts but before cart discount
  double get subtotalAfterItemDiscounts => subtotalBeforeDiscount - itemDiscountAmount;

  /// Get cart-level discount amount
  double get cartDiscountAmount {
    if (_cartDiscount == null) return 0;
    return _cartDiscount!.calculateAmount(subtotalAfterItemDiscounts);
  }

  /// Get final total amount after all discounts
  double get totalAmount => subtotalAfterItemDiscounts - cartDiscountAmount;

  /// Get total discount amount (item + cart)
  double get totalDiscountAmount => itemDiscountAmount + cartDiscountAmount;

  /// Check if cart has any discounts
  bool get hasDiscounts => itemDiscountAmount > 0 || _cartDiscount != null;

  /// Set the customer for this transaction
  void setCustomer(int? customerId) {
    _selectedCustomerId = customerId;
    notifyListeners();
  }

  /// Clear the selected customer
  void clearCustomer() {
    _selectedCustomerId = null;
    notifyListeners();
  }

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
    _selectedCustomerId = null; // Also clear customer when clearing cart
    _cartDiscount = null; // Also clear cart discount
    notifyListeners();
  }

  /// Apply discount to a specific cart item
  void applyItemDiscount(CartItem item, Discount discount) {
    final index = _items.indexWhere((i) =>
        i.product.id == item.product.id && i.unit?.id == item.unit?.id);

    if (index >= 0) {
      // Create new discount with item scope and key
      final itemDiscount = discount.copyWith(
        scope: DiscountScope.item,
        itemKey: _items[index].key,
      );
      
      // Update the item with the discount
      final updatedItem = CartItem(
        product: _items[index].product,
        quantity: _items[index].quantity,
        unit: _items[index].unit,
        discount: itemDiscount,
      );
      
      _items[index] = updatedItem;
      notifyListeners();
    }
  }

  /// Remove discount from a specific cart item
  void removeItemDiscount(CartItem item) {
    final index = _items.indexWhere((i) =>
        i.product.id == item.product.id && i.unit?.id == item.unit?.id);

    if (index >= 0) {
      final updatedItem = CartItem(
        product: _items[index].product,
        quantity: _items[index].quantity,
        unit: _items[index].unit,
        discount: null, // Remove discount
      );
      
      _items[index] = updatedItem;
      notifyListeners();
    }
  }

  /// Apply discount to entire cart
  void applyCartDiscount(Discount discount) {
    _cartDiscount = discount.copyWith(scope: DiscountScope.cart);
    notifyListeners();
  }

  /// Remove cart-level discount
  void removeCartDiscount() {
    _cartDiscount = null;
    notifyListeners();
  }

  /// Clear all discounts (item and cart level)
  void clearAllDiscounts() {
    // Clear item discounts
    for (int i = 0; i < _items.length; i++) {
      if (_items[i].hasDiscount) {
        _items[i] = CartItem(
          product: _items[i].product,
          quantity: _items[i].quantity,
          unit: _items[i].unit,
          discount: null,
        );
      }
    }
    
    // Clear cart discount
    _cartDiscount = null;
    notifyListeners();
  }

  // Checkout will return transaction ID if successful, null otherwise
  Future<String?> checkout({List<Payment>? payments}) async {
    if (_items.isEmpty) return null;

    final dbService = DatabaseService();
    final db = await dbService.database;
    final date = DateTime.now();
    
    // Generate transaction ID
    final transactionId = '${date.millisecondsSinceEpoch}';
    
    // Calculate amounts
    final subtotal = subtotalBeforeDiscount;
    final discountAmt = totalDiscountAmount;
    final finalAmount = totalAmount;
    
    // Default to cash payment if no payments specified
    final paymentList = payments ?? [
      Payment(
        method: PaymentMethodType.cash,
        amount: finalAmount,
        paidAt: date,
      )
    ];
    
    final paidAmount = paymentList.fold(0.0, (sum, p) => sum + p.amount);
    final changeAmount = paidAmount > finalAmount ? paidAmount - finalAmount : 0;

    // Start a database transaction
    await db.transaction((txn) async {
      // 1. Create transaction record
      await txn.insert('transactions', {
        'id': transactionId,
        'customer_id': _selectedCustomerId,
        'total_amount': subtotal,
        'discount_amount': discountAmt,
        'final_amount': finalAmount,
        'paid_amount': paidAmount,
        'change_amount': changeAmount,
        'status': 'completed',
        'created_at': date.toIso8601String(),
        'completed_at': date.toIso8601String(),
      });

      // 2. Save payments
      for (var payment in paymentList) {
        await txn.insert('payments', {
          'transaction_id': transactionId,
          'method': payment.method.name,
          'amount': payment.amount,
          'reference': payment.reference,
          'notes': payment.notes,
          'paid_at': payment.paidAt.toIso8601String(),
        });
      }

      // 3. Save cart-level discount if exists
      if (_cartDiscount != null) {
        await txn.insert('discounts', {
          'transaction_id': transactionId,
          'type': _cartDiscount!.type.name,
          'scope': _cartDiscount!.scope.name,
          'value': _cartDiscount!.value,
          'reason': _cartDiscount!.reason,
          'item_key': null,
          'applied_at': _cartDiscount!.appliedAt.toIso8601String(),
        });
      }

      // 4. Process each cart item
      for (var item in _items) {
        // Calculate factor (how many base units)
        double factor = item.unit?.factor ?? 1.0;
        int totalBaseUnitsDeducted = (item.quantity * factor).round();

        // Update Inventory
        await txn.rawUpdate(
          'UPDATE products SET stockQuantity = stockQuantity - ? WHERE id = ?',
          [totalBaseUnitsDeducted, item.product.id],
        );

        // Check for low stock
        final List<Map<String, dynamic>> result = await txn.query(
          'products',
          columns: ['stockQuantity', 'name'],
          where: 'id = ?',
          whereArgs: [item.product.id],
        );

        if (result.isNotEmpty) {
          final newStock = result.first['stockQuantity'] as int;
          final productName = result.first['name'] as String;
          if (newStock < 5) {
            // Threshold 5
            // Notification logic (fire and forget)
            NotificationService().showNotification(
              item.product.id ?? 0,
              'Low Stock Alert',
              '$productName is running low ($newStock left)!',
            );
          }
        }

        // Save item-level discount if exists
        if (item.hasDiscount) {
          await txn.insert('discounts', {
            'transaction_id': transactionId,
            'type': item.discount!.type.name,
            'scope': item.discount!.scope.name,
            'value': item.discount!.value,
            'reason': item.discount!.reason,
            'item_key': item.key,
            'applied_at': item.discount!.appliedAt.toIso8601String(),
          });
        }

        // Record Sale Item
        await txn.insert('sale_items', {
          'product_id': item.product.id,
          'quantity': item.quantity, // Count of units sold
          'date': date.toIso8601String(),
          'selling_price': item.unitPrice, // Store original unit price
          'discount_amount': item.discountAmount,
          'customer_id': _selectedCustomerId,
          'transaction_id': transactionId,
          'unit_name': item.unit?.name,
        });
      }

      // 5. Update customer stats if customer is selected
      if (_selectedCustomerId != null) {
        final customerData = await txn.query(
          'customers',
          where: 'id = ?',
          whereArgs: [_selectedCustomerId],
          limit: 1,
        );

        if (customerData.isNotEmpty) {
          final currentTotalSpent =
              (customerData.first['total_spent'] as num?)?.toDouble() ?? 0.0;
          final currentLoyaltyPoints =
              (customerData.first['loyalty_points'] as num?)?.toDouble() ?? 0.0;

          // Calculate new values (use final amount after discount)
          final newTotalSpent = currentTotalSpent + finalAmount;
          final pointsEarned = finalAmount * 0.01; // 1% of purchase as points
          final newLoyaltyPoints = currentLoyaltyPoints + pointsEarned;

          // Update customer
          await txn.update(
            'customers',
            {
              'total_spent': newTotalSpent,
              'loyalty_points': newLoyaltyPoints,
              'last_purchase_date': date.toIso8601String(),
            },
            where: 'id = ?',
            whereArgs: [_selectedCustomerId],
          );
        }
      }

      // 6. Create Journal Entry (Transaction)
      final headerId = await txn.insert('journal_headers', {
        'date': date.toIso8601String(),
        'description': 'Sale - ${items.length} items${hasDiscounts ? " (Discounted)" : ""}',
        'reference_type': 'SALE',
      });

      // Get Account IDs
      final cashAccount = await txn.query('accounts',
          where: 'name = ?', whereArgs: ['Cash on Hand - USD']);
      final salesAccount = await txn.query('accounts',
          where: 'name = ?', whereArgs: ['Sales Revenue - USD']);

      final cashId = cashAccount.first['id'];
      final salesId = salesAccount.first['id'];

      // Post 1: Debit Cash (Asset Increases) - use final amount
      await txn.insert('journal_lines', {
        'header_id': headerId,
        'account_id': cashId,
        'debit': finalAmount,
        'credit': 0,
      });

      // Post 2: Credit Sales Revenue (Income Increases)
      await txn.insert('journal_lines', {
        'header_id': headerId,
        'account_id': salesId,
        'debit': 0,
        'credit': finalAmount,
      });
    });

    clearCart();
    return transactionId;
  }

  /// Hold/park current transaction
  Future<String?> holdTransaction({String? notes}) async {
    if (_items.isEmpty) return null;

    try {
      final dbService = DatabaseService();
      final db = await dbService.database;
      final date = DateTime.now();
      final holdId = '${date.millisecondsSinceEpoch}';

      // Serialize cart state
      final cartData = {
        'items': _items.map((item) {
          return {
            'product': item.product.toMap(),
            'quantity': item.quantity,
            'unit': item.unit?.toMap(),
            'discount': item.discount?.toMap(),
          };
        }).toList(),
        'cartDiscount': _cartDiscount?.toMap(),
      };

      await db.insert('held_transactions', {
        'id': holdId,
        'cart_data': jsonEncode(cartData),
        'customer_id': _selectedCustomerId,
        'created_at': date.toIso8601String(),
        'notes': notes,
      });

      clearCart();
      return holdId;
    } catch (e) {
      debugPrint('Error holding transaction: $e');
      return null;
    }
  }

  /// Recall/restore held transaction
  Future<bool> recallTransaction(String holdId) async {
    try {
      final dbService = DatabaseService();
      final db = await dbService.database;

      final results = await db.query(
        'held_transactions',
        where: 'id = ?',
        whereArgs: [holdId],
      );

      if (results.isEmpty) return false;

      final heldData = results.first;
      final cartDataJson = heldData['cart_data'] as String;
      final cartData = jsonDecode(cartDataJson) as Map<String, dynamic>;

      // Clear current cart
      clearCart();

      // Restore items
      final itemsList = cartData['items'] as List;
      for (var itemData in itemsList) {
        final product = Product.fromMap(itemData['product'] as Map<String, dynamic>);
        final quantity = itemData['quantity'] as int;
        final unitData = itemData['unit'] as Map<String, dynamic>?;
        final discountData = itemData['discount'] as Map<String, dynamic>?;

        ProductUnit? unit;
        if (unitData != null) {
          unit = ProductUnit.fromMap(unitData);
        }

        Discount? discount;
        if (discountData != null) {
          discount = Discount.fromMap(discountData);
        }

        final cartItem = CartItem(
          product: product,
          quantity: quantity,
          unit: unit,
          discount: discount,
        );

        _items.add(cartItem);
      }

      // Restore cart discount
      final cartDiscountData = cartData['cartDiscount'] as Map<String, dynamic>?;
      if (cartDiscountData != null) {
        _cartDiscount = Discount.fromMap(cartDiscountData);
      }

      // Restore customer
      _selectedCustomerId = heldData['customer_id'] as int?;

      // Delete held transaction
      await db.delete('held_transactions', where: 'id = ?', whereArgs: [holdId]);

      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error recalling transaction: $e');
      return false;
    }
  }

  /// Get list of held transactions
  Future<List<Map<String, dynamic>>> getHeldTransactions() async {
    final dbService = DatabaseService();
    final db = await dbService.database;

    return await db.rawQuery('''
      SELECT 
        h.*,
        c.name as customer_name
      FROM held_transactions h
      LEFT JOIN customers c ON h.customer_id = c.id
      ORDER BY h.created_at DESC
    ''');
  }

  /// Delete a held transaction
  Future<bool> deleteHeldTransaction(String holdId) async {
    try {
      final dbService = DatabaseService();
      final db = await dbService.database;
      await db.delete('held_transactions', where: 'id = ?', whereArgs: [holdId]);
      return true;
    } catch (e) {
      debugPrint('Error deleting held transaction: $e');
      return false;
    }
  }
}
