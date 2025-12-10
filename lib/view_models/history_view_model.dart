import 'package:flutter/foundation.dart';
import '../services/database_service.dart';

class HistoryViewModel extends ChangeNotifier {
  final DatabaseService _databaseService = DatabaseService();

  List<Map<String, dynamic>> _sales = [];
  List<Map<String, dynamic>> get sales => _sales;

  List<Map<String, dynamic>> _purchases = [];
  List<Map<String, dynamic>> get purchases => _purchases;

  Future<void> fetchSales() async {
    _sales = await _databaseService.getSaleHistory();
    notifyListeners();
  }

  Future<void> fetchPurchases() async {
    _purchases = await _databaseService.getPurchaseHistory();
    notifyListeners();
  }

  Future<void> deleteSale(String date) async {
    await _databaseService.softDeleteSale(date);
    await fetchSales();
  }

  Future<void> deletePurchase(int id) async {
    await _databaseService.softDeletePurchase(id);
    await fetchPurchases();
  }

  Future<List<Map<String, dynamic>>> getSaleDetails(String date) {
    return _databaseService.getSaleDetails(date);
  }
}
