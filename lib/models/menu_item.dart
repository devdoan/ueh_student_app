// ============================================================================
// 🎤 [THUYẾT MINH - MODEL MENU ITEM]:
// "Dạ thưa thầy, model MenuItemModel đại diện cho cấu trúc dữ liệu của các mục menu
// được lấy động từ API của nhà trường (/v1/menu).
// Model này được thiết kế để vừa parse dữ liệu từ JSON server trả về, vừa có khả năng
// chuyển đổi qua lại với SQLite (toMap và fromMap) nhằm hỗ trợ cơ chế lưu trữ
// ngoại tuyến (offline caching) khi thiết bị mất mạng."
// ============================================================================

class MenuItemModel {
  final int id;
  final String iconName; // Tên icon từ server (ví dụ: 'ic_news', 'ic_attendance')
  final String menuName; // Tên hiển thị của menu (ví dụ: 'Tin tức', 'Điểm danh')
  final String menuUrl;  // Đường dẫn hoặc route tương ứng
  final int ordering;    // Thứ tự sắp xếp hiển thị trên giao diện

  MenuItemModel({
    required this.id,
    required this.iconName,
    required this.menuName,
    required this.menuUrl,
    required this.ordering,
  });

  // 🎤 [THUYẾT MINH - TƯƠNG THÍCH NGƯỢC]:
  // "Các getter tiện ích giúp tương thích với mã nguồn cũ và dễ gọi trong UI code."
  String get title => menuName;
  String get iconPath => iconName;
  String get route => menuUrl;

  // 🎤 [THUYẾT MINH - DESERIALIZATION TỪ API]:
  // "Factory constructor fromJson ánh xạ dữ liệu JSON từ API endpoint /v1/menu vào Model.
  // Em sử dụng fallback kiểm tra cả định dạng snake_case và camelCase để tránh lỗi null."
  factory MenuItemModel.fromJson(Map<String, dynamic> json) {
    return MenuItemModel(
      id: json['id'] ?? 0,
      iconName: json['icon_name'] ?? json['iconPath'] ?? '',
      menuName: json['menu_name'] ?? json['title'] ?? '',
      menuUrl: json['menu_url'] ?? json['route'] ?? '',
      ordering: json['ordering'] ?? 0,
    );
  }

  // 🎤 [THUYẾT MINH - SERIALIZATION CHO SQLITE]:
  // "Hàm toMap chuyển đổi đối tượng thành dạng Map<String, dynamic> tương thích
  // hoàn toàn với cấu trúc bảng SQLite 'menu_table' để lưu cache offline."
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'icon_name': iconName,
      'menu_name': menuName,
      'menu_url': menuUrl,
      'ordering': ordering,
    };
  }

  // 🎤 [THUYẾT MINH - KHÔI PHỤC TỪ SQLITE KHI MẤT MẠNG]:
  // "Factory constructor fromMap đọc các dòng dữ liệu truy vấn từ SQLite DatabaseHelper
  // và tái tạo lại danh sách MenuItemModel khi người dùng mở ứng dụng trong chế độ offline."
  factory MenuItemModel.fromMap(Map<String, dynamic> map) {
    return MenuItemModel(
      id: map['id'] ?? 0,
      iconName: map['icon_name'] ?? map['iconPath'] ?? '',
      menuName: map['menu_name'] ?? map['title'] ?? '',
      menuUrl: map['menu_url'] ?? map['route'] ?? '',
      ordering: map['ordering'] ?? 0,
    );
  }
}

