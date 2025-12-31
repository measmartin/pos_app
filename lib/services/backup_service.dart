import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import 'package:sqflite/sqflite.dart';
import 'database_service.dart';

class BackupService {
  final DatabaseService _databaseService = DatabaseService();

  /// Export all database tables to JSON format
  Future<File> exportToJson() async {
    final db = await _databaseService.database;
    
    // Get all tables
    final tables = await _getTables(db);
    
    // Export data from each table
    final Map<String, List<Map<String, dynamic>>> backup = {};
    
    for (final table in tables) {
      backup[table] = await db.query(table);
    }
    
    // Add metadata
    final backupData = {
      'version': '1.0',
      'exported_at': DateTime.now().toIso8601String(),
      'database_version': await db.getVersion(),
      'data': backup,
    };
    
    // Convert to JSON
    final jsonString = const JsonEncoder.withIndent('  ').convert(backupData);
    
    // Save to file
    final directory = await getApplicationDocumentsDirectory();
    final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final fileName = 'pos_backup_$timestamp.json';
    final file = File('${directory.path}/$fileName');
    
    await file.writeAsString(jsonString);
    return file;
  }

  /// Import database from JSON backup file
  Future<bool> importFromJson(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        throw Exception('Backup file not found');
      }
      
      // Read and parse JSON
      final jsonString = await file.readAsString();
      final Map<String, dynamic> backupData = json.decode(jsonString);
      
      // Validate backup format
      if (!backupData.containsKey('data')) {
        throw Exception('Invalid backup file format');
      }
      
      final db = await _databaseService.database;
      final Map<String, dynamic> data = backupData['data'];
      
      // Import data in transaction
      await db.transaction((txn) async {
        // Clear existing data (except settings)
        final tables = await _getTables(db);
        for (final table in tables) {
          if (table != 'settings') {
            await txn.delete(table);
          }
        }
        
        // Insert backup data
        for (final entry in data.entries) {
          final tableName = entry.key;
          final List<dynamic> rows = entry.value;
          
          for (final row in rows) {
            // Skip settings if it exists in backup (to preserve current settings)
            if (tableName == 'settings') continue;
            
            await txn.insert(
              tableName,
              Map<String, dynamic>.from(row),
              conflictAlgorithm: ConflictAlgorithm.replace,
            );
          }
        }
      });
      
      return true;
    } catch (e) {
      throw Exception('Failed to import backup: $e');
    }
  }

  /// Export specific table to CSV format
  Future<File> exportTableToCsv(String tableName) async {
    final db = await _databaseService.database;
    
    // Get table data
    final data = await db.query(tableName);
    
    if (data.isEmpty) {
      throw Exception('Table is empty');
    }
    
    // Get column names
    final columns = data.first.keys.toList();
    
    // Build CSV content
    final csvBuffer = StringBuffer();
    
    // Add header row
    csvBuffer.writeln(columns.join(','));
    
    // Add data rows
    for (final row in data) {
      final values = columns.map((col) {
        final value = row[col];
        if (value == null) return '';
        // Escape commas and quotes
        final valueStr = value.toString();
        if (valueStr.contains(',') || valueStr.contains('"') || valueStr.contains('\n')) {
          return '"${valueStr.replaceAll('"', '""')}"';
        }
        return valueStr;
      }).join(',');
      csvBuffer.writeln(values);
    }
    
    // Save to file
    final directory = await getApplicationDocumentsDirectory();
    final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final fileName = '${tableName}_export_$timestamp.csv';
    final file = File('${directory.path}/$fileName');
    
    await file.writeAsString(csvBuffer.toString());
    return file;
  }

  /// Get list of all database tables
  Future<List<String>> _getTables(Database db) async {
    final tables = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%' AND name NOT LIKE 'android_%'",
    );
    return tables.map((t) => t['name'] as String).toList();
  }

  /// Get list of available backup files
  Future<List<FileSystemEntity>> getBackupFiles() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final files = directory.listSync()
        .where((file) => file.path.contains('pos_backup_') && file.path.endsWith('.json'))
        .toList();
      
      // Sort by modification date (newest first)
      files.sort((a, b) {
        final aStat = a.statSync();
        final bStat = b.statSync();
        return bStat.modified.compareTo(aStat.modified);
      });
      
      return files;
    } catch (e) {
      return [];
    }
  }

  /// Delete a backup file
  Future<bool> deleteBackupFile(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  /// Get backup file size in KB
  Future<double> getFileSize(String filePath) async {
    try {
      final file = File(filePath);
      final bytes = await file.length();
      return bytes / 1024; // Convert to KB
    } catch (e) {
      return 0;
    }
  }
}
