import 'package:flutter/foundation.dart';
import '../services/database_service.dart';

class JournalViewModel extends ChangeNotifier {
  final DatabaseService _databaseService = DatabaseService();
  
  List<Map<String, dynamic>> _journalPages = [];
  List<Map<String, dynamic>> get journalPages => _journalPages;

  Future<void> fetchEntries() async {
    final db = await _databaseService.database;
    
    // Fetch headers with lines
    // We want a structure like:
    // [
    //   { 
    //     'header': {id, date, description},
    //     'lines': [ {account_name, debit, credit}, ... ]
    //   }
    // ]
    
    final headers = await db.query('journal_headers', orderBy: 'date DESC');
    
    _journalPages = [];
    
    for (var header in headers) {
      final lines = await db.rawQuery('''
        SELECT l.*, a.name as account_name
        FROM journal_lines l
        JOIN accounts a ON l.account_id = a.id
        WHERE l.header_id = ?
      ''', [header['id']]);
      
      _journalPages.add({
        'header': header,
        'lines': lines,
      });
    }
    
    notifyListeners();
  }

  // Getters for Dashboard metrics (using new structure)
  // Note: We need to define which accounts are "Sales" vs "Purchases" if we strictly use accounting tables.
  // OR we can continue using the helper methods in DatabaseService that query sale_items/purchase_items directly for dashboard stats,
  // which is often cleaner for "Operational Reporting" vs "Financial Reporting".
  // The Dashboard currently uses `getSalesSum` from `DatabaseService` which queries `sale_items`. That logic is still valid and robust.
  
  // We can wrap those service calls here if the UI expects them from this VM.
  Future<double> getSalesToday() async {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day);
    final end = DateTime(now.year, now.month, now.day, 23, 59, 59);
    return await _databaseService.getSalesSum(start, end);
  }

  Future<double> getSalesThisWeek() async {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final start = DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);
    final end = DateTime(now.year, now.month, now.day, 23, 59, 59);
    return await _databaseService.getSalesSum(start, end);
  }

  Future<double> getSalesThisMonth() async {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, 1);
    final lastDay = (now.month < 12) ? DateTime(now.year, now.month + 1, 0) : DateTime(now.year + 1, 1, 0);
    final end = DateTime(lastDay.year, lastDay.month, lastDay.day, 23, 59, 59);
    return await _databaseService.getSalesSum(start, end);
  }

  Future<double> getSalesThisYear() async {
    final now = DateTime.now();
    final start = DateTime(now.year, 1, 1);
    final end = DateTime(now.year, 12, 31, 23, 59, 59);
    return await _databaseService.getSalesSum(start, end);
  }
}
