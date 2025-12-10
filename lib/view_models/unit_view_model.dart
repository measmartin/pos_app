import 'package:flutter/foundation.dart';
import '../models/unit_definition.dart';
import '../services/database_service.dart';

class UnitViewModel extends ChangeNotifier {
  List<UnitDefinition> _unitDefinitions = [];
  List<UnitDefinition> get unitDefinitions => _unitDefinitions;

  final DatabaseService _databaseService = DatabaseService();

  Future<void> fetchUnitDefinitions() async {
    final db = await _databaseService.database;
    final List<Map<String, dynamic>> maps = await db.query('unit_definitions');
    _unitDefinitions = List.generate(maps.length, (i) => UnitDefinition.fromMap(maps[i]));
    notifyListeners();
  }

  Future<void> addUnitDefinition(UnitDefinition unit) async {
    final db = await _databaseService.database;
    await db.insert('unit_definitions', unit.toMap());
    await fetchUnitDefinitions();
  }

  Future<void> deleteUnitDefinition(int id) async {
    final db = await _databaseService.database;
    await db.delete('unit_definitions', where: 'id = ?', whereArgs: [id]);
    await fetchUnitDefinitions();
  }

  List<String> _baseUnits = [];
  List<String> get baseUnits => _baseUnits;

  Future<void> fetchBaseUnits() async {
    _baseUnits = await _databaseService.getUniqueBaseUnits();
    notifyListeners();
  }
}
