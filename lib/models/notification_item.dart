// ============================================================================
// 🎤 [THUYẾT MINH - MODEL THÔNG BÁO]:
// "Dạ thưa thầy, model NotificationItemModel quản lý các bản ghi thông báo push
// nhận được từ Firebase Cloud Messaging (FCM).
// Vì thông báo cần được lưu trữ lâu dài trên thiết bị để sinh viên xem lại bất cứ lúc nào,
// model này được ánh xạ trực tiếp với bảng SQLite 'notifications_table'."
// ============================================================================

class NotificationItemModel {
  final int? id;            // Khóa chính tự tăng (PRIMARY KEY AUTOINCREMENT) trong SQLite
  final String title;       // Tiêu đề thông báo từ FCM
  final String body;        // Nội dung chi tiết thông báo
  final String receivedAt;  // Thời gian nhận thông báo (ISO string / định dạng ngày giờ)
  final bool isRead;        // Trạng thái đã đọc (true/false, lưu dưới dạng 1/0 trong SQLite)
  final String? data;       // Dữ liệu payload bổ sung kèm theo FCM message

  NotificationItemModel({
    this.id,
    required this.title,
    required this.body,
    required this.receivedAt,
    this.isRead = false,
    this.data,
  });

  // 🎤 [THUYẾT MINH - SERIALIZATION CHO SQLITE]:
  // "Hàm toMap chuyển đổi đối tượng thông báo thành bản đồ key-value để chèn (INSERT)
  // hoặc cập nhật (UPDATE) vào bảng SQLite. Trường isRead boolean được chuyển thành 1 hoặc 0."
  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'title': title,
      'body': body,
      'received_at': receivedAt,
      'is_read': isRead ? 1 : 0,
      'data': data,
    };
    if (id != null) {
      map['id'] = id;
    }
    return map;
  }

  // 🎤 [THUYẾT MINH - KHÔI PHỤC TỪ CƠ SỞ DỮ LIỆU SQLITE]:
  // "Factory constructor fromMap đọc kết quả truy vấn từ SQLite DatabaseHelper,
  // tái tạo đối tượng NotificationItemModel và chuyển đổi cột is_read kiểu int (1/0) thành bool."
  factory NotificationItemModel.fromMap(Map<String, dynamic> map) {
    return NotificationItemModel(
      id: map['id'] as int?,
      title: map['title'] ?? '',
      body: map['body'] ?? '',
      receivedAt: map['received_at'] ?? '',
      isRead: (map['is_read'] as int? ?? 0) == 1,
      data: map['data'] as String?,
    );
  }
}


