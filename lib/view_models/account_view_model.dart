import 'package:flutter/foundation.dart';
import '../models/account.dart';
import '../services/database_service.dart';

class AccountViewModel extends ChangeNotifier {
  List<Account> _accounts = [];
  List<Account> get accounts => _accounts;

  final DatabaseService _databaseService = DatabaseService();

  Future<void> fetchAccounts() async {
    final db = await _databaseService.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'accounts',
      orderBy: 'code ASC',
    );
    _accounts = maps.map((map) => Account.fromMap(map)).toList();
    notifyListeners();
  }

  Future<List<Account>> getAccountsByType(AccountType type) async {
    final db = await _databaseService.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'accounts',
      where: 'type = ? AND is_active = 1',
      whereArgs: [type.name.toUpperCase()],
      orderBy: 'code ASC',
    );
    return maps.map((map) => Account.fromMap(map)).toList();
  }

  Future<Account?> getAccountByName(String name) async {
    final db = await _databaseService.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'accounts',
      where: 'name = ? AND is_active = 1',
      whereArgs: [name],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return Account.fromMap(maps.first);
  }

  Future<Account?> getAccountByCode(String code) async {
    final db = await _databaseService.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'accounts',
      where: 'code = ? AND is_active = 1',
      whereArgs: [code],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return Account.fromMap(maps.first);
  }

  Future<Account?> getAccountById(int id) async {
    final db = await _databaseService.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'accounts',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return Account.fromMap(maps.first);
  }

  Future<double> getAccountBalance(int accountId) async {
    final db = await _databaseService.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'accounts',
      columns: ['balance'],
      where: 'id = ?',
      whereArgs: [accountId],
      limit: 1,
    );
    if (maps.isEmpty) return 0.0;
    return maps.first['balance'] ?? 0.0;
  }

  Future<void> updateAccountBalance(int accountId, double newBalance) async {
    final db = await _databaseService.database;
    await db.update(
      'accounts',
      {'balance': newBalance},
      where: 'id = ?',
      whereArgs: [accountId],
    );
    await fetchAccounts();
  }

  Future<void> addAccount(Account account) async {
    final db = await _databaseService.database;
    await db.insert('accounts', account.toMap());
    await fetchAccounts();
  }

  Future<void> updateAccount(Account account) async {
    final db = await _databaseService.database;
    await db.update(
      'accounts',
      account.toMap(),
      where: 'id = ?',
      whereArgs: [account.id],
    );
    await fetchAccounts();
  }

  Future<void> deactivateAccount(int id) async {
    final db = await _databaseService.database;
    await db.update(
      'accounts',
      {'is_active': 0},
      where: 'id = ?',
      whereArgs: [id],
    );
    await fetchAccounts();
  }

  // Get balance summary by account type
  Future<Map<AccountType, double>> getBalanceSummary() async {
    final db = await _databaseService.database;
    final result = <AccountType, double>{};

    for (var type in AccountType.values) {
      final List<Map<String, dynamic>> maps = await db.rawQuery(
        'SELECT SUM(balance) as total FROM accounts WHERE type = ? AND is_active = 1',
        [type.name.toUpperCase()],
      );
      result[type] = maps.first['total'] ?? 0.0;
    }

    return result;
  }
}
