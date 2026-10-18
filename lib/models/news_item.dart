// ============================================================================
// 🎤 [THUYẾT MINH - MODEL BÀI VIẾT TIN TỨC]:
// "Dạ thưa thầy, model NewsItemModel đại diện cho một bài viết tin tức lấy từ API.
// Model này chứa đầy đủ thông tin: ID bài viết (uid), danh mục (catUid, categoryName),
// tiêu đề, mô tả ngắn, ngày đăng, hình ảnh thumbnail/banner, và đặc biệt là
// danh sách các mục tiêu phát triển bền vững (SDGs) của UEH."
// ============================================================================

class NewsItemModel {
  final int uid;                // ID định danh duy nhất của bài viết trên hệ thống
  final int catUid;             // Mã danh mục (ví dụ: 219: Đào tạo, 220: NCKH, 221: HTQT, 222: Đời sống SV)
  final String categoryName;    // Tên danh mục hiển thị
  final String title;           // Tiêu đề bài viết
  final String shortDesc;       // Tóm tắt ngắn nội dung bài viết
  final String postDate;        // Ngày đăng bài
  final List<int> sdgs;         // Danh sách ID các mục tiêu SDG (Sustainable Development Goals)
  final bool isFeatured;        // Đánh dấu bài viết nổi bật (banner)
  final String? backgroundImg;  // Ảnh bìa kích thước lớn
  final String? thumbnailImg;   // Ảnh đại diện nhỏ

  NewsItemModel({
    required this.uid,
    required this.catUid,
    required this.categoryName,
    required this.title,
    required this.shortDesc,
    required this.postDate,
    required this.sdgs,
    required this.isFeatured,
    this.backgroundImg,
    this.thumbnailImg,
  });

  // 🎤 [THUYẾT MINH - GETTER TIỆN ÍCH]:
  // "Các getter giúp tái sử dụng mã nguồn và map các mục tiêu SDG thành đường dẫn asset ảnh tương ứng."
  int get id => uid;
  String get category => categoryName;
  String get date => postDate;
  String get thumbnailUrl => thumbnailImg ?? backgroundImg ?? '';

  // 🎤 [THUYẾT MINH - HIỂN THỊ ICON SDG]:
  // "Tự động chuyển đổi mảng số [4, 8, 17] thành đường dẫn hình ảnh SDG trong assets/images/sdg/vi/
  // để hiển thị trực quan các mục tiêu phát triển bền vững của UEH."
  List<String> get sdgIcons =>
      sdgs.map((s) => 'assets/images/sdg/vi/sdg-$s.png').toList();
  String get link => '';
  String get contentHtml => '';

  // 🎤 [THUYẾT MINH - DESERIALIZATION TỪ API]:
  // "Hàm fromJson bóc tách dữ liệu từ JSON API của thầy.
  // Em xử lý kỹ các trường hợp rỗng, chuỗi thừa (trim) và chuyển đổi mảng dynamic sang List<int>."
  factory NewsItemModel.fromJson(Map<String, dynamic> json) {
    return NewsItemModel(
      uid: json['uid'] ?? json['id'] ?? 0,
      catUid: json['cat_uid'] ?? 0,
      categoryName: json['category_name'] ?? json['category'] ?? '',
      title: (json['title'] ?? '').toString().trim(),
      shortDesc: (json['short_desc'] ?? '').toString().trim(),
      postDate: json['post_date'] ?? json['date'] ?? '',
      sdgs: json['sdgs'] != null
          ? (json['sdgs'] as List<dynamic>).map((e) => (e as num).toInt()).toList()
          : [],
      isFeatured: json['is_featured'] ?? json['isFeatured'] ?? false,
      backgroundImg: json['background_img'],
      thumbnailImg: json['thumbnail_img'],
    );
  }
}

