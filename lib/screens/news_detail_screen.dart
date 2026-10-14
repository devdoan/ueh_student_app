import 'package:flutter/material.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import '../models/news_item.dart';
import '../services/api_service.dart';

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
