import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../database/database_helper.dart';
import '../models/notification_item.dart';
import '../firebase_options.dart';

// Hàm xử lý thông báo khi App đang chạy nền hoặc đã tắt hoàn toàn (Background/Terminated)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    final db = DatabaseHelper();
    final now = DateTime.now().toString().substring(0, 19).replaceFirst('T', ' ');
    final title = message.notification?.title ?? message.data['title'] ?? 'Thông báo UEH';
    final body = message.notification?.body ?? message.data['body'] ?? '';

    await db.insertNotification(NotificationItemModel(
      title: title,
      body: body,
      receivedAt: now,
      data: message.data.isNotEmpty ? jsonEncode(message.data) : null,
    ));
    debugPrint('📩 [Background] Đã lưu thông báo vào SQLite: $title');
  } catch (e) {
    debugPrint('❌ [Background Handler Error]: $e');
  }
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  final DatabaseHelper _dbHelper = DatabaseHelper();

  // Callback báo cho màn hình Thông báo biết để tự động load lại dữ liệu ngay lập tức
  VoidCallback? onNotificationReceived;

  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'ueh_notification_channel',
    'Thông báo UEH',
    description: 'Kênh nhận thông báo điểm danh và tin tức từ UEH',
    importance: Importance.max,
    playSound: true,
    enableVibration: true,
  );

  Future<void> initialize() async {
    // 1. Xin quyền nhận thông báo từ người dùng (bắt buộc cho Android 13+ và iOS)
    NotificationSettings settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );
    debugPrint('🔔 Trạng thái cấp quyền thông báo: ${settings.authorizationStatus}');

    // 2. Khởi tạo Local Notifications (hiển thị popup trên máy Android/iOS)
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings iosSettings = DarwinInitializationSettings();

    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        debugPrint('👉 Người dùng vừa bấm vào thông báo: ${response.payload}');
      },
    );

    // 3. Tạo Notification Channel trên Android
    final androidPlugin = _localNotifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin != null) {
      await androidPlugin.createNotificationChannel(_channel);
      await androidPlugin.requestNotificationsPermission();
    }

    // 4. Lấy và in mã FCM Token ra console để tiện gửi thử nghiệm
    try {
      String? token = await _fcm.getToken();
      debugPrint('\n======================================================');
      debugPrint('🔥 FCM DEVICE TOKEN (Copy token này dán lên Firebase test):');
      debugPrint('$token');
      debugPrint('======================================================\n');
    } catch (e) {
      debugPrint('❌ Không thể lấy FCM Token: $e');
    }

    // Đăng ký nhận thông báo nhóm toàn trường
    try {
      await _fcm.subscribeToTopic('ueh_all');
      debugPrint('📢 Đã đăng ký nhận thông báo nhóm: ueh_all');
    } catch (e) {
      debugPrint('⚠️ Không thể đăng ký topic ueh_all: $e');
    }

    // 5. Lắng nghe thông báo khi App ĐANG MỞ (Foreground)
    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      debugPrint('📩 Nhận thông báo Foreground: ${message.notification?.title}');

      final title = message.notification?.title ?? message.data['title'] ?? 'Thông báo UEH';
      final body = message.notification?.body ?? message.data['body'] ?? '';
      final now = DateTime.now().toString().substring(0, 19).replaceFirst('T', ' ');

      // Lưu ngay vào SQLite
      await _dbHelper.insertNotification(NotificationItemModel(
        title: title,
        body: body,
        receivedAt: now,
        data: message.data.isNotEmpty ? jsonEncode(message.data) : null,
      ));

      // Báo UI cập nhật tức thì
      onNotificationReceived?.call();

      // Hiện Pop-up Banner đỉnh màn hình
      RemoteNotification? notification = message.notification;
      if (notification != null) {
        _localNotifications.show(
          id: notification.hashCode,
          title: title,
          body: body,
          notificationDetails: NotificationDetails(
            android: AndroidNotificationDetails(
              _channel.id,
              _channel.name,
              channelDescription: _channel.description,
              importance: Importance.max,
              priority: Priority.high,
              icon: '@mipmap/ic_launcher',
              playSound: true,
              enableVibration: true,
            ),
          ),
          payload: jsonEncode(message.data),
        );
      }
    });

    // 6. Xử lý khi người dùng ấn vào thông báo từ thanh thông báo hệ thống
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('🚀 Mở app từ thông báo: ${message.notification?.title}');
      onNotificationReceived?.call();
    });
  }
}

