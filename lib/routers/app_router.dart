// ============================================================================
// 🎤 [THUYẾT MINH - ROUTER / ĐIỀU HƯỚNG]:
// "Dạ thưa thầy, em sử dụng thư viện chuẩn go_router của Flutter để quản lý
// điều hướng có cấu trúc (declarative routing), giúp quản lý các màn hình rõ ràng,
// tránh hardcode đường dẫn và hỗ trợ truyền tham số đối tượng an toàn."
// ============================================================================

import 'package:go_router/go_router.dart';

import '../screens/home_screen.dart';
import '../widgets/splash_screen.dart';
import '../screens/news_detail_screen.dart';
import '../models/news_item.dart';

// 🎤 [THUYẾT MINH - HẰNG SỐ ĐƯỜNG DẪN]:
// "Em định nghĩa class AppRoutes với các static const đại diện cho từng route.
// Việc này giúp tránh gõ sai chính tả và dễ bảo trì khi mở rộng ứng dụng."
class AppRoutes {
  static const splash = '/';
  static const home = '/home';
  static const newsDetail = '/news_detail';
}

// 🎤 [THUYẾT MINH - CẤU HÌNH GOROUTER]:
// "Khởi tạo router với điểm xuất phát ban đầu (initialLocation) là màn hình Splash (/).
// Sau 3 giây ở màn hình Splash, ứng dụng sẽ tự chuyển hướng vào /home."
final GoRouter appRouter = GoRouter(
  initialLocation: AppRoutes.splash,
  routes: [
    // 1. Màn hình Chào (Splash Screen)
    GoRoute(
      path: AppRoutes.splash,
      builder: (context, state) => const SplashScreen(),
    ),
    // 2. Màn hình Chính (Home Screen - Chứa Bottom Navigation Bar 4 Tab)
    GoRoute(
      path: AppRoutes.home,
      builder: (context, state) => const HomeScreen(),
    ),
    // 3. Màn hình Chi tiết bài viết (News Detail Screen)
    // 🎤 [THUYẾT MINH - TRUYỀN THAM SỐ QUA EXTRA]:
    // "Khi người dùng bấm vào một bài viết từ màn hình tin tức, đối tượng NewsItemModel
    // được đóng gói và truyền sang màn hình chi tiết thông qua state.extra,
    // đảm bảo tính an toàn kiểu dữ liệu (type-safe) mà không cần query lại API ban đầu."
    GoRoute(
      path: AppRoutes.newsDetail,
      builder: (context, state) {
        final item = state.extra as NewsItemModel;
        return NewsDetailScreen(newsItem: item);
      },
    ),
  ],
);

