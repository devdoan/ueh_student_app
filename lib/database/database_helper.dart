import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/menu_item.dart';
import '../models/notification_item.dart';

// ============================================================================
// 🎤 [THUYẾT MINH: TẦNG CƠ SỞ DỮ LIỆU CỤC BỘ SQLITE (DATABASE HELPER)]
// - Sử dụng mô hình Singleton (DatabaseHelper._internal) duy nhất trong toàn app
// - Bảng menu_table: Cache dữ liệu menu từ API để app hoạt động OFFLINE khi mất mạng
// - Bảng notifications_table: Lưu trữ lịch sử thông báo từ Firebase Cloud Messaging
// ============================================================================
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

  // Khởi tạo Database ueh_student_app.db
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

  // --------------------------------------------------------------------------
  // 🎤 [THUYẾT MINH - CẤU TRÚC 2 BẢNG SQLITE]:
  // 1. menu_table: id, icon_name, menu_name, menu_url, ordering
  // 2. notifications_table: id, title, body, received_at, is_read, data
  // --------------------------------------------------------------------------
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

  // ==========================================================================
  // 🎤 [THUYẾT MINH - QUẢN LÝ MENU OFFLINE]:
  // - insertMenu: Dùng Batch để xóa cũ và ghi đè toàn bộ danh sách menu từ API
  // - getMenus: Đọc menu từ SQLite sắp xếp theo ordering để hiển thị lên Drawer
  // ==========================================================================
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

  // ==========================================================================
  // 🎤 [THUYẾT MINH - QUẢN LÝ THÔNG BÁO FIREBASE TRONG SQLITE]:
  // - insertNotification: Lưu thông báo mới nhận được từ Firebase
  // - getNotifications: Lấy danh sách thông báo theo thứ tự mới nhất (id DESC)
  // - getUnreadCount: Đếm số lượng thông báo chưa đọc (is_read = 0) để gắn badge đỏ
  // - markNotificationAsRead: Cập nhật is_read = 1 khi sinh viên mở xem
  // - deleteNotification & clearAllNotifications: Xóa 1 hoặc tất cả thông báo
  // ==========================================================================
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
