import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'firebase_options.dart';
import 'services/notification_service.dart';
import 'routers/app_router.dart';

// ============================================================================
// 🎤 [THUYẾT MINH: ĐIỂM KHỞI CHẠY ỨNG DỤNG (MAIN ENTRY POINT)]
// - WidgetsFlutterBinding.ensureInitialized(): Đảm bảo Flutter Engine sẵn sàng
// - Firebase.initializeApp(): Khởi tạo nền tảng Firebase đa nền tảng (Android/iOS)
// - FirebaseMessaging.onBackgroundMessage: Đăng ký hàm nhận thông báo khi app đóng/chạy ngầm
// - NotificationService().initialize(): Khởi tạo kênh thông báo Local Notification và subscribe topic
// ============================================================================
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Khởi tạo Firebase với cấu hình tự động từ flutterfire configure
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Đăng ký Background Message Handler độc lập cho Firebase Messaging
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  // Khởi tạo dịch vụ thông báo (kênh Android Channel, quyền thông báo, FCM token)
  await NotificationService().initialize();

  runApp(const MyApp());
}

// ============================================================================
// 🎤 [THUYẾT MINH: CẤU HÌNH GIAO DIỆN GỐC (MYAPP)]
// - MaterialApp.router: Tích hợp GoRouter để điều hướng trang chuyên nghiệp
// - seedColor #005F69: Màu xanh cổ vịt chủ đạo theo nhận diện thương hiệu UEH
// - useMaterial3: Áp dụng chuẩn thiết kế Material Design 3 hiện đại
// ============================================================================
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'UEH Student App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF005F69)),
        useMaterial3: true,
      ),
      routerConfig: appRouter,
    );
  }
}
