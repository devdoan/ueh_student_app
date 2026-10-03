import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as html_parser;
import '../models/menu_item.dart';
import '../models/news_item.dart';

class ApiService {
  Future<List<MenuItemModel>> fetchMenus() async {
    // Đây là Mock API (Dữ liệu giả lập) cho Menu. 
    // Trong thực tế, bạn sẽ thay List này bằng http.get(url_menu_api_cua_truong)
    return [
      MenuItemModel(id: 1, title: 'Tin tức UEH', route: '/news', iconPath: 'news'),
      MenuItemModel(id: 2, title: 'Sự kiện UEH', route: '/events', iconPath: 'events'),
      MenuItemModel(id: 3, title: 'Xem điểm', route: '/scores', iconPath: 'scores'),
      MenuItemModel(id: 4, title: 'Định danh khuôn mặt', route: '/face', iconPath: 'face'),
      MenuItemModel(id: 5, title: 'Thời khóa biểu', route: '/schedule', iconPath: 'schedule'),
      MenuItemModel(id: 6, title: 'Lịch thi', route: '/exams', iconPath: 'exams'),
      MenuItemModel(id: 7, title: 'Chăm sóc sức khỏe', route: '/health', iconPath: 'health'),
      MenuItemModel(id: 8, title: 'UEH Go Green Station', route: '/green', iconPath: 'green'),
      MenuItemModel(id: 9, title: 'Liên hệ trực tiếp UEH', route: '/contact', iconPath: 'contact'),
    ];
  }

  Future<List<NewsItemModel>> fetchNews(int page) async {
    final uehPage = page + 1;
    final url = 'https://ueh.edu.vn/tin-tuc?app=true&page=$uehPage';
    
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode != 200) return [];
      
      final document = html_parser.parse(response.body);
      final articles = document.querySelectorAll('article.list-item');
      
      List<NewsItemModel> items = [];
      int index = 0;
      
      for (var article in articles) {
        final catElement = article.querySelector('h3 a[style*="#f56d1f"]');
        final category = catElement?.text.trim() ?? 'TIN TỨC';
        
        final titleElement = article.querySelector('h3:not([style*="16px"]) a');
        final title = titleElement?.text.trim() ?? 'Không có tiêu đề';
        String link = titleElement?.attributes['href'] ?? '';
        if (link.startsWith('/')) {
          link = 'https://ueh.edu.vn$link';
        }
        
        final sdgElements = article.querySelectorAll('img.category-icon');
        List<String> sdgIcons = [];
        for (var e in sdgElements) {
          String src = e.attributes['src'] ?? '';
          if (src.startsWith('/images/sdg/')) {
            sdgIcons.add('assets$src');
          }
        }
        
        final imgElement = article.querySelector('.card-photo img');
        String thumbnailUrl = '';
        if (imgElement != null) {
          thumbnailUrl = imgElement.attributes['src'] ?? '';
          if (thumbnailUrl.startsWith('/')) {
            thumbnailUrl = 'https://ueh.edu.vn$thumbnailUrl';
          }
        }
        
        bool isFeatured = (page == 0 && index == 0);
        
        items.add(
          NewsItemModel(
            id: index + (page * 10),
            category: category,
            title: title,
            date: '',
            thumbnailUrl: thumbnailUrl,
            sdgIcons: sdgIcons,
            contentHtml: '',
            link: link,
            isFeatured: isFeatured,
          )
        );
        index++;
      }
      
      return items;
    } catch (e) {
      return [];
    }
  }

  Future<String> fetchNewsDetail(String link) async {
    if (link.isEmpty) return '<p>Đường dẫn bài viết không hợp lệ.</p>';
    try {
      final response = await http.get(Uri.parse(link));
      if (response.statusCode != 200) return '<p>Lỗi kết nối máy chủ.</p>';
      
      final document = html_parser.parse(response.body);
      final contentDiv = document.querySelector('#news_content');
      
      return contentDiv?.outerHtml ?? '<p>Không tìm thấy nội dung bài viết.</p>';
    } catch (e) {
      return '<p>Đã xảy ra lỗi khi tải bài viết: $e</p>';
    }
  }
}
