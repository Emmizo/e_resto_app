import 'dart:async';

import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _db;

  Future<Database> get db async {
    if (_db != null) return _db!;
    _db = await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    final documentsDirectory = await getApplicationDocumentsDirectory();
    final path = join(documentsDirectory.path, 'eresta_app.db');
    return await openDatabase(
      path,
      version: 2,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE restaurants (
        id INTEGER PRIMARY KEY,
        name TEXT,
        description TEXT,
        address TEXT,
        longitude TEXT,
        latitude TEXT,
        phoneNumber TEXT,
        email TEXT,
        website TEXT,
        openingHours TEXT,
        cuisineId INTEGER,
        priceRange TEXT,
        image TEXT,
        ownerId INTEGER,
        isApproved INTEGER,
        status INTEGER,
        averageRating REAL,
        isFavorite INTEGER
      )
    ''');
    await db.execute('''
      CREATE TABLE banners (
        id INTEGER PRIMARY KEY,
        restaurantId INTEGER,
        title TEXT,
        description TEXT,
        imagePath TEXT,
        startDate TEXT,
        endDate TEXT,
        isActive INTEGER,
        restaurantName TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE categories (
        id INTEGER PRIMARY KEY,
        name TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE cart (
        id TEXT PRIMARY KEY,
        name TEXT,
        description TEXT,
        price REAL,
        imageUrl TEXT,
        restaurantId TEXT,
        restaurantName TEXT,
        quantity INTEGER
      )
    ''');
    await db.execute('''
      CREATE TABLE favorites (
        id INTEGER PRIMARY KEY,
        restaurantId INTEGER
      )
    ''');
    await db.execute('''
      CREATE TABLE orders (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        items TEXT,
        total REAL,
        address TEXT,
        status TEXT,
        createdAt TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE reservations (
        id INTEGER PRIMARY KEY,
        data TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE action_queue (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        actionType TEXT,
        payload TEXT,
        createdAt TEXT,
        retryCount INTEGER DEFAULT 0,
        lastError TEXT
      )
    ''');
  }

  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Add missing columns to orders table if they do not exist
      await db.execute('ALTER TABLE orders ADD COLUMN total_amount REAL;');
      await db.execute('ALTER TABLE orders ADD COLUMN delivery_address TEXT;');
      await db.execute('ALTER TABLE orders ADD COLUMN restaurant_id INTEGER;');
      await db.execute('ALTER TABLE orders ADD COLUMN payment_method TEXT;');
      await db.execute('ALTER TABLE orders ADD COLUMN created_at TEXT;');
    }
  }
}
