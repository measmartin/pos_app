import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import '../models/stock_adjustment.dart';
import '../models/product.dart';
import '../services/database_service.dart';

class StockAdjustmentViewModel extends ChangeNotifier {
  final DatabaseService _databaseService = DatabaseService();
  
  List<StockAdjustment> _adjustments = [];
  List<StockAdjustment> get adjustments => _adjustments;

  /// Fetch all stock adjustments
  Future<void> fetchAdjustments() async {
    final db = await _databaseService.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'stock_adjustments',
      orderBy: 'date DESC',
    );
    _adjustments = maps.map((map) => StockAdjustment.fromMap(map)).toList();
    notifyListeners();
  }

  /// Fetch adjustments for a specific product
  Future<List<StockAdjustment>> getAdjustmentsForProduct(int productId) async {
    final db = await _databaseService.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'stock_adjustments',
      where: 'product_id = ?',
      whereArgs: [productId],
      orderBy: 'date DESC',
    );
    return maps.map((map) => StockAdjustment.fromMap(map)).toList();
  }

  /// Create a stock adjustment and update product quantity
  Future<bool> createAdjustment({
    required Product product,
    required int quantityChange,
    required AdjustmentType type,
    required AdjustmentReason reason,
    String? notes,
  }) async {
    final db = await _databaseService.database;

    try {
      await db.transaction((txn) async {
        final oldQuantity = product.stockQuantity;
        final newQuantity = oldQuantity + quantityChange;

        // Validate new quantity
        if (newQuantity < 0) {
          throw Exception('Stock quantity cannot be negative');
        }

        // Create adjustment record
        final adjustment = StockAdjustment(
          productId: product.id!,
          quantityChange: quantityChange,
          oldQuantity: oldQuantity,
          newQuantity: newQuantity,
          type: type,
          reason: reason,
          notes: notes,
        );

        await txn.insert('stock_adjustments', adjustment.toMap());

        // Update product stock quantity
        await txn.update(
          'products',
          {'stockQuantity': newQuantity},
          where: 'id = ?',
          whereArgs: [product.id],
        );

        // Create journal entry for inventory adjustments
        if (quantityChange != 0) {
          await _createInventoryJournalEntry(
            txn,
            product,
            quantityChange,
            reason,
          );
        }
      });

      await fetchAdjustments();
      return true;
    } catch (e) {
      debugPrint('Error creating stock adjustment: $e');
      return false;
    }
  }

  /// Create journal entry for inventory adjustment
  Future<void> _createInventoryJournalEntry(
    Transaction txn,
    Product product,
    int quantityChange,
    AdjustmentReason reason,
  ) async {
    // Get inventory and adjustment accounts
    final inventoryAccount = await txn.query(
      'accounts',
      where: 'name = ?',
      whereArgs: ['Inventory - USD'],
      limit: 1,
    );

    // For adjustments, we typically adjust inventory and a corresponding expense/income account
    if (inventoryAccount.isEmpty) return;

    final inventoryAccountId = inventoryAccount.first['id'] as int;
    final amount = (quantityChange.abs() * product.costPrice).abs();

    // Create journal header
    final headerId = await txn.insert('journal_headers', {
      'date': DateTime.now().toIso8601String(),
      'description': 'Stock Adjustment: ${reason.displayName}',
      'reference_type': 'ADJUSTMENT',
      'reference_id': null,
    });

    if (quantityChange > 0) {
      // Addition: Debit Inventory, Credit appropriate account
      await txn.insert('journal_lines', {
        'header_id': headerId,
        'account_id': inventoryAccountId,
        'debit': amount,
        'credit': 0,
        'description': 'Inventory increase',
      });
    } else {
      // Subtraction: Credit Inventory, Debit expense
      await txn.insert('journal_lines', {
        'header_id': headerId,
        'account_id': inventoryAccountId,
        'debit': 0,
        'credit': amount,
        'description': 'Inventory decrease',
      });
    }

    // Update inventory account balance
    await txn.rawUpdate('''
      UPDATE accounts 
      SET balance = balance + ? 
      WHERE id = ?
    ''', [quantityChange > 0 ? amount : -amount, inventoryAccountId]);
  }

  /// Get adjustment statistics for a product
  Future<Map<String, dynamic>> getAdjustmentStats(int productId) async {
    final db = await _databaseService.database;
    
    final result = await db.rawQuery('''
      SELECT 
        COUNT(*) as total_adjustments,
        SUM(CASE WHEN quantity_change > 0 THEN quantity_change ELSE 0 END) as total_additions,
        SUM(CASE WHEN quantity_change < 0 THEN ABS(quantity_change) ELSE 0 END) as total_subtractions,
        MIN(date) as first_adjustment,
        MAX(date) as last_adjustment
      FROM stock_adjustments
      WHERE product_id = ?
    ''', [productId]);

    if (result.isEmpty) {
      return {
        'total_adjustments': 0,
        'total_additions': 0,
        'total_subtractions': 0,
        'first_adjustment': null,
        'last_adjustment': null,
      };
    }

    return {
      'total_adjustments': result.first['total_adjustments'] ?? 0,
      'total_additions': result.first['total_additions'] ?? 0,
      'total_subtractions': result.first['total_subtractions'] ?? 0,
      'first_adjustment': result.first['first_adjustment'],
      'last_adjustment': result.first['last_adjustment'],
    };
  }

  /// Delete an adjustment (admin only - should be used carefully)
  Future<bool> deleteAdjustment(int adjustmentId) async {
    final db = await _databaseService.database;
    
    try {
      await db.delete(
        'stock_adjustments',
        where: 'id = ?',
        whereArgs: [adjustmentId],
      );
      
      await fetchAdjustments();
      return true;
    } catch (e) {
      debugPrint('Error deleting adjustment: $e');
      return false;
    }
  }
}
