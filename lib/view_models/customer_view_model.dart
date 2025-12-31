import 'package:flutter/foundation.dart';
import '../models/customer.dart';
import '../services/database_service.dart';

class CustomerViewModel extends ChangeNotifier {
  final DatabaseService _databaseService = DatabaseService();

  List<Customer> _customers = [];
  List<Customer> get customers => _customers;

  List<Customer> _filteredCustomers = [];
  List<Customer> get filteredCustomers => _filteredCustomers;

  String _searchQuery = '';
  String get searchQuery => _searchQuery;

  bool _showInactiveCustomers = false;
  bool get showInactiveCustomers => _showInactiveCustomers;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  // Caching for stats
  Map<String, dynamic>? _cachedStats;
  DateTime? _statsLastUpdated;
  final Duration _statsCacheDuration = Duration(minutes: 5);

  /// Fetch all customers from database
  Future<void> fetchCustomers() async {
    _isLoading = true;
    notifyListeners();

    try {
      final db = await _databaseService.database;
      final List<Map<String, dynamic>> maps = await db.query(
        'customers',
        orderBy: 'name ASC',
      );

      _customers = maps.map((map) => Customer.fromMap(map)).toList();
      _applyFilters();
      _invalidateStatsCache();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Invalidate stats cache when data changes
  void _invalidateStatsCache() {
    _cachedStats = null;
    _statsLastUpdated = null;
  }

  /// Add a new customer
  Future<bool> addCustomer(Customer customer) async {
    try {
      final db = await _databaseService.database;
      final id = await db.insert('customers', customer.toMap());

      final newCustomer = customer.copyWith(id: id);
      _customers.add(newCustomer);
      _applyFilters();
      _invalidateStatsCache();
      notifyListeners();

      return true;
    } catch (e) {
      debugPrint('Error adding customer: $e');
      return false;
    }
  }

  /// Update an existing customer
  Future<bool> updateCustomer(Customer customer) async {
    if (customer.id == null) return false;

    try {
      final db = await _databaseService.database;
      await db.update(
        'customers',
        customer.toMap(),
        where: 'id = ?',
        whereArgs: [customer.id],
      );

      final index = _customers.indexWhere((c) => c.id == customer.id);
      if (index != -1) {
        _customers[index] = customer;
        _applyFilters();
        _invalidateStatsCache();
        notifyListeners();
      }

      return true;
    } catch (e) {
      debugPrint('Error updating customer: $e');
      return false;
    }
  }

  /// Delete a customer (soft delete - mark as inactive)
  Future<bool> deleteCustomer(int customerId) async {
    try {
      final db = await _databaseService.database;
      
      // Soft delete - mark as inactive
      await db.update(
        'customers',
        {'is_active': 0},
        where: 'id = ?',
        whereArgs: [customerId],
      );

      final index = _customers.indexWhere((c) => c.id == customerId);
      if (index != -1) {
        _customers[index] = _customers[index].copyWith(isActive: false);
        _applyFilters();
        _invalidateStatsCache();
        notifyListeners();
      }

      return true;
    } catch (e) {
      debugPrint('Error deleting customer: $e');
      return false;
    }
  }

  /// Permanently delete a customer
  Future<bool> permanentlyDeleteCustomer(int customerId) async {
    try {
      final db = await _databaseService.database;
      await db.delete(
        'customers',
        where: 'id = ?',
        whereArgs: [customerId],
      );

      _customers.removeWhere((c) => c.id == customerId);
      _applyFilters();
      notifyListeners();

      return true;
    } catch (e) {
      debugPrint('Error permanently deleting customer: $e');
      return false;
    }
  }

  /// Restore an inactive customer
  Future<bool> restoreCustomer(int customerId) async {
    try {
      final db = await _databaseService.database;
      await db.update(
        'customers',
        {'is_active': 1},
        where: 'id = ?',
        whereArgs: [customerId],
      );

      final index = _customers.indexWhere((c) => c.id == customerId);
      if (index != -1) {
        _customers[index] = _customers[index].copyWith(isActive: true);
        _applyFilters();
        notifyListeners();
      }

      return true;
    } catch (e) {
      debugPrint('Error restoring customer: $e');
      return false;
    }
  }

  /// Get a single customer by ID
  Future<Customer?> getCustomer(int customerId) async {
    final db = await _databaseService.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'customers',
      where: 'id = ?',
      whereArgs: [customerId],
      limit: 1,
    );

    if (maps.isEmpty) return null;
    return Customer.fromMap(maps.first);
  }

  /// Search customers by name, phone, or email
  void searchCustomers(String query) {
    _searchQuery = query.toLowerCase();
    _applyFilters();
    notifyListeners();
  }

  /// Toggle showing inactive customers
  void toggleShowInactive() {
    _showInactiveCustomers = !_showInactiveCustomers;
    _applyFilters();
    notifyListeners();
  }

  /// Apply search and filter criteria
  void _applyFilters() {
    _filteredCustomers = _customers.where((customer) {
      // Filter by active status
      if (!_showInactiveCustomers && !customer.isActive) {
        return false;
      }

      // Filter by search query
      if (_searchQuery.isNotEmpty) {
        final nameMatch = customer.name.toLowerCase().contains(_searchQuery);
        final phoneMatch = customer.phone?.toLowerCase().contains(_searchQuery) ?? false;
        final emailMatch = customer.email?.toLowerCase().contains(_searchQuery) ?? false;
        
        return nameMatch || phoneMatch || emailMatch;
      }

      return true;
    }).toList();
  }

  /// Clear search
  void clearSearch() {
    _searchQuery = '';
    _applyFilters();
    notifyListeners();
  }

  /// Update customer's total spent and last purchase date
  Future<bool> updateCustomerPurchase(
    int customerId,
    double amount,
    DateTime purchaseDate,
  ) async {
    try {
      final db = await _databaseService.database;
      
      // Get current customer data
      final customer = await getCustomer(customerId);
      if (customer == null) return false;

      final newTotalSpent = customer.totalSpent + amount;
      final newLoyaltyPoints = customer.loyaltyPoints + (amount * 0.01); // 1% of purchase

      await db.update(
        'customers',
        {
          'total_spent': newTotalSpent,
          'loyalty_points': newLoyaltyPoints,
          'last_purchase_date': purchaseDate.toIso8601String(),
        },
        where: 'id = ?',
        whereArgs: [customerId],
      );

      // Update local data
      final index = _customers.indexWhere((c) => c.id == customerId);
      if (index != -1) {
        _customers[index] = _customers[index].copyWith(
          totalSpent: newTotalSpent,
          loyaltyPoints: newLoyaltyPoints,
          lastPurchaseDate: purchaseDate,
        );
        _applyFilters();
        notifyListeners();
      }

      return true;
    } catch (e) {
      debugPrint('Error updating customer purchase: $e');
      return false;
    }
  }

  /// Redeem loyalty points
  Future<bool> redeemLoyaltyPoints(int customerId, double points) async {
    try {
      final db = await _databaseService.database;
      
      // Get current customer data
      final customer = await getCustomer(customerId);
      if (customer == null) return false;

      if (customer.loyaltyPoints < points) {
        debugPrint('Insufficient loyalty points');
        return false;
      }

      final newLoyaltyPoints = customer.loyaltyPoints - points;

      await db.update(
        'customers',
        {'loyalty_points': newLoyaltyPoints},
        where: 'id = ?',
        whereArgs: [customerId],
      );

      // Update local data
      final index = _customers.indexWhere((c) => c.id == customerId);
      if (index != -1) {
        _customers[index] = _customers[index].copyWith(
          loyaltyPoints: newLoyaltyPoints,
        );
        _applyFilters();
        notifyListeners();
      }

      return true;
    } catch (e) {
      debugPrint('Error redeeming loyalty points: $e');
      return false;
    }
  }

  /// Get customer statistics with caching
  Future<Map<String, dynamic>> getCustomerStats({bool forceRefresh = false}) async {
    // Return cached data if available and fresh
    if (!forceRefresh && 
        _cachedStats != null && 
        _statsLastUpdated != null &&
        DateTime.now().difference(_statsLastUpdated!) < _statsCacheDuration) {
      return _cachedStats!;
    }

    final db = await _databaseService.database;
    
    final result = await db.rawQuery('''
      SELECT 
        COUNT(*) as total_customers,
        COUNT(CASE WHEN is_active = 1 THEN 1 END) as active_customers,
        COUNT(CASE WHEN is_active = 0 THEN 1 END) as inactive_customers,
        SUM(total_spent) as total_revenue,
        AVG(total_spent) as avg_spent_per_customer,
        SUM(loyalty_points) as total_loyalty_points
      FROM customers
    ''');

    if (result.isEmpty) {
      _cachedStats = {
        'total_customers': 0,
        'active_customers': 0,
        'inactive_customers': 0,
        'total_revenue': 0.0,
        'avg_spent_per_customer': 0.0,
        'total_loyalty_points': 0.0,
      };
    } else {
      _cachedStats = {
        'total_customers': result.first['total_customers'] ?? 0,
        'active_customers': result.first['active_customers'] ?? 0,
        'inactive_customers': result.first['inactive_customers'] ?? 0,
        'total_revenue': (result.first['total_revenue'] as num?)?.toDouble() ?? 0.0,
        'avg_spent_per_customer': (result.first['avg_spent_per_customer'] as num?)?.toDouble() ?? 0.0,
        'total_loyalty_points': (result.first['total_loyalty_points'] as num?)?.toDouble() ?? 0.0,
      };
    }

    _statsLastUpdated = DateTime.now();
    return _cachedStats!;
  }

  /// Get top customers by spending
  Future<List<Customer>> getTopCustomers({int limit = 10}) async {
    final db = await _databaseService.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'customers',
      where: 'is_active = 1',
      orderBy: 'total_spent DESC',
      limit: limit,
    );

    return maps.map((map) => Customer.fromMap(map)).toList();
  }

  /// Get customers by tier
  List<Customer> getCustomersByTier(CustomerTier tier) {
    return _customers.where((c) => c.tier == tier && c.isActive).toList();
  }

  /// Get total customer count
  int get totalCustomers => _customers.where((c) => c.isActive).length;

  /// Get inactive customer count
  int get inactiveCustomers => _customers.where((c) => !c.isActive).length;
}
