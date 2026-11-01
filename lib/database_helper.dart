
import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();

  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;

    _database = await _initDB('myasset.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return openDatabase(
      path,
      version: 5,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,

    );

  }

  // ============================================================
  // MEMBUAT DATABASE BARU
  // ============================================================

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
  CREATE TABLE users (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL,
    email TEXT NOT NULL UNIQUE,
    password TEXT NOT NULL,
    profile_image_path TEXT
  )
''');

    await _createAssetsTable(db);
    await _createCustomCategoriesTable(db);
    await _createAssetHistoryTable(db);
  }

  // ============================================================
  // MIGRASI DATABASE LAMA
  // ============================================================

  Future<void> _upgradeDB(
      Database db,
      int oldVersion,
      int newVersion,
      ) async {
    if (oldVersion < 2) {
      await _createAssetsTable(db);
    }

    if (oldVersion < 3) {
      await _ensureAssetExtrasOnDB(db);
    }

    if (oldVersion < 5) {
      await db.execute(
        'ALTER TABLE users ADD COLUMN profile_image_path TEXT',
      );
    }

    if (oldVersion < 4) {
      await _createAssetHistoryTable(db);
    }
  }

  // ============================================================
  // TABEL ASET
  // ============================================================

  Future<void> _createAssetsTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS assets (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        name TEXT NOT NULL,
        category TEXT NOT NULL,
        value INTEGER NOT NULL DEFAULT 0,
        purchase_date TEXT NOT NULL,
        description TEXT,
        created_at TEXT NOT NULL,
        image_path TEXT,
        FOREIGN KEY (user_id) REFERENCES users(id)
      )
    ''');
  }

  // ============================================================
  // TABEL KATEGORI CUSTOM
  // ============================================================

  Future<void> _createCustomCategoriesTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS custom_categories (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        name TEXT NOT NULL COLLATE NOCASE,
        UNIQUE(user_id, name)
      )
    ''');
  }

  // ============================================================
  // TABEL RIWAYAT AKTIVITAS
  // ============================================================

  Future<void> _createAssetHistoryTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS asset_history (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        asset_id INTEGER,
        asset_name TEXT NOT NULL,
        category TEXT NOT NULL,
        action TEXT NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');
  }

  Future<void> _recordHistory(
      Transaction txn, {
        required int userId,
        required int assetId,
        required String assetName,
        required String category,
        required String action,
      }) async {
    await txn.insert('asset_history', {
      'user_id': userId,
      'asset_id': assetId,
      'asset_name': assetName,
      'category': category,
      'action': action,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  Future<List<Map<String, dynamic>>> getAssetHistory(
      int userId,
      ) async {
    final db = await database;

    return db.query(
      'asset_history',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'created_at DESC, id DESC',
    );
  }

  // ============================================================
  // TAMBAHAN DATABASE UNTUK FOTO & KATEGORI
  // ============================================================

  Future<void> _ensureAssetExtrasOnDB(Database db) async {
    await _createAssetsTable(db);

    final columns = await db.rawQuery(
      'PRAGMA table_info(assets)',
    );

    final hasImagePath = columns.any(
          (column) => column['name'] == 'image_path',
    );

    if (!hasImagePath) {
      await db.execute(
        'ALTER TABLE assets ADD COLUMN image_path TEXT',
      );
    }

    await _createCustomCategoriesTable(db);
  }

  Future<void> ensureAssetExtras() async {
    final db = await database;
    await _ensureAssetExtrasOnDB(db);
  }

  // ============================================================
  // REGISTER
  // ============================================================

  Future<int> registerUser(Map<String, dynamic> row) async {
    final db = await database;

    final data = Map<String, dynamic>.from(row);

    data['name'] = data['name'].toString().trim();
    data['email'] = data['email'].toString().trim().toLowerCase();
    data['password'] = data['password'].toString();

    try {
      return await db.insert('users', data);
    } catch (e) {
      debugPrint('Gagal registrasi: $e');
      return -1;
    }
  }

  // ============================================================
  // LOGIN
  // ============================================================

  Future<Map<String, dynamic>?> loginUser(
      String email,
      String password,
      ) async {
    final db = await database;

    final users = await db.query(
      'users',
      columns: ['id', 'name', 'email'],
    );

    debugPrint(
      'JUMLAH AKUN TERSIMPAN: ${users.length}',
    );

    final result = await db.query(
      'users',
      where: 'LOWER(TRIM(email)) = ? AND password = ?',
      whereArgs: [
        email.trim().toLowerCase(),
        password,
      ],
      limit: 1,
    );

    if (result.isNotEmpty) {
      return result.first;
    }

    return null;
  }

  // ============================================================
  // TAMBAH ASET + CATAT RIWAYAT
  // ============================================================

  Future<int> addAsset(Map<String, dynamic> asset) async {
    await ensureAssetExtras();

    final db = await database;

    return db.transaction((txn) async {
      final assetId = await txn.insert('assets', asset);

      await _recordHistory(
        txn,
        userId: asset['user_id'] as int,
        assetId: assetId,
        assetName: asset['name'].toString(),
        category: asset['category'].toString(),
        action: 'added',
      );

      return assetId;
    });
  }

  // ============================================================
  // AMBIL ASET MILIK PENGGUNA
  // ============================================================

  Future<List<Map<String, dynamic>>> getAssets(
      int userId,
      ) async {
    final db = await database;

    return db.query(
      'assets',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'created_at DESC',
    );
  }

  // ============================================================
  // PERBARUI ASET + CATAT RIWAYAT
  // ============================================================

  Future<int> updateAsset(
      int assetId,
      int userId,
      Map<String, dynamic> changes,
      ) async {
    final db = await database;

    const allowedColumns = {
      'name',
      'category',
      'value',
      'purchase_date',
      'description',
      'image_path',
    };

    final data = Map<String, dynamic>.from(changes)
      ..removeWhere(
            (key, value) => !allowedColumns.contains(key),
      );

    if (data.isEmpty) return 0;

    return db.transaction((txn) async {
      final existing = await txn.query(
        'assets',
        where: 'id = ? AND user_id = ?',
        whereArgs: [assetId, userId],
        limit: 1,
      );

      if (existing.isEmpty) return 0;

      final updated = await txn.update(
        'assets',
        data,
        where: 'id = ? AND user_id = ?',
        whereArgs: [assetId, userId],
      );

      if (updated > 0) {
        await _recordHistory(
          txn,
          userId: userId,
          assetId: assetId,
          assetName:
          (data['name'] ?? existing.first['name']).toString(),
          category:
          (data['category'] ?? existing.first['category'])
              .toString(),
          action: 'updated',
        );
      }

      return updated;
    });
  }

  // ============================================================
  // HAPUS ASET + CATAT RIWAYAT
  // ============================================================

  Future<int> deleteAsset(
      int assetId,
      int userId,
      ) async {
    final db = await database;

    return db.transaction((txn) async {
      final existing = await txn.query(
        'assets',
        where: 'id = ? AND user_id = ?',
        whereArgs: [assetId, userId],
        limit: 1,
      );

      if (existing.isEmpty) return 0;

      final deleted = await txn.delete(
        'assets',
        where: 'id = ? AND user_id = ?',
        whereArgs: [assetId, userId],
      );

      if (deleted > 0) {
        await _recordHistory(
          txn,
          userId: userId,
          assetId: assetId,
          assetName: existing.first['name'].toString(),
          category: existing.first['category'].toString(),
          action: 'deleted',
        );
      }

      return deleted;
    });
  }

  // ============================================================
  // AMBIL KATEGORI CUSTOM
  // ============================================================

  Future<List<String>> getCustomCategories(
      int userId,
      ) async {
    await ensureAssetExtras();

    final db = await database;

    final rows = await db.query(
      'custom_categories',
      columns: ['name'],
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'name COLLATE NOCASE ASC',
    );

    return rows
        .map((row) => row['name'] as String)
        .toList();
  }

  // ============================================================
  // TAMBAH KATEGORI CUSTOM
  // ============================================================

  Future<void> addCustomCategory(
      int userId,
      String categoryName,
      ) async {
    await ensureAssetExtras();

    final cleanName = categoryName.trim();

    if (cleanName.isEmpty) {
      throw ArgumentError(
        'Nama kategori tidak boleh kosong',
      );
    }

    final db = await database;

    await db.insert(
      'custom_categories',
      {
        'user_id': userId,
        'name': cleanName,
      },
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }

  Future<Map<String, dynamic>?> getUserProfile(int userId) async {
    final db = await database;

    final result = await db.query(
      'users',
      columns: ['id', 'name', 'email', 'profile_image_path'],
      where: 'id = ?',
      whereArgs: [userId],
      limit: 1,
    );

    return result.isEmpty ? null : result.first;
  }

  Future<int> updateUserProfile({
    required int userId,
    required String name,
    String? imagePath,
  }) async {
    final cleanName = name.trim();

    if (cleanName.isEmpty) {
      throw ArgumentError('Nama tidak boleh kosong');
    }

    final db = await database;

    final changes = <String, dynamic>{
      'name': cleanName,
    };

    if (imagePath != null) {
      changes['profile_image_path'] = imagePath;
    }

    return db.update(
      'users',
      changes,
      where: 'id = ?',
      whereArgs: [userId],
    );
  }
}
