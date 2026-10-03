class NewsItemModel {
  final int id;
  final String category;
  final String title;
  final String date;
  final String thumbnailUrl;
  final List<String> sdgIcons;
  final String contentHtml;
  final String link;
  final bool isFeatured;

  NewsItemModel({
    required this.id,
    required this.category,
    required this.title,
    required this.date,
    required this.thumbnailUrl,
    required this.sdgIcons,
    required this.contentHtml,
    this.link = '',
    this.isFeatured = false,
  });

  factory NewsItemModel.fromJson(Map<String, dynamic> json) {
    return NewsItemModel(
      id: json['id'] ?? 0,
      category: json['category'] ?? '',
      title: json['title'] ?? '',
      date: json['date'] ?? '',
      thumbnailUrl: json['thumbnailUrl'] ?? '',
      sdgIcons: List<String>.from(json['sdgIcons'] ?? []),
      contentHtml: json['contentHtml'] ?? '',
      link: json['link'] ?? '',
      isFeatured: json['isFeatured'] ?? false,
    );
  }
}
