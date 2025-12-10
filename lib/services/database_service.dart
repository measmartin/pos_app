import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/journal_entry.dart';
import '../models/product.dart';

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
      version: 6,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
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
        unit TEXT,
        image_path TEXT
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

    await _createSaleItemsTable(db);
    await _createProductUnitsTable(db);
    await _createPurchaseItemsTable(db);
    await _createUnitDefinitionsTable(db);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await _createSaleItemsTable(db);
    }
    if (oldVersion < 3) {
      await db.execute('ALTER TABLE products ADD COLUMN image_path TEXT');
    }
    if (oldVersion < 4) {
      await _createProductUnitsTable(db);
      await _createPurchaseItemsTable(db);
    }
    if (oldVersion < 5) {
      await _createUnitDefinitionsTable(db);
    }
    if (oldVersion < 6) {
      await db.execute('ALTER TABLE sale_items ADD COLUMN is_deleted INTEGER DEFAULT 0');
      await db.execute('ALTER TABLE purchase_items ADD COLUMN is_deleted INTEGER DEFAULT 0');
    }
  }

  Future<void> _createUnitDefinitionsTable(Database db) async {
    await db.execute('''
      CREATE TABLE unit_definitions(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT,
        base_unit TEXT,
        factor REAL
      )
    ''');
  }

  Future<void> _createProductUnitsTable(Database db) async {
    await db.execute('''
      CREATE TABLE product_units(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        product_id INTEGER,
        name TEXT,
        factor REAL,
        selling_price REAL,
        FOREIGN KEY(product_id) REFERENCES products(id) ON DELETE CASCADE
      )
    ''');
  }

  Future<void> _createPurchaseItemsTable(Database db) async {
    await db.execute('''
      CREATE TABLE purchase_items(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        product_id INTEGER,
        quantity INTEGER,
        cost_price REAL,
        date TEXT,
        is_deleted INTEGER DEFAULT 0,
        FOREIGN KEY(product_id) REFERENCES products(id)
      )
    ''');
  }

  Future<void> _createSaleItemsTable(Database db) async {
    await db.execute('''
      CREATE TABLE sale_items(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        product_id INTEGER,
        quantity INTEGER,
        date TEXT,
        selling_price REAL,
        is_deleted INTEGER DEFAULT 0,
        FOREIGN KEY(product_id) REFERENCES products(id)
      )
    ''');
  }

  // History Methods

  // Get grouped sales by date
  Future<List<Map<String, dynamic>>> getSaleHistory() async {
    final db = await database;
    // We group by date to simulate a "transaction"
    return await db.rawQuery('''
      SELECT 
        s.date,
        SUM(s.selling_price * s.quantity) as total_amount,
        COUNT(s.id) as item_count
      FROM sale_items s
      WHERE s.is_deleted = 0
      GROUP BY s.date
      ORDER BY s.date DESC
    ''');
  }

  // Get details for a specific sale date
  Future<List<Map<String, dynamic>>> getSaleDetails(String date) async {
    final db = await database;
    return await db.rawQuery('''
      SELECT s.*, p.name as product_name, p.unit as base_unit
      FROM sale_items s
      JOIN products p ON s.product_id = p.id
      WHERE s.date = ? AND s.is_deleted = 0
    ''', [date]);
  }

  Future<List<Map<String, dynamic>>> getPurchaseHistory() async {
    final db = await database;
    return await db.rawQuery('''
      SELECT 
        p_item.*,
        p.name as product_name,
        p.unit as base_unit
      FROM purchase_items p_item
      JOIN products p ON p_item.product_id = p.id
      WHERE p_item.is_deleted = 0
      ORDER BY p_item.date DESC
    ''');
  }

  Future<void> softDeleteSale(String date) async {
    final db = await database;
    await db.transaction((txn) async {
      // 1. Get items to restore stock
      final items = await txn.query(
        'sale_items', 
        where: 'date = ? AND is_deleted = 0', 
        whereArgs: [date]
      );

      double totalRefund = 0;

      for (var item in items) {
        int qty = item['quantity'] as int;
        int productId = item['product_id'] as int;
        double price = item['selling_price'] as double;
        totalRefund += (price * qty);

        // Restore stock
        await txn.rawUpdate(
          'UPDATE products SET stockQuantity = stockQuantity + ? WHERE id = ?',
          [qty, productId]
        );
      }

      // 2. Mark as deleted
      await txn.update(
        'sale_items', 
        {'is_deleted': 1}, 
        where: 'date = ?', 
        whereArgs: [date]
      );

      // 3. Journal Reversal
      await txn.insert('journal_entries', JournalEntry(
        date: DateTime.now(),
        type: 'DEBIT', // Refund reduces Sales (which is Credit) -> Debit? 
                       // Actually Sales is Income (Credit). Reducing income is Debit.
                       // Cash is Asset (Debit). Reducing cash is Credit.
                       // So: Credit Cash, Debit Sales (Revenue).
        description: 'Void Sale ($date)',
        amount: -totalRefund, // Store as negative or handle type? 
                              // Current logic: Credit = Income/Sales. Debit = Cash.
                              // Wait, existing logic: 
                              // Debit Cash (Asset) +Amount
                              // Credit Sales (Income) +Amount
                              // To reverse:
                              // Credit Cash -Amount (or just Credit with negative?)
                              // Let's explicitly log a "Void" entry.
                              // We will just add a 'VOID' type or negative amount. 
                              // Let's stick to: Credit Cash (Money out), Debit Sales (Revenue reduction).
                              // But my journal is simple: Type, Desc, Amount.
                              // I'll just put a negative amount entry.
      ).toMap());
      
      // Better:
      // Credit Cash (Money Returned)
       await txn.insert('journal_entries', JournalEntry(
        date: DateTime.now(),
        type: 'CREDIT', 
        description: 'Refunding Cash (Void Sale)',
        amount: -totalRefund, // Negative credit?? 
        // Let's follow the app's pattern:
        // Cash Sale: DEBIT Cash (+), CREDIT Sales (+).
        // Void: CREDIT Cash (-), DEBIT Sales (-).
        // I will just add an entry that clearly indicates reversal.
        // Actually, if I use "CREDIT" with positive amount, it usually means Income. 
        // If I use "DEBIT" with positive amount, it means Cash In.
        // To show Cash Out (Refund), I should use CREDIT with negative? Or DEBIT with negative?
        // Let's assume DEBIT = Cash In, CREDIT = Cash Out/Sales.
        // Actually, in accounting: 
        // Asset (Cash): Debit +, Credit -
        // Income (Sales): Credit +, Debit -
        // Current App Logic (CartViewModel):
        // 1. Debit Cash (+Total)
        // 2. Credit Sales (+Total)
        // So for Void:
        // 1. Credit Cash (+Total) -> Means money leaving? No, wait.
        // If "Type" column is just a tag, let's look at `JournalViewModel`: It doesn't sum based on type, it just lists.
        // `getSalesSum` sums `amount` where `type='CREDIT'`. 
        // So to reduce sales, I should insert a 'CREDIT' entry with NEGATIVE amount.
      ).toMap());
    });
  }

  Future<void> softDeletePurchase(int id) async {
    final db = await database;
    await db.transaction((txn) async {
      final items = await txn.query('purchase_items', where: 'id = ?', whereArgs: [id]);
      if (items.isEmpty) return;
      
      final item = items.first;
      int qty = item['quantity'] as int;
      int productId = item['product_id'] as int;
      double cost = item['cost_price'] as double;
      double total = qty * cost;

      // Restore stock (Reduce it, because we are undoing a purchase)
      await txn.rawUpdate(
        'UPDATE products SET stockQuantity = stockQuantity - ? WHERE id = ?',
        [qty, productId]
      );

      // Mark deleted
      await txn.update('purchase_items', {'is_deleted': 1}, where: 'id = ?', whereArgs: [id]);

      // Journal: Reverse Purchase
      // Purchase was: Credit Cash (Money Out), Debit Inventory (Asset In) - wait, my purchase logic was: Credit Cash.
      // So to reverse: Debit Cash (Money Back).
      // But `getSalesSum` only looks at CREDIT.
      // If we want to track "Purchases", we haven't implemented `getPurchaseSum`.
      // But we should record the cash flow.
      // We will add a DEBIT entry (Cash In / Refund from Supplier)
      await txn.insert('journal_entries', JournalEntry(
        date: DateTime.now(),
        type: 'DEBIT',
        description: 'Void Purchase (Stock Return)',
        amount: total, 
      ).toMap());
    });
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

  // Dashboard / Analytics Methods
  Future<List<Product>> getTrendingProducts() async {
    final db = await database;
    // Join sale_items with products to get product details, sum quantity
    final List<Map<String, dynamic>> result = await db.rawQuery('''
      SELECT p.*, SUM(s.quantity) as total_sold
      FROM products p
      JOIN sale_items s ON p.id = s.product_id
      WHERE s.is_deleted = 0
      GROUP BY p.id
      ORDER BY total_sold DESC
      LIMIT 5
    ''');
    
    return List.generate(result.length, (i) => Product.fromMap(result[i]));
  }

  Future<double> getSalesSum(DateTime start, DateTime end) async {
    final db = await database;
    final List<Map<String, dynamic>> result = await db.rawQuery('''
      SELECT SUM(quantity * selling_price) as total
      FROM sale_items
      WHERE is_deleted = 0 
      AND date >= ? AND date <= ?
    ''', [start.toIso8601String(), end.toIso8601String()]);
    
    if (result.isEmpty || result.first['total'] == null) return 0.0;
    return result.first['total'] as double;
  }

  Future<double> getPurchaseSum(DateTime start, DateTime end) async {
    final db = await database;
    final List<Map<String, dynamic>> result = await db.rawQuery('''
      SELECT SUM(quantity * cost_price) as total
      FROM purchase_items
      WHERE is_deleted = 0 
      AND date >= ? AND date <= ?
    ''', [start.toIso8601String(), end.toIso8601String()]);
    
    if (result.isEmpty || result.first['total'] == null) return 0.0;
    return result.first['total'] as double;
  }

  Future<List<String>> getUniqueBaseUnits() async {
    final db = await database;
    final List<Map<String, dynamic>> productUnits = await db.rawQuery('SELECT DISTINCT unit FROM products');
    final List<Map<String, dynamic>> definedBaseUnits = await db.rawQuery('SELECT DISTINCT base_unit FROM unit_definitions');
    
    final Set<String> units = {};
    for (var map in productUnits) {
      if (map['unit'] != null && (map['unit'] as String).isNotEmpty) {
        units.add(map['unit'] as String);
      }
    }
    for (var map in definedBaseUnits) {
      if (map['base_unit'] != null && (map['base_unit'] as String).isNotEmpty) {
        units.add(map['base_unit'] as String);
      }
    }
    
    return units.toList()..sort();
  }
}