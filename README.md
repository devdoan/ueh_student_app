# UEH Student App

App Flutter cho sinh viên UEH. Điều hướng bằng `go_router`, icon bằng `font_awesome_flutter`.

## Yêu cầu môi trường

- Flutter SDK kênh `master`, Dart `^3.14.0-201.0.dev` (xem `environment.sdk` trong `pubspec.yaml`).
- Android SDK (đã test với `compileSdk`/`targetSdk` mặc định của Flutter, build-tools 36.0.0).
- Windows: xem mục "Vấn đề đã biết" bên dưới trước khi build Android.

Cài đặt:

```bash
flutter pub get
```

## Cấu trúc code (`lib/`)

```
lib/
  main.dart                    # MaterialApp.router, theme, entrypoint
  routers/
    app_router.dart            # GoRouter: '/' -> SplashScreen, '/home' -> HomeScreen
  widgets/
    splash_screen.dart         # Splash: ảnh nền + lớp phủ đen mờ + spinner, delay 3s -> /home
    home_screen.dart           # Scaffold chính: AppBar + Drawer + BottomNavigationBar (4 tab)
    app_drawer.dart            # Nav drawer bên trái (menu UEH)
    ueh_news_webview.dart      # WebView load https://ueh.edu.vn/tintucmobile (tab "Trang chủ")
```

Không có thư mục `models/`, `services/`, `state management` nào khác — project hiện tại thuần UI, chưa có gọi API/backend riêng ngoài WebView.

## Hiện trạng các màn hình

### Splash screen (`splash_screen.dart`)
- Hiển thị full-screen ảnh `assets/images/nso-splash-landscape-1499x999.png`, phủ lớp đen mờ 40%, `CircularProgressIndicator` màu trắng ở giữa.
- Delay 3 giây rồi `context.go('/home')`.
- Native splash (lúc app chưa load xong Flutter engine) dùng `flutter_native_splash`, config trong `pubspec.yaml` (nền trắng + cùng ảnh). Nếu đổi ảnh/màu native splash, sửa `pubspec.yaml` rồi chạy lại:
  ```bash
  dart run flutter_native_splash:create
  ```

### Home screen (`home_screen.dart`)
- AppBar: nền `#005F69`, chữ/icon trắng, title "Trang chủ".
- Drawer (`app_drawer.dart`): header nền `#005F69` + logo `assets/images/logo-header.png` căn giữa (không còn avatar tròn/text cũ). Danh sách menu (chưa có điều hướng thật, mỗi item chỉ đóng drawer khi bấm):
  Tin tức UEH, Sự kiện UEH, Xem điểm, Định danh khuôn mặt, Thời khóa biểu, Lịch thi, Chăm sóc sức khỏe, UEH Go Green Station, Liên hệ trực tiếp UEH, UEH Green Coin, Đã điểm danh.
- BottomNavigationBar 4 tab:
  1. **Trang chủ** — `UehNewsWebView`: `webview_flutter` load `https://ueh.edu.vn/tintucmobile`, có spinner khi đang tải.
  2. **Thông báo** — placeholder (icon + text giữa màn hình, chưa có nội dung thật).
  3. **Điểm danh** — placeholder.
  4. **Tài khoản** — placeholder.

## Việc chưa làm / TODO tiếp theo

- [ ] Các tab "Thông báo", "Điểm danh", "Tài khoản" mới là placeholder, cần xây UI + logic thật.
- [ ] Các item trong nav drawer chưa điều hướng đến màn hình con nào — cần tạo route/screen tương ứng.
- [ ] Chưa có backend/API integration nào ngoài WebView tin tức.
- [ ] `applicationId` Android vẫn là mặc định `com.example.student_app` — **phải đổi** trước khi phát hành chính thức (đây là bước gần như không thể đổi ngược sau khi đã publish lên store).
- [ ] Release APK hiện ký bằng **debug key** (`android/app/build.gradle.kts` → `signingConfig = signingConfigs.getByName("debug")`). Cần tạo keystore riêng trước khi nộp Google Play.
- [ ] iOS: đã copy icon set vào `ios/Runner/Assets.xcassets/AppIcon.appiconset/` nhưng **chưa build/test trên máy Mac/Xcode** (máy dev hiện tại là Windows).

## Vấn đề đã biết (đã xử lý)

- **Lỗi build Windows – Kotlin incremental cache**: build Android từng fail với lỗi
  `IllegalStateException: Storage ... is already registered` khi compile `webview_flutter_android`
  (bug của Kotlin Build Tools API mới trên Windows, không liên quan code Dart).
  Đã fix bằng cách thêm vào `android/gradle.properties`:
  ```
  kotlin.incremental=false
  org.gradle.parallel=false
  ```
  Nếu gặp lại lỗi tương tự: `flutter clean` rồi build lại.

- **App icon**: bộ icon trong `assets/AppIcons/` (tạo bằng appicon.co) đã được áp dụng:
  - Android: `android/app/src/main/res/mipmap-*/ic_launcher.png` (icon flat) +
    `mipmap-anydpi-v26/ic_launcher.xml` (adaptive icon, foreground = `drawable-xxxhdpi/ic_launcher_foreground.png`,
    background = `values/colors.xml` → `ic_launcher_background = #FFFFFF`).
  - iOS: toàn bộ `ios/Runner/Assets.xcassets/AppIcon.appiconset/` đã được thay bằng bộ mới.
  - ⚠️ **Chưa giải quyết xong**: trên emulator lẫn điện thoại thật, icon ngoài màn hình chính bị
    xuất hiện một viền xanh dương nhạt bao quanh (không có trong ảnh gốc). Đã xác nhận qua
    `aapt2 dump` rằng resource biên dịch đúng (`ic_launcher_background = #FFFFFF`), nên nguyên nhân
    nhiều khả năng nằm ở cách launcher/OS render adaptive icon (không phải sai resource trong repo).
    Cần điều tra tiếp trên thiết bị thật sạch (chưa qua `pm clear`/cache thử nghiệm) hoặc thử bỏ hẳn
    layer adaptive, chỉ dùng icon flat, để so sánh.

## Build lệnh nhanh

```bash
# chạy debug trên thiết bị/emulator đang kết nối
flutter run

# build APK release (hiện ký bằng debug key, xem TODO ở trên)
flutter build apk --release
```

## Git / Deploy

- Repo: `https://github.com/luudinh93/ueh_student_app.git`, nhánh `main`.
- `.gitignore` đã loại `build/`, `.dart_tool/`, `android/.gradle`, `android/.kotlin`,
  `android/local.properties`, `ios/Pods`, keystore (`*.jks`, `key.properties`), v.v.
  Không commit APK build ra — build lại bằng lệnh ở trên khi cần.
