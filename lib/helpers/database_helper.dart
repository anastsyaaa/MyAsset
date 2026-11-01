import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/asset_model.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  // Inisialisasi Database
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('myasset.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  // Membuat tabel 'assets' di dalam SQLite
  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE assets (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nama TEXT NOT NULL,
        kategori TEXT NOT NULL,
        tanggalBeli TEXT NOT NULL,
        hargaBeli REAL NOT NULL,
        catatan TEXT
      )
    ''');
  }

  // FUNGSI 1: Tambah Asset Baru
  Future<int> insertAsset(AssetModel asset) async {
    final db = await instance.database;
    return await db.insert('assets', asset.toMap());
  }

  // FUNGSI 2: Ambil Semua Asset dari Database
  Future<List<AssetModel>> getAllAssets() async {
    final db = await instance.database;
    final result = await db.query('assets', orderBy: 'id DESC');
    return result.map((json) => AssetModel.fromMap(json)).toList();
  }

  // FUNGSI 3: Hapus Asset berdasarkan ID
  Future<int> deleteAsset(int id) async {
    final db = await instance.database;
    return await db.delete('assets', where: 'id = ?', whereArgs: [id]);
  }
}