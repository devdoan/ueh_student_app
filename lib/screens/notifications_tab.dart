import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/notification_item.dart';
import '../services/notification_service.dart';

// ============================================================================
// 🎤 [THUYẾT MINH: TAB THÔNG BÁO (NOTIFICATIONS TAB)]
// - Đọc và hiển thị danh sách thông báo từ SQLite (notifications_table)
// - Lắng nghe sự kiện thông báo mới từ NotificationService để tự động load lại tức thì
// - Cho phép xem chi tiết trong AlertDialog, tự động đánh dấu đã đọc (is_read = 1)
// - Hỗ trợ vuốt để xóa từng tin hoặc xóa tất cả thông báo
// ============================================================================
class NotificationsTab extends StatefulWidget {
  const NotificationsTab({super.key});

  @override
  State<NotificationsTab> createState() => _NotificationsTabState();
}

class _NotificationsTabState extends State<NotificationsTab> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  List<NotificationItemModel> _notifications = [];
  bool _isLoading = true;

  final Color uehPrimary = const Color(0xFF005F69);
  final Color uehOrange = const Color(0xFFED6B28);

  @override
  void initState() {
    super.initState();
    _loadNotifications();

    // ------------------------------------------------------------------------
    // 🎤 [THUYẾT MINH: LẮNG NGHE THÔNG BÁO MỚI TỰ ĐỘNG REFRESH UI]
    // ------------------------------------------------------------------------
    NotificationService().onNotificationReceived = () {
      if (mounted) {
        _loadNotifications();
      }
    };
  }

  Future<void> _loadNotifications() async {
    final list = await _dbHelper.getNotifications();
    if (mounted) {
      setState(() {
        _notifications = list;
        _isLoading = false;
      });
    }
  }

  // --------------------------------------------------------------------------
  // 🎤 [THUYẾT MINH - XEM CHI TIẾT & CẬP NHẬT TRẠNG THÁI ĐÃ ĐỌC (is_read = 1)]
  // - Khi sinh viên bấm vào 1 thông báo:
  //   1. Kiểm tra nếu chưa đọc (!item.isRead) -> Gọi SQLite cập nhật is_read = 1
  //   2. Gọi lại _loadNotifications() để badge giảm đi và chấm cam biến mất
  //   3. Hiển thị hộp thoại AlertDialog với tiêu đề, ngày nhận và nội dung đầy đủ
  // --------------------------------------------------------------------------
  Future<void> _showNotificationDetail(NotificationItemModel item) async {
    // Đánh dấu đã đọc trong SQLite
    if (!item.isRead && item.id != null) {
      await _dbHelper.markNotificationAsRead(item.id!);
      _loadNotifications();
    }

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.notifications_active, color: uehPrimary),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                item.title,
                style: TextStyle(color: uehPrimary, fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              item.receivedAt,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
            ),
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 12),
            Text(
              item.body.isNotEmpty ? item.body : 'Không có nội dung chi tiết.',
              style: const TextStyle(fontSize: 15, height: 1.4, color: Colors.black87),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Đóng', style: TextStyle(color: uehPrimary, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // --------------------------------------------------------------------------
  // 🎤 [THUYẾT MINH - TÍNH NĂNG XÓA TẤT CẢ LỊCH SỬ THÔNG BÁO]
  // - Mở hộp thoại xác nhận an toàn trước khi xóa
  // - Gọi SQLite clearAllNotifications() dọn sạch bảng notifications_table
  // --------------------------------------------------------------------------
  Future<void> _clearAll() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: const Text('Bạn có chắc chắn muốn xóa toàn bộ lịch sử thông báo không?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Xóa hết', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _dbHelper.clearAllNotifications();
      _loadNotifications();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Center(child: CircularProgressIndicator(color: uehPrimary));
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: RefreshIndicator(
        onRefresh: _loadNotifications,
        color: uehPrimary,
        child: _notifications.isEmpty
            ? CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverFillRemaining(
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.notifications_none_outlined, size: 80, color: Colors.grey.shade400),
                            const SizedBox(height: 16),
                            const Text(
                              'Chưa có thông báo nào',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black54),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Các thông báo điểm danh và tin tức mới từ UEH sẽ xuất hiện ở đây.',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              )
            : Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${_notifications.length} thông báo',
                          style: TextStyle(color: Colors.grey.shade700, fontWeight: FontWeight.w600),
                        ),
                        TextButton.icon(
                          onPressed: _clearAll,
                          icon: const Icon(Icons.delete_sweep, size: 18, color: Colors.redAccent),
                          label: const Text('Xóa tất cả', style: TextStyle(color: Colors.redAccent, fontSize: 13)),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      itemCount: _notifications.length,
                      itemBuilder: (context, index) {
                        final notif = _notifications[index];
                        // 🎤 [THUYẾT MINH - CỬ CHỈ VUỐT ĐỂ XÓA (DISMISSIBLE)]:
                        // "Sử dụng widget Dismissible hỗ trợ thao tác vuốt từ phải sang trái (endToStart).
                        // Khi người dùng vuốt, bản ghi thông báo tương ứng trong SQLite bị xóa ngay lập tức."
                        return Dismissible(
                          key: Key('notif_${notif.id ?? index}'),
                          direction: DismissDirection.endToStart,
                          background: Container(
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 20),
                            color: Colors.red.shade400,
                            child: const Icon(Icons.delete, color: Colors.white),
                          ),
                          onDismissed: (direction) {
                            if (notif.id != null) {
                              _dbHelper.deleteNotification(notif.id!);
                            }
                          },
                          // 🎤 [THUYẾT MINH - PHÂN BIỆT THÔNG BÁO ĐÃ ĐỌC VÀ CHƯA ĐỌC]:
                          // "Thông báo chưa đọc có viền xanh cổ vịt #005F69, icon chuông đang reo và chấm tròn cam UEH.
                          // Khi đã đọc, viền chuyển xám thanh lịch và chấm tròn cam tự động biến mất."
                          child: InkWell(
                            onTap: () => _showNotificationDetail(notif),
                            child: Container(
                              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: notif.isRead ? Colors.grey.shade200 : uehPrimary.withValues(alpha: 0.3),
                                  width: notif.isRead ? 1 : 1.5,
                                ),
                                boxShadow: const [
                                  BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 1)),
                                ],
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  CircleAvatar(
                                    radius: 20,
                                    backgroundColor: notif.isRead
                                        ? Colors.grey.shade200
                                        : uehPrimary.withValues(alpha: 0.1),
                                    child: Icon(
                                      notif.isRead ? Icons.notifications_outlined : Icons.notifications_active,
                                      color: notif.isRead ? Colors.grey : uehPrimary,
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                notif.title,
                                                style: TextStyle(
                                                  fontWeight: notif.isRead ? FontWeight.w600 : FontWeight.bold,
                                                  fontSize: 15,
                                                  color: Colors.black87,
                                                ),
                                              ),
                                            ),
                                            if (!notif.isRead)
                                              Container(
                                                width: 8,
                                                height: 8,
                                                margin: const EdgeInsets.only(left: 6),
                                                decoration: BoxDecoration(
                                                  color: uehOrange,
                                                  shape: BoxShape.circle,
                                                ),
                                              ),
                                          ],
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          notif.body,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(fontSize: 13, color: Colors.grey.shade700, height: 1.3),
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          notif.receivedAt,
                                          style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

