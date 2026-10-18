import 'package:flutter/material.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import '../models/news_item.dart';
import '../services/api_service.dart';

// ============================================================================
// 🎤 [THUYẾT MINH: MÀN HÌNH CHI TIẾT TIN TỨC (NEWS DETAIL SCREEN)]
// "Dạ thưa thầy, màn hình này hiển thị toàn bộ nội dung bài viết định dạng HTML
// lấy từ API GET /v1/news/{uid}.
// - Sử dụng thư viện flutter_widget_from_html để render sinh động hình ảnh, đoạn văn,
//   bảng biểu và liên kết trực tiếp từ mã nguồn HTML.
// - Dữ liệu được giải mã UTF-8 tiếng Việt chuẩn xác qua utf8.decode(response.bodyBytes).
// - Nút quay lại (Back arrow <) ở AppBar cho phép trở về danh sách bài viết mượt mà."
// ============================================================================
class NewsDetailScreen extends StatefulWidget {
  final NewsItemModel newsItem;

  const NewsDetailScreen({super.key, required this.newsItem});

  @override
  State<NewsDetailScreen> createState() => _NewsDetailScreenState();
}

class _NewsDetailScreenState extends State<NewsDetailScreen> {
  final ApiService _apiService = ApiService();
  String? _htmlContent;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDetail();
  }

  // --------------------------------------------------------------------------
  // 🎤 [THUYẾT MINH - GỌI API LẤY NỘI DUNG HTML BÀI VIẾT]:
  // "Gọi hàm fetchNewsDetail với uid bài viết. Khi nhận được nội dung HTML,
  // setState cập nhật _htmlContent và tắt cờ _isLoading để hiển thị bài viết."
  // --------------------------------------------------------------------------
  Future<void> _loadDetail() async {
    final content = await _apiService.fetchNewsDetail(widget.newsItem.uid);
    if (mounted) {
      setState(() {
        _htmlContent = content;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chi tiết tin tức'),
        backgroundColor: const Color(0xFF005F69),
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          tooltip: 'Quay lại',
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.newsItem.categoryName.isNotEmpty) ...[
              Text(
                widget.newsItem.categoryName.toUpperCase(),
                style: const TextStyle(
                  color: Color(0xFFED6B28),
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 8),
            ],
            Text(
              widget.newsItem.title,
              style: const TextStyle(
                fontSize: 20, 
                fontWeight: FontWeight.bold, 
                color: Color(0xFF005F69),
                height: 1.3,
              ),
            ),
            if (widget.newsItem.postDate.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                widget.newsItem.postDate.replaceFirst('T', ' '),
                style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
              ),
            ],
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 12),
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 40.0),
                child: Center(child: CircularProgressIndicator(color: Color(0xFF005F69))),
              )
            else
              // 🎤 [THUYẾT MINH - HIỂN THỊ NỘI DUNG HTML PHONG PHÚ]:
              // "Widget HtmlWidget xử lý các thẻ <img>, <p>, <a>, <strong> trong HTML
              // và dàn trang đẹp mắt, tương thích hoàn toàn với nội dung biên tập từ CMS trường."
              HtmlWidget(
                _htmlContent ?? '',
                textStyle: const TextStyle(
                  fontSize: 16.0,
                  height: 1.5,
                  color: Colors.black87,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
