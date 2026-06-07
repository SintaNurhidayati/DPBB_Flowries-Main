import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();

  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('flowries.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 5, 
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  Future _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute(
        'ALTER TABLE transactions ADD COLUMN buktiPembayaran TEXT',
      );
      await db.execute(
        'ALTER TABLE transactions ADD COLUMN tipePesanan TEXT DEFAULT "katalog"',
      );
      await db.execute(
        'ALTER TABLE transactions ADD COLUMN catatanCustom TEXT',
      );
    }
    if (oldVersion < 3) {
      await db.execute(
        'ALTER TABLE products ADD COLUMN kategori TEXT DEFAULT "Semua"',
      );
      await db.execute(
        'ALTER TABLE users ADD COLUMN isActive INTEGER DEFAULT 1',
      );
      await db.execute('DROP TABLE IF EXISTS vouchers');
    }
    if (oldVersion < 4) {
      await db.execute('ALTER TABLE reviews ADD COLUMN reply TEXT');
      await db.execute('ALTER TABLE reviews ADD COLUMN repliedAt TEXT');
      await db.execute('ALTER TABLE reviews ADD COLUMN repliedBy TEXT');
    }
    if (oldVersion < 5) {
      // Create custom tables for version 5
      await db.execute('''
        CREATE TABLE IF NOT EXISTS custom_flowers (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL,
          price REAL NOT NULL,
          image_url TEXT,
          createdAt TEXT
        )
      ''');
      await db.execute('''
        CREATE TABLE IF NOT EXISTS custom_wrappings (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL,
          price REAL NOT NULL,
          image_url TEXT,
          createdAt TEXT
        )
      ''');
      await db.execute('''
        CREATE TABLE IF NOT EXISTS custom_sizes (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL,
          price REAL NOT NULL,
          description TEXT,
          createdAt TEXT
        )
      ''');
    }
  }

  Future _createDB(Database db, int version) async {
    const idType = 'TEXT PRIMARY KEY';
    const textType = 'TEXT NOT NULL';
    const integerType = 'INTEGER NOT NULL';
    const realType = 'REAL NOT NULL';

    // 1. Table Users
    await db.execute('''
      CREATE TABLE users (
        id $idType,
        email $textType,
        password $textType,
        nama $textType,
        noTelepon $textType,
        alamat $textType,
        tipeUser $textType,
        createdAt $textType,
        isActive INTEGER DEFAULT 1
      )
    ''');

    // 2. Table Products
    await db.execute('''
      CREATE TABLE products (
        id $idType,
        nama $textType,
        deskripsi $textType,
        harga $realType,
        gambar $textType,
        stok $integerType,
        rating $realType,
        jumlahUlasan $integerType,
        createdAt $textType,
        createdBy $textType,
        kategori $textType DEFAULT 'Semua'
      )
    ''');

    // 3. Table Cart Items
    await db.execute('''
      CREATE TABLE cart_items (
        id $idType,
        productId $textType,
        quantity $integerType,
        FOREIGN KEY (productId) REFERENCES products (id) ON DELETE CASCADE
      )
    ''');

    // 4. Table Transactions
    await db.execute('''
      CREATE TABLE transactions (
        id $idType,
        userId $textType,
        items $textType,
        totalSebelomDiskon $realType,
        diskonNominal $realType,
        totalSetelahDiskon $realType,
        status $textType,
        tanggalPemesanan $textType,
        tanggalSelesai TEXT,
        metodePembayaran $textType,
        alamatPengiriman $textType,
        buktiPembayaran TEXT,
        tipePesanan TEXT DEFAULT 'katalog',
        catatanCustom TEXT,
        FOREIGN KEY (userId) REFERENCES users (id) ON DELETE CASCADE
      )
    ''');

    // 5. Table Reviews
    await db.execute('''
      CREATE TABLE reviews (
        id $idType,
        productId $textType,
        userId $textType,
        rating $integerType,
        komentar $textType,
        createdAt $textType,
        image_url TEXT,
        reply TEXT,
        repliedAt TEXT,
        repliedBy TEXT,
        FOREIGN KEY (productId) REFERENCES products (id) ON DELETE CASCADE,
        FOREIGN KEY (userId) REFERENCES users (id) ON DELETE CASCADE
      )
    ''');

    // 6. Table Custom Flowers
    await db.execute('''
      CREATE TABLE custom_flowers (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        price REAL NOT NULL,
        image_url TEXT,
        createdAt TEXT
      )
    ''');

    // 7. Table Custom Wrappings
    await db.execute('''
      CREATE TABLE custom_wrappings (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        price REAL NOT NULL,
        image_url TEXT,
        createdAt TEXT
      )
    ''');

    // 8. Table Custom Sizes
    await db.execute('''
      CREATE TABLE custom_sizes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        price REAL NOT NULL,
        description TEXT,
        createdAt TEXT
      )
    ''');
  }

  // PRODUCT METHODS
  Future<Map<String, dynamic>?> getProductById(int id) async {
    final db = await instance.database;
    final maps = await db.query(
      'products',
      where: 'id = ?',
      whereArgs: [id.toString()],
    );
    if (maps.isNotEmpty) return maps.first;
    return null;
  }

  Future<List<Map<String, dynamic>>> getAllProducts() async {
    final db = await database;
    return await db.query('products', orderBy: 'createdAt DESC');
  }

  Future<int> insertProduct(Map<String, dynamic> product) async {
    final db = await instance.database;
    return await db.insert('products', product);
  }

  Future<int> updateProduct(String id, Map<String, dynamic> product) async {
    final db = await instance.database;
    return await db.update(
      'products',
      product,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteProduct(String id) async {
    final db = await instance.database;
    return await db.delete('products', where: 'id = ?', whereArgs: [id]);
  }

  // REVIEW METHODS
  Future<List<Map<String, dynamic>>> getReviewsByProduct(int productId) async {
    final db = await instance.database;
    return await db.query(
      'reviews',
      where: 'productId = ?',
      whereArgs: [productId.toString()],
      orderBy: 'createdAt DESC',
    );
  }

  // CUSTOM FLOWERS
  Future<List<Map<String, dynamic>>> getCustomFlowers() async {
    final db = await database;
    return await db.query('custom_flowers', orderBy: 'createdAt DESC');
  }

  Future<int> insertCustomFlower(Map<String, dynamic> data) async {
    final db = await database;
    data['createdAt'] = DateTime.now().toIso8601String();
    return await db.insert('custom_flowers', data);
  }

  Future<int> updateCustomFlower(int id, Map<String, dynamic> data) async {
    final db = await database;
    data['createdAt'] = DateTime.now().toIso8601String();
    return await db.update(
      'custom_flowers',
      data,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteCustomFlower(int id) async {
    final db = await database;
    return await db.delete('custom_flowers', where: 'id = ?', whereArgs: [id]);
  }

  // CUSTOM WRAPPINGS
  Future<List<Map<String, dynamic>>> getCustomWrappings() async {
    final db = await database;
    return await db.query('custom_wrappings', orderBy: 'createdAt DESC');
  }

  Future<int> insertCustomWrapping(Map<String, dynamic> data) async {
    final db = await database;
    data['createdAt'] = DateTime.now().toIso8601String();
    return await db.insert('custom_wrappings', data);
  }

  Future<int> updateCustomWrapping(int id, Map<String, dynamic> data) async {
    final db = await database;
    data['createdAt'] = DateTime.now().toIso8601String();
    return await db.update(
      'custom_wrappings',
      data,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteCustomWrapping(int id) async {
    final db = await database;
    return await db.delete(
      'custom_wrappings',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // CUSTOM SIZES
  Future<List<Map<String, dynamic>>> getCustomSizes() async {
    final db = await database;
    return await db.query('custom_sizes', orderBy: 'createdAt DESC');
  }

  Future<int> insertCustomSize(Map<String, dynamic> data) async {
    final db = await database;
    data['createdAt'] = DateTime.now().toIso8601String();
    return await db.insert('custom_sizes', data);
  }

  Future<int> updateCustomSize(int id, Map<String, dynamic> data) async {
    final db = await database;
    data['createdAt'] = DateTime.now().toIso8601String();
    return await db.update(
      'custom_sizes',
      data,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteCustomSize(int id) async {
    final db = await database;
    return await db.delete('custom_sizes', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> close() async {
    final db = await instance.database;
    db.close();
  }
}
