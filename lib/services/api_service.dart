import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/menu_item.dart';
import '../models/news_item.dart';

// ============================================================================
// 🎤 [THUYẾT MINH: TẦNG DỊCH VỤ API (API SERVICE)]
// - Chịu trách nhiệm kết nối RESTful API với server trường (api.ngoisaoviet.info)
// - Quản lý Access Token & Refresh Token bằng FlutterSecureStorage
// - Tự động Refresh Token khi gặp mã lỗi 401 Unauthorized
// - Xử lý tiếng Việt chuẩn xác bằng utf8.decode(response.bodyBytes)
// ============================================================================
class ApiService {
  static const String baseUrl = 'https://api.ngoisaoviet.info';
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  // --------------------------------------------------------------------------
  // 🎤 [THUYẾT MINH - TÍNH NĂNG 1: ĐĂNG NHẬP HỆ THỐNG]
  // - Gọi POST /api/login truyền MSSV & Mật khẩu
  // - Nhận về Token và Refresh Token, lưu trữ bảo mật trong FlutterSecureStorage
  // --------------------------------------------------------------------------
  Future<Map<String, dynamic>> login(String mssv, String matKhau) async {
    final url = '$baseUrl/api/login';
    final response = await http.post(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'mssv': mssv, 'mat_khau': matKhau}),
    );

    final data = jsonDecode(response.body);
    if (response.statusCode == 200) {
      if (data['token'] != null) {
        await _storage.write(key: 'token', value: data['token']);
      }
      if (data['refresh_token'] != null) {
        await _storage.write(key: 'refresh_token', value: data['refresh_token']);
      }
      return data;
    } else {
      throw Exception(data['message'] ?? 'Đăng nhập thất bại');
    }
  }

  // --------------------------------------------------------------------------
  // 🎤 [THUYẾT MINH - TÍNH NĂNG 2: TỰ ĐỘNG REFRESH TOKEN KHI HẾT HẠN]
  // - Khi Token hết hạn, gọi POST /api/refresh-token với refresh_token đã lưu
  // - Giúp phiên đăng nhập duy trì liên tục mà không bắt người dùng đăng nhập lại
  // --------------------------------------------------------------------------
  Future<bool> refreshToken() async {
    try {
      final currentRefreshToken = await _storage.read(key: 'refresh_token');
      if (currentRefreshToken == null || currentRefreshToken.isEmpty) {
        return false;
      }

      final url = '$baseUrl/api/refresh-token';
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'refresh_token': currentRefreshToken}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['token'] != null) {
          await _storage.write(key: 'token', value: data['token']);
        }
        if (data['refresh_token'] != null) {
          await _storage.write(key: 'refresh_token', value: data['refresh_token']);
        }
        return true;
      } else {
        // Refresh token không hợp lệ hoặc đã hết hạn -> Thu hồi & yêu cầu đăng nhập lại
        await _storage.delete(key: 'token');
        await _storage.delete(key: 'refresh_token');
        return false;
      }
    } catch (e) {
      return false;
    }
  }

  // Helper thực hiện request cần Authorization, tự động refresh 1 lần nếu gặp 401
  Future<http.Response> _authenticatedRequest(
    String method,
    String path, {
    Map<String, dynamic>? body,
    String? tokenOverride,
    bool retry = true,
  }) async {
    String? token = tokenOverride ?? await _storage.read(key: 'token');

    final uri = Uri.parse('$baseUrl$path');
    final headers = {
      'Content-Type': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };

    http.Response response;
    if (method.toUpperCase() == 'POST') {
      response = await http.post(uri, headers: headers, body: body != null ? jsonEncode(body) : null);
    } else {
      response = await http.get(uri, headers: headers);
    }

    // Nếu gặp 401 (token hết hạn) và còn quyền retry -> thử refresh token
    if (response.statusCode == 401 && retry) {
      final success = await refreshToken();
      if (success) {
        return _authenticatedRequest(method, path, body: body, retry: false);
      }
    }

    return response;
  }

  // --------------------------------------------------------------------------
  // 🎤 [THUYẾT MINH - TÍNH NĂNG 3: LẤY THÔNG TIN SINH VIÊN]
  // - Gọi GET /api/student-info có Bearer Token để lấy hồ sơ cá nhân
  // --------------------------------------------------------------------------
  Future<Map<String, dynamic>> getStudentInfo([String? token]) async {
    final response = await _authenticatedRequest('GET', '/api/student-info', tokenOverride: token);

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      try {
        final data = jsonDecode(response.body);
        throw Exception(data['message'] ?? 'Không thể tải thông tin sinh viên');
      } catch (_) {
        throw Exception('Không thể tải thông tin sinh viên (Mã lỗi: ${response.statusCode})');
      }
    }
  }

  // --------------------------------------------------------------------------
  // 🎤 [THUYẾT MINH - TÍNH NĂNG 4: ĐIỂM DANH GPS & QR CODE]
  // - Gửi tọa độ GPS (latitude, longitude) và mã QR Code lên POST /api/attendance
  // - Server kiểm tra khoảng cách < 200m so với phòng học và xác nhận điểm danh
  // --------------------------------------------------------------------------
  Future<Map<String, dynamic>> postAttendance(String token, String code, double lat, double lng) async {
    final response = await _authenticatedRequest(
      'POST',
      '/api/attendance',
      tokenOverride: token,
      body: {
        'code': code,
        'latitude': lat,
        'longitude': lng,
      },
    );

    final data = jsonDecode(response.body);
    if (response.statusCode == 200) {
      return data;
    } else {
      throw Exception(data['message'] ?? 'Điểm danh thất bại');
    }
  }

  // --------------------------------------------------------------------------
  // 🎤 [THUYẾT MINH - TÍNH NĂNG 5: TẢI MENU DRAWER TỪ API]
  // - Gọi GET /api/menu để lấy danh sách chức năng từ server
  // - Dữ liệu sau đó được DatabaseHelper lưu vào SQLite để xem offline
  // --------------------------------------------------------------------------
  Future<List<MenuItemModel>> fetchMenus([String? token]) async {
    try {
      final response = await _authenticatedRequest('GET', '/api/menu', tokenOverride: token);
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((item) => MenuItemModel.fromJson(item)).toList();
      }
    } catch (_) {}
    return getDefaultMenus();
  }

  // Menu dự phòng khi chưa đăng nhập hoặc mất mạng
  static List<MenuItemModel> getDefaultMenus() {
    return [
      MenuItemModel(id: 1, iconName: 'newspaper', menuName: 'Tin tức UEH', menuUrl: 'https://ueh.edu.vn/tintucmobile', ordering: 0),
      MenuItemModel(id: 2, iconName: 'calendarDays', menuName: 'Sự kiện UEH', menuUrl: '', ordering: 1),
      MenuItemModel(id: 3, iconName: 'chartLine', menuName: 'Xem điểm', menuUrl: '', ordering: 2),
      MenuItemModel(id: 4, iconName: 'face', menuName: 'Định danh khuôn mặt', menuUrl: '', ordering: 3),
      MenuItemModel(id: 5, iconName: 'clock', menuName: 'Thời khóa biểu', menuUrl: '', ordering: 4),
      MenuItemModel(id: 6, iconName: 'clipboardList', menuName: 'Lịch thi', menuUrl: '', ordering: 5),
      MenuItemModel(id: 7, iconName: 'shieldHeart', menuName: 'Chăm sóc sức khỏe', menuUrl: '', ordering: 6),
      MenuItemModel(id: 8, iconName: 'leaf', menuName: 'UEH Go Green Station', menuUrl: '', ordering: 7),
      MenuItemModel(id: 9, iconName: 'circleQuestion', menuName: 'Liên hệ trực tiếp UEH', menuUrl: '', ordering: 8),
    ];
  }

  // --------------------------------------------------------------------------
  // 🎤 [THUYẾT MINH - TÍNH NĂNG 6: TIN TỨC NỔI BẬT]
  // - Gọi GET /api/news/featured, giải mã UTF-8 tiếng Việt
  // - Trả về bài viết có background_img hiển thị ở đầu trang
  // --------------------------------------------------------------------------
  Future<List<NewsItemModel>> fetchFeaturedNews() async {
    final url = '$baseUrl/api/news/featured';
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(utf8.decode(response.bodyBytes));
        return data.map((json) => NewsItemModel.fromJson(json)).toList();
      }
    } catch (e) {
      // Bỏ qua lỗi kết nối
    }
    return [];
  }

  // --------------------------------------------------------------------------
  // 🎤 [THUYẾT MINH - TÍNH NĂNG 7: BÀI VIẾT XEM TRƯỚC 4 CATEGORY]
  // - Lấy bài viết mới nhất của 4 ID thầy giao: 219, 220, 221, 222
  // - Sử dụng Future.wait để gọi đồng thời 4 API, tối ưu tốc độ tải trang
  // --------------------------------------------------------------------------
  Future<Map<int, NewsItemModel>> fetchCategoryPreviews() async {
    final Map<int, NewsItemModel> previews = {};
    final categoryIds = [219, 220, 221, 222];

    try {
      final futures = categoryIds.map((id) => fetchNewsByCategory(id, limit: 1, offset: 0));
      final responses = await Future.wait(futures);

      for (int i = 0; i < categoryIds.length; i++) {
        if (responses[i].isNotEmpty) {
          previews[categoryIds[i]] = responses[i].first;
        }
      }
    } catch (_) {}

    return previews;
  }

  // --------------------------------------------------------------------------
  // 🎤 [THUYẾT MINH - TÍNH NĂNG 8: TIN TỨC THEO CHUYÊN MỤC & PHÂN TRANG]
  // - Gọi GET /api/news?cat_uid={id}&limit={limit}&offset={offset}
  // - Phục vụ trực tiếp cho tính năng LAZYLOAD khi cuộn trang
  // --------------------------------------------------------------------------
  Future<List<NewsItemModel>> fetchNewsByCategory(int catUid, {int limit = 10, int offset = 0}) async {
    final url = '$baseUrl/api/news?cat_uid=$catUid&limit=$limit&offset=$offset';
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(utf8.decode(response.bodyBytes));
        final List<dynamic> items = data['items'] ?? [];
        return items.map((json) => NewsItemModel.fromJson(json)).toList();
      }
    } catch (e) {
      // Bỏ qua lỗi kết nối
    }
    return [];
  }

  // --------------------------------------------------------------------------
  // 🎤 [THUYẾT MINH - TÍNH NĂNG 9: LAZYLOAD TỔNG HỢP TẤT CẢ BÀI VIẾT]
  // - Tải thêm bài viết từ cả 4 chuyên mục theo phân trang offset
  // - Sắp xếp bài viết mới nhất theo ngày đăng (postDate)
  // --------------------------------------------------------------------------
  Future<List<NewsItemModel>> fetchMoreNews(int offset, {int limit = 8}) async {
    List<NewsItemModel> results = [];
    final categories = [219, 220, 221, 222];
    final limitPerCat = (limit / categories.length).ceil();
    final catOffset = (offset / categories.length).floor();

    try {
      final responses = await Future.wait(
        categories.map((cat) => fetchNewsByCategory(cat, limit: limitPerCat, offset: catOffset)),
      );

      for (var list in responses) {
        results.addAll(list);
      }

      results.sort((a, b) => b.postDate.compareTo(a.postDate));
    } catch (_) {}

    return results;
  }

  // --------------------------------------------------------------------------
  // 🎤 [THUYẾT MINH - TÍNH NĂNG 10: CHI TIẾT TIN TỨC HTML]
  // - Gọi GET /api/news/{uid} để lấy toàn bộ nội dung HTML bài viết
  // - Giải mã utf8.decode để không bị lỗi dấu tiếng Việt
  // --------------------------------------------------------------------------
  Future<String> fetchNewsDetail(dynamic idOrLink) async {
    int? uid;
    if (idOrLink is int) {
      uid = idOrLink;
    } else if (idOrLink is String) {
      uid = int.tryParse(idOrLink);
    }

    if (uid != null) {
      final url = '$baseUrl/api/news/$uid';
      try {
        final response = await http.get(Uri.parse(url));
        if (response.statusCode == 200) {
          final data = jsonDecode(utf8.decode(response.bodyBytes));
          return data['content'] ?? '<p>Bài viết chưa có nội dung.</p>';
        } else {
          return '<p>Không tìm thấy tin tức.</p>';
        }
      } catch (e) {
        return '<p>Đã xảy ra lỗi khi tải bài viết: $e</p>';
      }
    }

    return '<p>Không tìm thấy bài viết.</p>';
  }
}
