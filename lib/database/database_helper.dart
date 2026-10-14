import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/menu_item.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  factory DatabaseHelper() => _instance;

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDb();
    return _database!;
  }

  Future<Database> _initDb() async {
    String path = join(await getDatabasesPath(), 'ueh_student_app.db');
    return await openDatabase(
      path,
      version: 2,
      onCreate: (db, version) async {
        await _createDb(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute('DROP TABLE IF EXISTS menu_table');
          await _createDb(db);
        }
      },
    );
  }

  Future<void> _createDb(Database db) async {
    await db.execute('''
      CREATE TABLE menu_table(
        id INTEGER PRIMARY KEY,
        icon_name TEXT,
        menu_name TEXT,
        menu_url TEXT,
        ordering INTEGER
      )
    ''');
  }

  Future<void> insertMenu(List<MenuItemModel> menus) async {
    final db = await database;
    Batch batch = db.batch();
    batch.delete('menu_table');
    for (var menu in menus) {
      batch.insert('menu_table', menu.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }

  Future<List<MenuItemModel>> getMenus() async {
    final db = await database;
    final List<Map<String, dynamic>> maps =
        await db.query('menu_table', orderBy: 'ordering ASC');
    return List.generate(maps.length, (i) {
      return MenuItemModel.fromMap(maps[i]);
    });
  }
}
