import 'dart:io';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('barbershop.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, filePath);
    final db = await openDatabase(path, version: 1, onCreate: _createDB);
    // MIGRASI: Tambah kolom photo jika belum ada
    await db.execute('''
      ALTER TABLE users ADD COLUMN photo TEXT
    ''').catchError((e) {});
    return db;
  }

  Future _createDB(Database db, int version) async {
    // Outlets table
    await db.execute('''
      CREATE TABLE outlets (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        address TEXT,
        phone TEXT
      )
    ''');

    // Users table
    await db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        username TEXT NOT NULL UNIQUE,
        password TEXT NOT NULL,
        full_name TEXT,
        email TEXT,
        role TEXT NOT NULL DEFAULT 'admin',
        outlet_id INTEGER,
        is_active INTEGER NOT NULL DEFAULT 1,
        FOREIGN KEY (outlet_id) REFERENCES outlets(id)
      )
    ''');

    // Customers table
    await db.execute('''
      CREATE TABLE customers (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        phone TEXT,
        birth_date TEXT,
        notes TEXT,
        points INTEGER NOT NULL DEFAULT 0,
        referral_code TEXT UNIQUE,
        referred_by TEXT
      )
    ''');

    // Services table
    await db.execute('''
      CREATE TABLE services (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL UNIQUE,
        description TEXT,
        price INTEGER NOT NULL,
        duration_minutes INTEGER NOT NULL DEFAULT 30,
        is_active INTEGER NOT NULL DEFAULT 1
      )
    ''');

    // Products table
    await db.execute('''
      CREATE TABLE products (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL UNIQUE,
        description TEXT,
        price INTEGER NOT NULL,
        stock INTEGER NOT NULL DEFAULT 0,
        unit TEXT NOT NULL DEFAULT 'pcs',
        is_active INTEGER NOT NULL DEFAULT 1
      )
    ''');

    // Barbers table
    await db.execute('''
      CREATE TABLE barbers (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        photo TEXT,
        bio TEXT,
        is_active INTEGER NOT NULL DEFAULT 1
      )
    ''');

    // Promos table
    await db.execute('''
      CREATE TABLE promos (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        type TEXT NOT NULL CHECK(type IN ('percentage', 'fixed')),
        value INTEGER NOT NULL,
        start_date TEXT,
        end_date TEXT,
        min_total INTEGER,
        is_active INTEGER DEFAULT 1
      )
    ''');

    // Bookings table
    await db.execute('''
      CREATE TABLE bookings (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        customer_id INTEGER NOT NULL,
        barber_id INTEGER NOT NULL,
        service_id INTEGER NOT NULL,
        outlet_id INTEGER,
        scheduled_at TEXT NOT NULL,
        status TEXT NOT NULL DEFAULT 'pending',
        notes TEXT,
        FOREIGN KEY (customer_id) REFERENCES customers(id),
        FOREIGN KEY (barber_id) REFERENCES barbers(id),
        FOREIGN KEY (service_id) REFERENCES services(id),
        FOREIGN KEY (outlet_id) REFERENCES outlets(id)
      )
    ''');

    // Transactions table
    await db.execute('''
      CREATE TABLE transactions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date TEXT NOT NULL,
        customer_id INTEGER,
        user_id INTEGER,
        outlet_id INTEGER,
        total INTEGER NOT NULL,
        payment_method TEXT DEFAULT 'cash',
        promo_id INTEGER,
        notes TEXT,
        FOREIGN KEY (customer_id) REFERENCES customers(id),
        FOREIGN KEY (user_id) REFERENCES users(id),
        FOREIGN KEY (outlet_id) REFERENCES outlets(id),
        FOREIGN KEY (promo_id) REFERENCES promos(id)
      )
    ''');

    // Transaction details table
    await db.execute('''
      CREATE TABLE transaction_details (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        transaction_id INTEGER NOT NULL,
        item_type TEXT NOT NULL CHECK(item_type IN ('service', 'product')),
        item_id INTEGER NOT NULL,
        quantity INTEGER NOT NULL,
        price INTEGER NOT NULL,
        subtotal INTEGER NOT NULL,
        FOREIGN KEY (transaction_id) REFERENCES transactions(id)
      )
    ''');

    // Promo applies to table
    await db.execute('''
      CREATE TABLE promo_applies_to (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        promo_id INTEGER,
        applies_to TEXT NOT NULL CHECK(applies_to IN ('service', 'product')),
        item_id INTEGER,
        FOREIGN KEY (promo_id) REFERENCES promos(id)
      )
    ''');

    // Point history table
    await db.execute('''
      CREATE TABLE point_history (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        customer_id INTEGER,
        transaction_id INTEGER,
        points_earned INTEGER DEFAULT 0,
        points_used INTEGER DEFAULT 0,
        date TEXT NOT NULL,
        FOREIGN KEY (customer_id) REFERENCES customers(id),
        FOREIGN KEY (transaction_id) REFERENCES transactions(id)
      )
    ''');

    // Referrals table
    await db.execute('''
      CREATE TABLE referrals (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        referrer_id INTEGER,
        referred_id INTEGER,
        date TEXT NOT NULL,
        reward_given INTEGER DEFAULT 0,
        FOREIGN KEY (referrer_id) REFERENCES customers(id),
        FOREIGN KEY (referred_id) REFERENCES customers(id)
      )
    ''');

    // Memberships table
    await db.execute('''
      CREATE TABLE memberships (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        customer_id INTEGER,
        tier TEXT NOT NULL,
        price INTEGER,
        start_date TEXT,
        end_date TEXT,
        is_active INTEGER DEFAULT 1,
        FOREIGN KEY (customer_id) REFERENCES customers(id)
      )
    ''');

    // Message logs table
    await db.execute('''
      CREATE TABLE message_logs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        customer_id INTEGER,
        type TEXT NOT NULL,
        message TEXT,
        status TEXT DEFAULT 'pending',
        sent_at TEXT,
        FOREIGN KEY (customer_id) REFERENCES customers(id)
      )
    ''');

    // Logs table
    await db.execute('''
      CREATE TABLE logs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER,
        action TEXT NOT NULL,
        timestamp TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (user_id) REFERENCES users(id)
      )
    ''');

    // Finance Categories table
    await db.execute('''
      CREATE TABLE finance_categories (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        type TEXT NOT NULL CHECK(type IN ('income', 'expense')),
        description TEXT,
        is_active INTEGER NOT NULL DEFAULT 1
      )
    ''');

    // Finance Transactions table
    await db.execute('''
      CREATE TABLE finance_transactions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date TEXT NOT NULL,
        category_id INTEGER NOT NULL,
        amount INTEGER NOT NULL,
        description TEXT,
        payment_method TEXT DEFAULT 'cash',
        reference_id TEXT,
        user_id INTEGER,
        outlet_id INTEGER,
        FOREIGN KEY (category_id) REFERENCES finance_categories(id),
        FOREIGN KEY (user_id) REFERENCES users(id),
        FOREIGN KEY (outlet_id) REFERENCES outlets(id)
      )
    ''');

    // Token trial table
    await db.execute('''
      CREATE TABLE token_trial (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        token TEXT NOT NULL,
        trial INTEGER NOT NULL DEFAULT 0,
        start_at TEXT
      )
    ''');

    // Insert default finance categories
    await db.insert('finance_categories', {
      'name': 'Penjualan Layanan',
      'type': 'income',
      'description': 'Pendapatan dari penjualan layanan',
      'is_active': 1,
    });

    await db.insert('finance_categories', {
      'name': 'Penjualan Produk',
      'type': 'income',
      'description': 'Pendapatan dari penjualan produk',
      'is_active': 1,
    });

    await db.insert('finance_categories', {
      'name': 'Gaji Karyawan',
      'type': 'expense',
      'description': 'Pengeluaran untuk gaji karyawan',
      'is_active': 1,
    });

    await db.insert('finance_categories', {
      'name': 'Sewa Tempat',
      'type': 'expense',
      'description': 'Pengeluaran untuk sewa tempat',
      'is_active': 1,
    });

    await db.insert('finance_categories', {
      'name': 'Pembelian Stok',
      'type': 'expense',
      'description': 'Pengeluaran untuk pembelian stok produk',
      'is_active': 1,
    });

    await db.insert('finance_categories', {
      'name': 'Utilitas',
      'type': 'expense',
      'description': 'Pengeluaran untuk listrik, air, internet, dll',
      'is_active': 1,
    });
  }

  // Generic query methods
  Future<int> insert(String table, Map<String, dynamic> row) async {
    Database db = await instance.database;
    return await db.insert(table, row);
  }

  Future<List<Map<String, dynamic>>> queryAllRows(String table) async {
    Database db = await instance.database;
    return await db.query(table);
  }

  Future<List<Map<String, dynamic>>> queryWhere(
    String table,
    String where,
    List<dynamic> whereArgs,
  ) async {
    Database db = await instance.database;
    return await db.query(table, where: where, whereArgs: whereArgs);
  }

  Future<int> update(
    String table,
    Map<String, dynamic> row,
    String where,
    List<dynamic> whereArgs,
  ) async {
    Database db = await instance.database;
    return await db.update(table, row, where: where, whereArgs: whereArgs);
  }

  Future<int> delete(
    String table,
    String where,
    List<dynamic> whereArgs,
  ) async {
    Database db = await instance.database;
    return await db.delete(table, where: where, whereArgs: whereArgs);
  }

  Future<void> close() async {
    if (_database != null) {
      await _database!.close();
    }
  }
}
