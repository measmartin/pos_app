import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/journal_entry.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  static Database? _database;

  factory DatabaseService() {
    return _instance;
  }

  DatabaseService._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'pos_app.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE products(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT,
        barcode TEXT,
        costPrice REAL,
        sellingPrice REAL,
        stockQuantity INTEGER,
        unit TEXT
      )
    ''');
    
    await db.execute('''
      CREATE TABLE journal_entries(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date TEXT,
        type TEXT,
        description TEXT,
        amount REAL
      )
    ''');
  }

  // Journal Methods
  Future<void> insertJournalEntry(JournalEntry entry) async {
    final db = await database;
    await db.insert('journal_entries', entry.toMap());
  }

  Future<List<JournalEntry>> getJournalEntries() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('journal_entries', orderBy: 'date DESC');
    return List.generate(maps.length, (i) => JournalEntry.fromMap(maps[i]));
  }
}
