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
      version: 14,
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
    await _createAccountingTables(db);
    await _seedChartOfAccounts(db);
    await _createStockAdjustmentsTable(db);
    await _createCustomersTable(db);
    await _createTransactionsTable(db);
    await _createReturnsTable(db);
    await _createHeldTransactionsTable(db);
    await _createSettingsTable(db);
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
    if (oldVersion < 7) {
      await _createAccountingTables(db);
      await _seedChartOfAccounts(db);
    }
    if (oldVersion < 8) {
      await _createStockAdjustmentsTable(db);
    }
    if (oldVersion < 9) {
      await _createCustomersTable(db);
    }
    if (oldVersion < 10) {
      await _createTransactionsTable(db);
    }
    if (oldVersion < 11) {
      await _createReturnsTable(db);
    }
    if (oldVersion < 12) {
      await _createHeldTransactionsTable(db);
    }
    if (oldVersion < 13) {
      await _addPerformanceIndexes(db);
    }
    if (oldVersion < 14) {
      await _createSettingsTable(db);
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

  Future<void> _createAccountingTables(Database db) async {
    // Accounts table - Chart of Accounts
    await db.execute('''
      CREATE TABLE accounts(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        code TEXT UNIQUE NOT NULL,
        name TEXT NOT NULL,
        type TEXT NOT NULL,
        parent_id INTEGER,
        balance REAL DEFAULT 0,
        is_active INTEGER DEFAULT 1,
        FOREIGN KEY(parent_id) REFERENCES accounts(id)
      )
    ''');

    // Journal Headers - Main journal entry
    await db.execute('''
      CREATE TABLE journal_headers(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date TEXT NOT NULL,
        description TEXT NOT NULL,
        reference_type TEXT,
        reference_id INTEGER,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        is_voided INTEGER DEFAULT 0
      )
    ''');

    // Journal Lines - Double-entry lines
    await db.execute('''
      CREATE TABLE journal_lines(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        header_id INTEGER NOT NULL,
        account_id INTEGER NOT NULL,
        debit REAL DEFAULT 0,
        credit REAL DEFAULT 0,
        description TEXT,
        FOREIGN KEY(header_id) REFERENCES journal_headers(id) ON DELETE CASCADE,
        FOREIGN KEY(account_id) REFERENCES accounts(id),
        CHECK (debit >= 0 AND credit >= 0),
        CHECK (NOT (debit > 0 AND credit > 0))
      )
    ''');

    // Create indexes for better query performance
    await db.execute('CREATE INDEX idx_journal_lines_header ON journal_lines(header_id)');
    await db.execute('CREATE INDEX idx_journal_lines_account ON journal_lines(account_id)');
    await db.execute('CREATE INDEX idx_journal_headers_date ON journal_headers(date)');
  }

  Future<void> _seedChartOfAccounts(Database db) async {
    // Seed default chart of accounts
    final accounts = [
      // Assets (1000-1999)
      {'code': '1000', 'name': 'Cash on Hand - USD', 'type': 'ASSET'},
      {'code': '1100', 'name': 'Inventory - USD', 'type': 'ASSET'},
      {'code': '1200', 'name': 'Accounts Receivable', 'type': 'ASSET'},
      {'code': '1300', 'name': 'Equipment', 'type': 'ASSET'},
      
      // Liabilities (2000-2999)
      {'code': '2000', 'name': 'Accounts Payable', 'type': 'LIABILITY'},
      {'code': '2100', 'name': 'Sales Tax Payable', 'type': 'LIABILITY'},
      
      // Equity (3000-3999)
      {'code': '3000', 'name': 'Owner Equity', 'type': 'EQUITY'},
      {'code': '3100', 'name': 'Retained Earnings', 'type': 'EQUITY'},
      
      // Revenue (4000-4999)
      {'code': '4000', 'name': 'Sales Revenue - USD', 'type': 'REVENUE'},
      {'code': '4100', 'name': 'Other Income', 'type': 'REVENUE'},
      
      // Expenses (5000-5999)
      {'code': '5000', 'name': 'Cost of Goods Sold', 'type': 'EXPENSE'},
      {'code': '5100', 'name': 'Operating Expenses', 'type': 'EXPENSE'},
      {'code': '5200', 'name': 'Utilities', 'type': 'EXPENSE'},
      {'code': '5300', 'name': 'Rent', 'type': 'EXPENSE'},
    ];

    for (var account in accounts) {
      await db.insert('accounts', account);
    }
  }

  Future<void> _createStockAdjustmentsTable(Database db) async {
    await db.execute('''
      CREATE TABLE stock_adjustments(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        product_id INTEGER NOT NULL,
        quantity_change INTEGER NOT NULL,
        old_quantity INTEGER NOT NULL,
        new_quantity INTEGER NOT NULL,
        type TEXT NOT NULL,
        reason TEXT NOT NULL,
        notes TEXT,
        date TEXT NOT NULL,
        user_id TEXT,
        FOREIGN KEY(product_id) REFERENCES products(id)
      )
    ''');
    
    // Create index for faster queries
    await db.execute('CREATE INDEX idx_stock_adjustments_product ON stock_adjustments(product_id)');
    await db.execute('CREATE INDEX idx_stock_adjustments_date ON stock_adjustments(date)');
  }

  Future<void> _createCustomersTable(Database db) async {
    await db.execute('''
      CREATE TABLE customers(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        phone TEXT,
        email TEXT,
        address TEXT,
        loyalty_points REAL DEFAULT 0,
        total_spent REAL DEFAULT 0,
        created_at TEXT NOT NULL,
        last_purchase_date TEXT,
        notes TEXT,
        is_active INTEGER DEFAULT 1
      )
    ''');
    
    // Create indexes for faster queries
    await db.execute('CREATE INDEX idx_customers_name ON customers(name)');
    await db.execute('CREATE INDEX idx_customers_phone ON customers(phone)');
    await db.execute('CREATE INDEX idx_customers_is_active ON customers(is_active)');
    
    // Add customer_id to sale_items table
    await db.execute('ALTER TABLE sale_items ADD COLUMN customer_id INTEGER');
    await db.execute('CREATE INDEX idx_sale_items_customer ON sale_items(customer_id)');
  }

  Future<void> _createTransactionsTable(Database db) async {
    // Transactions table - groups sale_items into transactions
    await db.execute('''
      CREATE TABLE transactions(
        id TEXT PRIMARY KEY,
        customer_id INTEGER,
        total_amount REAL NOT NULL,
        discount_amount REAL DEFAULT 0,
        final_amount REAL NOT NULL,
        paid_amount REAL NOT NULL,
        change_amount REAL DEFAULT 0,
        status TEXT NOT NULL,
        created_at TEXT NOT NULL,
        completed_at TEXT,
        notes TEXT,
        FOREIGN KEY(customer_id) REFERENCES customers(id)
      )
    ''');
    
    // Discounts table - stores discount information
    await db.execute('''
      CREATE TABLE discounts(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        transaction_id TEXT,
        type TEXT NOT NULL,
        scope TEXT NOT NULL,
        value REAL NOT NULL,
        reason TEXT,
        item_key TEXT,
        applied_at TEXT NOT NULL,
        FOREIGN KEY(transaction_id) REFERENCES transactions(id)
      )
    ''');
    
    // Payments table - stores payment method information
    await db.execute('''
      CREATE TABLE payments(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        transaction_id TEXT NOT NULL,
        method TEXT NOT NULL,
        amount REAL NOT NULL,
        reference TEXT,
        notes TEXT,
        paid_at TEXT NOT NULL,
        FOREIGN KEY(transaction_id) REFERENCES transactions(id)
      )
    ''');
    
    // Add transaction_id to sale_items table
    await db.execute('ALTER TABLE sale_items ADD COLUMN transaction_id TEXT');
    await db.execute('ALTER TABLE sale_items ADD COLUMN discount_amount REAL DEFAULT 0');
    await db.execute('ALTER TABLE sale_items ADD COLUMN unit_name TEXT');
    
    // Create indexes
    await db.execute('CREATE INDEX idx_transactions_customer ON transactions(customer_id)');
    await db.execute('CREATE INDEX idx_transactions_status ON transactions(status)');
    await db.execute('CREATE INDEX idx_transactions_created_at ON transactions(created_at)');
    await db.execute('CREATE INDEX idx_discounts_transaction ON discounts(transaction_id)');
    await db.execute('CREATE INDEX idx_payments_transaction ON payments(transaction_id)');
    await db.execute('CREATE INDEX idx_sale_items_transaction ON sale_items(transaction_id)');
  }

  Future<void> _createReturnsTable(Database db) async {
    // Returns table - tracks product returns/refunds
    await db.execute('''
      CREATE TABLE returns(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        sale_item_id INTEGER NOT NULL,
        product_id INTEGER NOT NULL,
        product_name TEXT NOT NULL,
        quantity_returned INTEGER NOT NULL,
        refund_amount REAL NOT NULL,
        reason TEXT NOT NULL,
        notes TEXT,
        return_date TEXT NOT NULL,
        transaction_id TEXT,
        FOREIGN KEY(sale_item_id) REFERENCES sale_items(id),
        FOREIGN KEY(product_id) REFERENCES products(id)
      )
    ''');
    
    // Create indexes
    await db.execute('CREATE INDEX idx_returns_sale_item ON returns(sale_item_id)');
    await db.execute('CREATE INDEX idx_returns_product ON returns(product_id)');
    await db.execute('CREATE INDEX idx_returns_date ON returns(return_date)');
    await db.execute('CREATE INDEX idx_returns_transaction ON returns(transaction_id)');
    
    // Add returned_quantity to sale_items to track partial returns
    await db.execute('ALTER TABLE sale_items ADD COLUMN returned_quantity INTEGER DEFAULT 0');
  }

  Future<void> _createHeldTransactionsTable(Database db) async {
    // Held transactions table - stores parked/held transactions
    await db.execute('''
      CREATE TABLE held_transactions(
        id TEXT PRIMARY KEY,
        cart_data TEXT NOT NULL,
        customer_id INTEGER,
        created_at TEXT NOT NULL,
        notes TEXT
      )
    ''');
    
    // Create indexes
    await db.execute('CREATE INDEX idx_held_transactions_created ON held_transactions(created_at)');
    await db.execute('CREATE INDEX idx_held_transactions_customer ON held_transactions(customer_id)');
  }

  Future<void> _createSettingsTable(Database db) async {
    // Settings table - stores app configuration
    await db.execute('''
      CREATE TABLE settings(
        id INTEGER PRIMARY KEY CHECK (id = 1),
        business_name TEXT NOT NULL DEFAULT 'My Shop',
        business_address TEXT,
        business_phone TEXT,
        business_email TEXT,
        tax_id TEXT,
        tax_rate REAL DEFAULT 0.0,
        currency_symbol TEXT DEFAULT '\$',
        receipt_header TEXT DEFAULT 'Thank you for your purchase!',
        receipt_footer TEXT DEFAULT 'Please come again',
        enable_loyalty_program INTEGER DEFAULT 1,
        enable_low_stock_alerts INTEGER DEFAULT 1,
        low_stock_threshold INTEGER DEFAULT 10,
        print_receipt_automatically INTEGER DEFAULT 0
      )
    ''');
    
    // Insert default settings
    await db.execute('''
      INSERT INTO settings (id, business_name, currency_symbol, receipt_header, receipt_footer)
      VALUES (1, 'My Shop', '\$', 'Thank you for your purchase!', 'Please come again')
    ''');
  }

  Future<void> _addPerformanceIndexes(Database db) async {
    // Products indexes
    await db.execute('CREATE INDEX IF NOT EXISTS idx_products_barcode ON products(barcode)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_products_name ON products(name)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_products_stock ON products(stockQuantity)');
    
    // Product units index
    await db.execute('CREATE INDEX IF NOT EXISTS idx_product_units_product ON product_units(product_id)');
    
    // Sale items composite indexes
    await db.execute('CREATE INDEX IF NOT EXISTS idx_sale_items_product_deleted ON sale_items(product_id, is_deleted)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_sale_items_date_deleted ON sale_items(date, is_deleted)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_sale_items_product_date_deleted ON sale_items(product_id, date, is_deleted)');
    
    // Purchase items indexes
    await db.execute('CREATE INDEX IF NOT EXISTS idx_purchase_items_product_deleted ON purchase_items(product_id, is_deleted)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_purchase_items_date ON purchase_items(date)');
    
    // Customers index
    await db.execute('CREATE INDEX IF NOT EXISTS idx_customers_email ON customers(email)');
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

  // Settings Methods
  Future<Map<String, dynamic>?> getSettings() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('settings', where: 'id = 1');
    
    if (maps.isEmpty) {
      // Insert default settings if not exist
      await db.execute('''
        INSERT OR IGNORE INTO settings (id, business_name, currency_symbol, receipt_header, receipt_footer)
        VALUES (1, 'My Shop', '\$', 'Thank you for your purchase!', 'Please come again')
      ''');
      return (await db.query('settings', where: 'id = 1')).firstOrNull;
    }
    
    return maps.first;
  }

  Future<void> updateSettings(Map<String, dynamic> settings) async {
    final db = await database;
    await db.update(
      'settings',
      settings,
      where: 'id = 1',
    );
  }
}