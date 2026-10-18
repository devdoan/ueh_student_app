// ============================================================================
// 🎤 [THUYẾT MINH - MÀN HÌNH CHÀO (SPLASH SCREEN)]:
// "Dạ thưa thầy, màn hình Splash hiển thị hình ảnh thương hiệu UEH ngay khi mở ứng dụng.
// Màn hình này chạy trong 3 giây để người dùng làm quen với thương hiệu, đồng thời tạo
// khoảng thời gian đệm cho các dịch vụ nền (Firebase, SQLite, FCM) sẵn sàng hoạt động,
// sau đó tự động chuyển hướng vào HomeScreen."
// ============================================================================

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../routers/app_router.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // 🎤 [THUYẾT MINH - TỰ ĐỘNG CHUYỂN MÀN HÌNH]:
    // "Ngay khi widget được nạp (initState), hàm _goToHome() được gọi để bắt đầu đếm ngược."
    _goToHome();
  }

  // 🎤 [THUYẾT MINH - ĐẾM NGƯỢC VÀ ĐIỀU HƯỚNG]:
  // "Sử dụng Future.delayed 3 giây, sau đó kiểm tra mounted và dùng context.go(AppRoutes.home).
  // Việc dùng context.go thay vì push giúp thay thế hoàn toàn route hiện tại,
  // do đó khi người dùng ở màn hình chính bấm nút Back sẽ không bị quay ngược lại màn hình Splash."
  Future<void> _goToHome() async {
    await Future.delayed(const Duration(seconds: 3));
    if (mounted) context.go(AppRoutes.home);
  }

  @override
  Widget build(BuildContext context) {
    // 🎤 [THUYẾT MINH - GIAO DIỆN SPLASH]:
    // "Sử dụng Stack để xếp chồng:
    // 1. Ảnh nền nhận diện UEH (fit: BoxFit.cover).
    // 2. Lớp phủ đen bán trong suốt (alpha: 0.4) giúp dịu mắt và làm nổi bật vòng quay tiến trình.
    // 3. CircularProgressIndicator màu trắng xoay ở chính giữa."
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/images/nso-splash-landscape-1499x999.png',
            fit: BoxFit.cover,
          ),
          Container(color: Colors.black.withValues(alpha: 0.4)),
          const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

