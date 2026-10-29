import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('mayorista_connect.db');
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

  Future<void> _createDB(Database db, int version) async {
    // Tabla para registrar pedidos locales (Offline-First)
    await db.execute('''
      CREATE TABLE pedidos (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        bodega_nombre TEXT NOT NULL,
        bodega_ruc TEXT NOT NULL,
        total REAL NOT NULL,
        fecha TEXT NOT NULL,
        sincronizado INTEGER NOT NULL
      )
    ''');
  }

  Future<int> insertarPedido(Map<String, dynamic> row) async {
    final db = await instance.database;
    return await db.insert('pedidos', row);
  }

  Future<int> actualizarPedido(int id, double nuevoTotal) async {
    final db = await instance.database;
    return await db.update(
      'pedidos',
      {'total': nuevoTotal},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> eliminarPedido(int id) async {
    final db = await instance.database;
    return await db.delete(
      'pedidos',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<Map<String, dynamic>>> obtenerPedidos() async {
    final db = await instance.database;
    return await db.query('pedidos', orderBy: 'id DESC');
  }

  Future<int> marcarComoSincronizados() async {
    final db = await instance.database;
    return await db.update(
      'pedidos',
      {'sincronizado': 1},
      where: 'sincronizado = ?',
      whereArgs: [0],
    );
  }
}