class NewsItemModel {
  final int uid;
  final int catUid;
  final String categoryName;
  final String title;
  final String shortDesc;
  final String postDate;
  final List<int> sdgs;
  final bool isFeatured;
  final String? backgroundImg;
  final String? thumbnailImg;

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

  // Tương thích ngược với các màn hình cũ
  int get id => uid;
  String get category => categoryName;
  String get date => postDate;
  String get thumbnailUrl => thumbnailImg ?? backgroundImg ?? '';
  List<String> get sdgIcons =>
      sdgs.map((s) => 'assets/images/sdg/vi/sdg-$s.png').toList();
  String get link => '';
  String get contentHtml => '';

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
