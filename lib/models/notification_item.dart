class NotificationItemModel {
  final int? id;
  final String title;
  final String body;
  final String receivedAt;
  final bool isRead;
  final String? data;

  NotificationItemModel({
    this.id,
    required this.title,
    required this.body,
    required this.receivedAt,
    this.isRead = false,
    this.data,
  });

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

