import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/menu_item.dart';
import '../models/notification_item.dart';

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
      version: 3,
      onCreate: (db, version) async {
        await _createDb(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute('DROP TABLE IF EXISTS menu_table');
        }
        if (oldVersion < 3) {
          await db.execute('''
            CREATE TABLE IF NOT EXISTS notifications_table(
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              title TEXT,
              body TEXT,
              received_at TEXT,
              is_read INTEGER,
              data TEXT
            )
          ''');
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

    await db.execute('''
      CREATE TABLE notifications_table(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT,
        body TEXT,
        received_at TEXT,
        is_read INTEGER,
        data TEXT
      )
    ''');
  }

  // --- MENU METHODS ---
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

  // --- NOTIFICATION METHODS ---
  Future<int> insertNotification(NotificationItemModel item) async {
    final db = await database;
    return await db.insert(
      'notifications_table',
      item.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<NotificationItemModel>> getNotifications() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'notifications_table',
      orderBy: 'id DESC',
    );
    return List.generate(maps.length, (i) {
      return NotificationItemModel.fromMap(maps[i]);
    });
  }

  Future<int> getUnreadCount() async {
    final db = await database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM notifications_table WHERE is_read = 0');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<void> markNotificationAsRead(int id) async {
    final db = await database;
    await db.update(
      'notifications_table',
      {'is_read': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> deleteNotification(int id) async {
    final db = await database;
    await db.delete(
      'notifications_table',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> clearAllNotifications() async {
    final db = await database;
    await db.delete('notifications_table');
  }
}
