import 'dart:async';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

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
      version: 1,
      onCreate: _onCreate,
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
}
