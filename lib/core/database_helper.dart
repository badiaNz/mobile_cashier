import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._internal();
  static Database? _database;

  DatabaseHelper._internal();

  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'mobile_cashier.db');

    return await openDatabase(
      path,
      version: 2,
      onCreate: _createTables,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _createTables(Database db, int version) async {
    await db.execute('''
      CREATE TABLE users (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        email TEXT UNIQUE NOT NULL,
        pin TEXT,
        role TEXT NOT NULL DEFAULT 'cashier',
        avatar_url TEXT,
        is_active INTEGER NOT NULL DEFAULT 1,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE store_settings (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        store_name TEXT NOT NULL DEFAULT 'My Store',
        address TEXT,
        phone TEXT,
        email TEXT,
        logo_path TEXT,
        currency TEXT NOT NULL DEFAULT 'IDR',
        tax_percentage REAL NOT NULL DEFAULT 0.0,
        tax_included INTEGER NOT NULL DEFAULT 0,
        receipt_footer TEXT,
        receipt_header TEXT,
        printer_type TEXT DEFAULT 'none',
        printer_ip TEXT,
        printer_port INTEGER
      )
    ''');

    await db.execute('''
      CREATE TABLE categories (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        icon TEXT,
        color TEXT,
        sort_order INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE products (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        description TEXT,
        category_id TEXT,
        barcode TEXT,
        sku TEXT,
        price REAL NOT NULL DEFAULT 0,
        cost_price REAL NOT NULL DEFAULT 0,
        stock INTEGER NOT NULL DEFAULT 0,
        min_stock INTEGER NOT NULL DEFAULT 0,
        unit TEXT NOT NULL DEFAULT 'pcs',
        image_path TEXT,
        is_active INTEGER NOT NULL DEFAULT 1,
        track_stock INTEGER NOT NULL DEFAULT 1,
        has_variants INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (category_id) REFERENCES categories(id) ON DELETE SET NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE product_variants (
        id TEXT PRIMARY KEY,
        product_id TEXT NOT NULL,
        name TEXT NOT NULL,
        price REAL NOT NULL DEFAULT 0,
        cost_price REAL NOT NULL DEFAULT 0,
        stock INTEGER NOT NULL DEFAULT 0,
        barcode TEXT,
        sku TEXT,
        FOREIGN KEY (product_id) REFERENCES products(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE customers (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        phone TEXT,
        email TEXT,
        address TEXT,
        points INTEGER NOT NULL DEFAULT 0,
        total_spending REAL NOT NULL DEFAULT 0,
        notes TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE transactions (
        id TEXT PRIMARY KEY,
        invoice_number TEXT NOT NULL UNIQUE,
        cashier_id TEXT NOT NULL,
        customer_id TEXT,
        subtotal REAL NOT NULL DEFAULT 0,
        discount_type TEXT NOT NULL DEFAULT 'none',
        discount_value REAL NOT NULL DEFAULT 0,
        discount_amount REAL NOT NULL DEFAULT 0,
        tax_percentage REAL NOT NULL DEFAULT 0,
        tax_amount REAL NOT NULL DEFAULT 0,
        rounding REAL NOT NULL DEFAULT 0,
        total REAL NOT NULL DEFAULT 0,
        payment_method TEXT NOT NULL DEFAULT 'cash',
        amount_paid REAL NOT NULL DEFAULT 0,
        change_amount REAL NOT NULL DEFAULT 0,
        status TEXT NOT NULL DEFAULT 'completed',
        notes TEXT,
        created_at TEXT NOT NULL,
        FOREIGN KEY (cashier_id) REFERENCES users(id),
        FOREIGN KEY (customer_id) REFERENCES customers(id)
      )
    ''');

    await db.execute('''
      CREATE TABLE transaction_items (
        id TEXT PRIMARY KEY,
        transaction_id TEXT NOT NULL,
        product_id TEXT NOT NULL,
        variant_id TEXT,
        product_name TEXT NOT NULL,
        product_price REAL NOT NULL,
        quantity INTEGER NOT NULL DEFAULT 1,
        discount_percentage REAL NOT NULL DEFAULT 0,
        subtotal REAL NOT NULL,
        notes TEXT,
        FOREIGN KEY (transaction_id) REFERENCES transactions(id) ON DELETE CASCADE,
        FOREIGN KEY (product_id) REFERENCES products(id)
      )
    ''');

    await db.execute('''
      CREATE TABLE discounts (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        type TEXT NOT NULL DEFAULT 'percentage',
        value REAL NOT NULL,
        min_purchase REAL NOT NULL DEFAULT 0,
        max_discount REAL,
        is_active INTEGER NOT NULL DEFAULT 1,
        start_date TEXT,
        end_date TEXT,
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE cash_drawers (
        id TEXT PRIMARY KEY,
        cashier_id TEXT NOT NULL,
        opening_amount REAL NOT NULL DEFAULT 0,
        closing_amount REAL,
        expected_amount REAL,
        difference REAL,
        status TEXT NOT NULL DEFAULT 'open',
        opened_at TEXT NOT NULL,
        closed_at TEXT,
        notes TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE stock_movements (
        id TEXT PRIMARY KEY,
        product_id TEXT NOT NULL,
        variant_id TEXT,
        type TEXT NOT NULL,
        quantity INTEGER NOT NULL,
        before_stock INTEGER NOT NULL,
        after_stock INTEGER NOT NULL,
        reason TEXT,
        reference_id TEXT,
        created_at TEXT NOT NULL,
        created_by TEXT,
        FOREIGN KEY (product_id) REFERENCES products(id)
      )
    ''');

    // Insert default data
    await _insertDefaultData(db);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Update existing products with image URLs
      final imageMap = {
        'prod_001': 'https://images.unsplash.com/photo-1603133872878-684f208fb84b?w=200&q=80',
        'prod_002': 'https://images.unsplash.com/photo-1610057099431-d73a1c9d2f2f?w=200&q=80',
        'prod_003': 'https://images.unsplash.com/photo-1556679343-c7306c1976bc?w=200&q=80',
        'prod_004': 'https://images.unsplash.com/photo-1619566636858-adf3ef46400b?w=200&q=80',
        'prod_005': 'https://images.unsplash.com/photo-1621939514649-280e2ee25f60?w=200&q=80',
      };
      for (final entry in imageMap.entries) {
        await db.update('products', {'image_path': entry.value},
            where: 'id = ?', whereArgs: [entry.key]);
      }
    }
  }

  Future<void> _insertDefaultData(Database db) async {
    final now = DateTime.now().toIso8601String();

    // Default admin user
    await db.insert('users', {
      'id': 'user_001',
      'name': 'Admin',
      'email': 'admin@kasir.com',
      'pin': '1234',
      'role': 'admin',
      'is_active': 1,
      'created_at': now,
      'updated_at': now,
    });

    // Default store settings
    await db.insert('store_settings', {
      'store_name': 'Toko Saya',
      'currency': 'IDR',
      'tax_percentage': 11.0,
      'tax_included': 0,
      'receipt_footer': 'Terima kasih atas kunjungan Anda!',
    });

    // Default categories
    final categories = [
      {'id': 'cat_001', 'name': 'Makanan', 'icon': '🍕', 'color': '#FF7675', 'sort_order': 1},
      {'id': 'cat_002', 'name': 'Minuman', 'icon': '🥤', 'color': '#74B9FF', 'sort_order': 2},
      {'id': 'cat_003', 'name': 'Snack', 'icon': '🍿', 'color': '#FDCB6E', 'sort_order': 3},
      {'id': 'cat_004', 'name': 'Lainnya', 'icon': '📦', 'color': '#A29BFE', 'sort_order': 4},
    ];

    for (final cat in categories) {
      await db.insert('categories', {...cat, 'created_at': now});
    }

    // Sample products with images from Unsplash
    final products = [
      {
        'id': 'prod_001',
        'name': 'Nasi Goreng',
        'description': 'Nasi goreng spesial dengan telur dan ayam',
        'category_id': 'cat_001',
        'price': 25000.0,
        'cost_price': 15000.0,
        'stock': 100,
        'min_stock': 10,
        'unit': 'porsi',
        'image_path': 'https://images.unsplash.com/photo-1603133872878-684f208fb84b?w=200&q=80',
        'is_active': 1,
        'track_stock': 1,
        'has_variants': 0,
      },
      {
        'id': 'prod_002',
        'name': 'Ayam Goreng',
        'description': 'Ayam goreng crispy bumbu rempah',
        'category_id': 'cat_001',
        'price': 30000.0,
        'cost_price': 18000.0,
        'stock': 50,
        'min_stock': 5,
        'unit': 'porsi',
        'image_path': 'https://images.unsplash.com/photo-1610057099431-d73a1c9d2f2f?w=200&q=80',
        'is_active': 1,
        'track_stock': 1,
        'has_variants': 0,
      },
      {
        'id': 'prod_003',
        'name': 'Es Teh Manis',
        'description': 'Teh manis dingin segar',
        'category_id': 'cat_002',
        'price': 8000.0,
        'cost_price': 3000.0,
        'stock': 200,
        'min_stock': 20,
        'unit': 'cup',
        'image_path': 'https://images.unsplash.com/photo-1556679343-c7306c1976bc?w=200&q=80',
        'is_active': 1,
        'track_stock': 1,
        'has_variants': 0,
      },
      {
        'id': 'prod_004',
        'name': 'Jus Alpukat',
        'description': 'Jus alpukat segar dengan susu',
        'category_id': 'cat_002',
        'price': 18000.0,
        'cost_price': 10000.0,
        'stock': 80,
        'min_stock': 10,
        'unit': 'cup',
        'image_path': 'https://images.unsplash.com/photo-1619566636858-adf3ef46400b?w=200&q=80',
        'is_active': 1,
        'track_stock': 1,
        'has_variants': 0,
      },
      {
        'id': 'prod_005',
        'name': 'Keripik Singkong',
        'description': 'Keripik singkong gurih renyah',
        'category_id': 'cat_003',
        'price': 12000.0,
        'cost_price': 7000.0,
        'stock': 150,
        'min_stock': 15,
        'unit': 'bungkus',
        'image_path': 'https://images.unsplash.com/photo-1621939514649-280e2ee25f60?w=200&q=80',
        'is_active': 1,
        'track_stock': 1,
        'has_variants': 0,
      },
      {
        'id': 'prod_006',
        'name': 'Mie Goreng',
        'description': 'Mie goreng spesial bumbu pedas',
        'category_id': 'cat_001',
        'price': 22000.0,
        'cost_price': 12000.0,
        'stock': 80,
        'min_stock': 10,
        'unit': 'porsi',
        'image_path': 'https://images.unsplash.com/photo-1569050467447-ce54b3bbc37d?w=200&q=80',
        'is_active': 1,
        'track_stock': 1,
        'has_variants': 0,
      },
      {
        'id': 'prod_007',
        'name': 'Kopi Hitam',
        'description': 'Kopi hitam arabika pilihan',
        'category_id': 'cat_002',
        'price': 12000.0,
        'cost_price': 5000.0,
        'stock': 200,
        'min_stock': 20,
        'unit': 'cup',
        'image_path': 'https://images.unsplash.com/photo-1509042239860-f550ce710b93?w=200&q=80',
        'is_active': 1,
        'track_stock': 1,
        'has_variants': 0,
      },
      {
        'id': 'prod_008',
        'name': 'Pisang Goreng',
        'description': 'Pisang goreng crispy dengan cokelat',
        'category_id': 'cat_003',
        'price': 15000.0,
        'cost_price': 7000.0,
        'stock': 60,
        'min_stock': 8,
        'unit': 'porsi',
        'image_path': 'https://images.unsplash.com/photo-1568625365131-079e026a927d?w=200&q=80',
        'is_active': 1,
        'track_stock': 1,
        'has_variants': 0,
      },
    ];

    for (final product in products) {
      await db.insert('products', {...product, 'created_at': now, 'updated_at': now});
    }
  }

  // Generic CRUD operations
  Future<String> insert(String table, Map<String, dynamic> data) async {
    final db = await database;
    await db.insert(table, data, conflictAlgorithm: ConflictAlgorithm.replace);
    return data['id'] as String? ?? '';
  }

  Future<int> update(String table, Map<String, dynamic> data, String whereClause, List<dynamic> whereArgs) async {
    final db = await database;
    return await db.update(table, data, where: whereClause, whereArgs: whereArgs);
  }

  Future<int> delete(String table, String whereClause, List<dynamic> whereArgs) async {
    final db = await database;
    return await db.delete(table, where: whereClause, whereArgs: whereArgs);
  }

  Future<List<Map<String, dynamic>>> query(
    String table, {
    List<String>? columns,
    String? where,
    List<dynamic>? whereArgs,
    String? orderBy,
    int? limit,
    int? offset,
  }) async {
    final db = await database;
    return await db.query(
      table,
      columns: columns,
      where: where,
      whereArgs: whereArgs,
      orderBy: orderBy,
      limit: limit,
      offset: offset,
    );
  }

  Future<List<Map<String, dynamic>>> rawQuery(String sql, [List<dynamic>? args]) async {
    final db = await database;
    return await db.rawQuery(sql, args);
  }

  Future<int> rawUpdate(String sql, [List<dynamic>? args]) async {
    final db = await database;
    return await db.rawUpdate(sql, args);
  }
}
