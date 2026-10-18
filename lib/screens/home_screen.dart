import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../models/menu_item.dart';
import '../models/news_item.dart';
import '../services/api_service.dart';
import '../database/database_helper.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'account_tab.dart';
import 'attendance_tab.dart';
import 'notifications_tab.dart';

enum NewsViewMode {
  overview, // Màn hình ngoài: Featured + 4 Category Previews + Nút "Xem thêm"
  category, // Màn hình danh sách theo Category cụ thể
  allNews,  // Màn hình xem tất cả bài viết
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ApiService _apiService = ApiService();
  final DatabaseHelper _dbHelper = DatabaseHelper();

  // Scroll controllers riêng cho từng chế độ xem
  final ScrollController _overviewScrollController = ScrollController();
  final ScrollController _categoryScrollController = ScrollController();
  final ScrollController _allNewsScrollController = ScrollController();

  List<MenuItemModel> _menus = [];
  bool _isLoadingMenu = true;
  int _selectedIndex = 0;
  int _unreadNotificationsCount = 0;

  // Trạng thái hiển thị tin tức
  NewsViewMode _newsViewMode = NewsViewMode.overview;
  int _selectedCatUid = 219;
  String _selectedCategoryName = 'CUỘC SỐNG UEH';

  // Dữ liệu cho màn hình tổng quan (Overview)
  List<NewsItemModel> _featuredNews = [];
  Map<int, NewsItemModel> _categoryPreviews = {};
  bool _isLoadingOverview = true;

  // Dữ liệu cho màn hình xem theo Category
  List<NewsItemModel> _categoryNews = [];
  bool _isLoadingCategoryNews = false;
  bool _hasMoreCategoryNews = true;

  // Dữ liệu cho màn hình xem tất cả bài viết (All News)
  List<NewsItemModel> _allNews = [];
  bool _isLoadingAllNews = false;
  bool _hasMoreAllNews = true;

  // Trạng thái lazyload chung
  bool _isLoadingMore = false;

  // Bảng màu chuẩn UEH
  final Color uehPrimary = const Color(0xFF005F69); // Xanh cổ vịt
  final Color uehOrange = const Color(0xFFED6B28);  // Cam UEH
  final Color uehDarkSlate = const Color(0xFF355E6B); // Xanh đậm hộp tin nổi bật

  // Danh mục cố định theo yêu cầu của thầy
  static const List<Map<String, dynamic>> _officialCategories = [
    {'id': 219, 'name': 'CUỘC SỐNG UEH'},
    {'id': 220, 'name': 'KHOA HỌC – GÓC NHÌN CHUYÊN GIA'},
    {'id': 221, 'name': 'BÁO CHÍ NÓI VỀ UEH'},
    {'id': 222, 'name': 'TUYỂN SINH & HƯỚNG NGHIỆP'},
  ];

  @override
  void initState() {
    super.initState();
    _loadMenus();
    _loadOverviewNews();
    _loadUnreadCount();

    // Bắt sự kiện cuộn lazyload cho màn hình Category
    _categoryScrollController.addListener(() {
      if (_categoryScrollController.position.pixels >=
          _categoryScrollController.position.maxScrollExtent - 250) {
        _loadMoreCategoryNews();
      }
    });

    // Bắt sự kiện cuộn lazyload cho màn hình Tất cả bài viết
    _allNewsScrollController.addListener(() {
      if (_allNewsScrollController.position.pixels >=
          _allNewsScrollController.position.maxScrollExtent - 250) {
        _loadMoreAllNews();
      }
    });
  }

  @override
  void dispose() {
    _overviewScrollController.dispose();
    _categoryScrollController.dispose();
    _allNewsScrollController.dispose();
    super.dispose();
  }

  Future<void> _loadUnreadCount() async {
    try {
      final count = await _dbHelper.getUnreadCount();
      if (mounted) {
        setState(() => _unreadNotificationsCount = count);
      }
    } catch (_) {}
  }

  Future<void> _loadMenus() async {
    // 1. Đọc menu offline từ SQLite trước
    try {
      final localMenus = await _dbHelper.getMenus();
      if (localMenus.isNotEmpty && mounted) {
        setState(() {
          _menus = localMenus;
          _isLoadingMenu = false;
        });
      }
    } catch (_) {}

    // 2. Tải menu từ API và cập nhật SQLite
    try {
      final remoteMenus = await _apiService.fetchMenus();
      if (remoteMenus.isNotEmpty) {
        await _dbHelper.insertMenu(remoteMenus);
        if (mounted) {
          setState(() {
            _menus = remoteMenus;
            _isLoadingMenu = false;
          });
        }
      }
    } catch (e) {
      if (_menus.isEmpty && mounted) {
        setState(() => _isLoadingMenu = false);
      }
    }
  }

  // Tải dữ liệu cho màn hình bên ngoài (Overview)
  Future<void> _loadOverviewNews() async {
    setState(() => _isLoadingOverview = true);
    try {
      final results = await Future.wait([
        _apiService.fetchFeaturedNews(),
        _apiService.fetchCategoryPreviews(),
      ]);

      if (mounted) {
        setState(() {
          _featuredNews = results[0] as List<NewsItemModel>;
          _categoryPreviews = results[1] as Map<int, NewsItemModel>;
          _isLoadingOverview = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingOverview = false);
    }
  }

  // Mở màn hình danh sách bài viết thuộc Category
  void _openCategory(int catUid, String catName) async {
    setState(() {
      _newsViewMode = NewsViewMode.category;
      _selectedCatUid = catUid;
      _selectedCategoryName = catName;
      _categoryNews = [];
      _isLoadingCategoryNews = true;
      _hasMoreCategoryNews = true;
      _isLoadingMore = false;
    });

    try {
      final items = await _apiService.fetchNewsByCategory(catUid, limit: 10, offset: 0);
      if (mounted) {
        setState(() {
          _categoryNews = items;
          _isLoadingCategoryNews = false;
          if (items.length < 10) _hasMoreCategoryNews = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingCategoryNews = false);
    }
  }

  // Tải thêm bài viết cho Category (Lazyload)
  Future<void> _loadMoreCategoryNews() async {
    if (_isLoadingMore || !_hasMoreCategoryNews || _isLoadingCategoryNews) return;

    setState(() => _isLoadingMore = true);

    try {
      final currentOffset = _categoryNews.length;
      final newItems = await _apiService.fetchNewsByCategory(
        _selectedCatUid,
        limit: 10,
        offset: currentOffset,
      );

      if (mounted) {
        setState(() {
          _isLoadingMore = false;
          if (newItems.isEmpty) {
            _hasMoreCategoryNews = false;
          } else {
            final existingIds = _categoryNews.map((e) => e.uid).toSet();
            final uniqueItems = newItems.where((e) => !existingIds.contains(e.uid)).toList();
            if (uniqueItems.isEmpty) {
              _hasMoreCategoryNews = false;
            } else {
              _categoryNews.addAll(uniqueItems);
              if (newItems.length < 10) _hasMoreCategoryNews = false;
            }
          }
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingMore = false);
    }
  }

  // Mở màn hình Tất cả bài viết
  void _openAllNews() async {
    setState(() {
      _newsViewMode = NewsViewMode.allNews;
      _allNews = [];
      _isLoadingAllNews = true;
      _hasMoreAllNews = true;
      _isLoadingMore = false;
    });

    try {
      final items = await _apiService.fetchMoreNews(0, limit: 12);
      if (mounted) {
        setState(() {
          _allNews = items;
          _isLoadingAllNews = false;
          if (items.length < 8) _hasMoreAllNews = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingAllNews = false);
    }
  }

  // Tải thêm cho Tất cả bài viết (Lazyload)
  Future<void> _loadMoreAllNews() async {
    if (_isLoadingMore || !_hasMoreAllNews || _isLoadingAllNews) return;

    setState(() => _isLoadingMore = true);

    try {
      final currentOffset = _allNews.length;
      final newItems = await _apiService.fetchMoreNews(currentOffset, limit: 12);

      if (mounted) {
        setState(() {
          _isLoadingMore = false;
          if (newItems.isEmpty) {
            _hasMoreAllNews = false;
          } else {
            final existingIds = _allNews.map((e) => e.uid).toSet();
            final uniqueItems = newItems.where((e) => !existingIds.contains(e.uid)).toList();
            if (uniqueItems.isEmpty) {
              _hasMoreAllNews = false;
            } else {
              _allNews.addAll(uniqueItems);
            }
          }
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingMore = false);
    }
  }

  Future<void> _refreshCurrentData() async {
    _loadUnreadCount();
    if (_selectedIndex == 0) {
      if (_newsViewMode == NewsViewMode.overview) {
        await Future.wait([_loadMenus(), _loadOverviewNews()]);
      } else if (_newsViewMode == NewsViewMode.category) {
        _openCategory(_selectedCatUid, _selectedCategoryName);
      } else {
        _openAllNews();
      }
    } else {
      await _loadMenus();
    }
  }

  void _onItemTapped(int index) {
    if (index == 0 && _selectedIndex == 0) {
      // Nhấn lại tab Trang chủ -> quay về màn hình ngoài
      if (_newsViewMode != NewsViewMode.overview) {
        setState(() => _newsViewMode = NewsViewMode.overview);
      }
    }
    setState(() => _selectedIndex = index);
    _loadUnreadCount();
  }

  IconData _getMenuIcon(String iconPath) {
    final name = iconPath.toLowerCase();
    if (name.contains('news') || name.contains('báo')) return Icons.article_outlined;
    if (name.contains('calendar') || name.contains('event')) return Icons.calendar_month_outlined;
    if (name.contains('chart') || name.contains('score') || name.contains('điểm')) return Icons.analytics_outlined;
    if (name.contains('face') || name.contains('user') || name.contains('khuôn mặt')) return Icons.face_retouching_natural_outlined;
    if (name.contains('clock') || name.contains('schedule') || name.contains('thời khóa')) return Icons.schedule_outlined;
    if (name.contains('exam') || name.contains('clipboard') || name.contains('lịch thi')) return Icons.assignment_outlined;
    if (name.contains('health') || name.contains('shield') || name.contains('sức khỏe')) return Icons.health_and_safety_outlined;
    if (name.contains('leaf') || name.contains('green') || name.contains('môi trường')) return Icons.eco_outlined;
    if (name.contains('contact') || name.contains('phone') || name.contains('question') || name.contains('liên hệ')) return Icons.contact_support_outlined;
    return Icons.apps;
  }

  Widget _buildDrawer() {
    return Drawer(
      child: Container(
        color: uehPrimary,
        child: SafeArea(
          child: Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 24),
                color: Colors.white,
                child: Center(
                  child: Text(
                    'UEH\nUNIVERSITY',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: uehPrimary,
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      height: 1.0,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: _isLoadingMenu && _menus.isEmpty
                    ? const Center(child: CircularProgressIndicator(color: Colors.white))
                    : ListView.builder(
                        itemCount: _menus.length,
                        itemBuilder: (context, index) {
                          final menu = _menus[index];
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Colors.white24,
                              child: Icon(_getMenuIcon(menu.iconName), color: Colors.white),
                            ),
                            title: Text(
                              menu.menuName,
                              style: const TextStyle(color: Colors.white, fontSize: 16),
                            ),
                            onTap: () {
                              Navigator.pop(context);
                              if (menu.id == 1 || menu.menuName.contains('Tin tức')) {
                                setState(() {
                                  _selectedIndex = 0;
                                  _newsViewMode = NewsViewMode.overview;
                                });
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Tính năng ${menu.menuName} đang phát triển')),
                                );
                              }
                            },
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- COMPONENT: TIN TỨC NỔI BẬT (ẢNH 1) ---
  Widget _buildFeaturedCard(NewsItemModel item) {
    final imageUrl = (item.backgroundImg != null && item.backgroundImg!.isNotEmpty)
        ? item.backgroundImg!
        : (item.thumbnailImg ?? '');

    return InkWell(
      onTap: () => context.push('/news_detail', extra: item),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(4),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 6, offset: const Offset(0, 2)),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (imageUrl.isNotEmpty)
              Image.network(
                imageUrl,
                height: 185,
                fit: BoxFit.cover,
                errorBuilder: (c, e, s) => Container(
                  height: 185,
                  color: Colors.grey.shade300,
                  child: const Icon(Icons.image, size: 50, color: Colors.grey),
                ),
              ),
            Container(
              color: uehDarkSlate,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Text(
                    'TIN TỨC NỔI BẬT',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15.5,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.1,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (item.sdgs.isNotEmpty) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: item.sdgs.map((sdg) => Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 3),
                        child: Image.asset(
                          'assets/images/sdg/vi/sdg-$sdg.png',
                          height: 26,
                          width: 26,
                          errorBuilder: (c, e, s) => const SizedBox(),
                        ),
                      )).toList(),
                    ),
                    const SizedBox(height: 8),
                  ],
                  Text(
                    item.title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      height: 1.35,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- COMPONENT: CARD CATEGORY Ở MÀN HÌNH BÊN NGOÀI (ẢNH 5) ---
  Widget _buildOverviewCategoryCard({
    required int catUid,
    required String catName,
    required NewsItemModel? previewItem,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Dòng chữ màu cam (Category): bấm vào thì vào trang tổng hợp của các bài viết có phân loại đó
          InkWell(
            onTap: () => _openCategory(catUid, catName),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 2.0),
              child: Text(
                catName,
                style: TextStyle(
                  color: uehOrange,
                  fontWeight: FontWeight.bold,
                  fontSize: 14.5,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),

          // 2. Dãy SDG icon nếu có: bấm vào cũng mở thẳng bài viết đó
          if (previewItem != null && previewItem.sdgs.isNotEmpty) ...[
            InkWell(
              onTap: () {
                if (previewItem.title.isNotEmpty) {
                  context.push('/news_detail', extra: previewItem);
                }
              },
              child: Row(
                children: previewItem.sdgs.map((sdg) => Padding(
                  padding: const EdgeInsets.only(right: 5.0),
                  child: Image.asset(
                    'assets/images/sdg/vi/sdg-$sdg.png',
                    height: 25,
                    width: 25,
                    errorBuilder: (c, e, s) => const SizedBox(),
                  ),
                )).toList(),
              ),
            ),
            const SizedBox(height: 8),
          ],

          // 3. Dòng chữ màu xanh (Tiêu đề bài viết): bấm vào thì vào thẳng bài viết đó luôn
          InkWell(
            onTap: () {
              if (previewItem != null && previewItem.title.isNotEmpty) {
                context.push('/news_detail', extra: previewItem);
              }
            },
            child: Text(
              previewItem != null && previewItem.title.isNotEmpty
                  ? previewItem.title
                  : 'Chưa có bài viết mới',
              style: TextStyle(
                fontSize: 15.5,
                fontWeight: FontWeight.bold,
                color: uehPrimary,
                height: 1.3,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  // --- COMPONENT: CARD BÀI VIẾT ĐẦY ĐỦ CHO DANH SÁCH CATEGORY & TẤT CẢ (ẢNH 3 & 4) ---
  Widget _buildFullNewsCard(NewsItemModel item) {
    final thumb = (item.thumbnailImg != null && item.thumbnailImg!.isNotEmpty)
        ? item.thumbnailImg!
        : (item.backgroundImg ?? '');

    return InkWell(
      onTap: () => context.push('/news_detail', extra: item),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Tên Category in hoa màu cam
            Text(
              item.categoryName.isNotEmpty ? item.categoryName.toUpperCase() : _selectedCategoryName,
              style: TextStyle(
                color: uehOrange,
                fontWeight: FontWeight.bold,
                fontSize: 13.5,
              ),
            ),
            const SizedBox(height: 6),
            // Tiêu đề bài viết màu xanh cổ vịt
            Text(
              item.title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: uehPrimary,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 10),
            // Khối bố cục ngang: Ảnh bên trái, SDG + Mô tả tóm tắt bên phải (như Ảnh 3, 4)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (thumb.isNotEmpty)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: Image.network(
                      thumb,
                      width: 110,
                      height: 80,
                      fit: BoxFit.cover,
                      errorBuilder: (c, e, s) => Container(
                        width: 110,
                        height: 80,
                        color: Colors.grey.shade200,
                        child: const Icon(Icons.image, color: Colors.grey),
                      ),
                    ),
                  )
                else
                  Container(
                    width: 110,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Icon(Icons.image, color: Colors.grey),
                  ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (item.sdgs.isNotEmpty) ...[
                        Row(
                          children: item.sdgs.map((sdg) => Padding(
                            padding: const EdgeInsets.only(right: 4.0, bottom: 4.0),
                            child: Image.asset(
                              'assets/images/sdg/vi/sdg-$sdg.png',
                              height: 23,
                              width: 23,
                              errorBuilder: (c, e, s) => const SizedBox(),
                            ),
                          )).toList(),
                        ),
                      ],
                      Text(
                        item.shortDesc,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.black87,
                          height: 1.35,
                        ),
                        maxLines: 4,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // --- BREADCRUMB THANH ĐIỀU HƯỚNG TRANG CHỦ > TÊN MỤC ---
  Widget _buildBreadcrumb(String currentLabel) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: Colors.white,
      child: Row(
        children: [
          InkWell(
            onTap: () {
              setState(() => _newsViewMode = NewsViewMode.overview);
            },
            child: const Text(
              'Trang chủ',
              style: TextStyle(
                color: Colors.black87,
                fontSize: 14.5,
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 6),
            child: Text(
              '❯',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ),
          Expanded(
            child: Text(
              currentLabel,
              style: TextStyle(
                color: uehPrimary,
                fontSize: 14.5,
                fontWeight: FontWeight.bold,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  // --- 1. GIAO DIỆN BÊN NGOÀI CỦA TRANG TIN TỨC (OVERVIEW VIEW) ---
  Widget _buildOverviewView() {
    return RefreshIndicator(
      onRefresh: _refreshCurrentData,
      color: uehOrange,
      child: ListView(
        controller: _overviewScrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          // Tiêu đề "Tin tức" màu cam lớn + phụ đề
          Padding(
            padding: const EdgeInsets.only(top: 20, bottom: 12),
            child: Column(
              children: [
                Text(
                  'Tin tức',
                  style: TextStyle(
                    color: uehOrange,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Thông tin mới nhất và kiến thức hữu ích từ UEH',
                  style: TextStyle(color: Colors.grey, fontSize: 14),
                ),
              ],
            ),
          ),

          if (_isLoadingOverview)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 60.0),
              child: Center(child: CircularProgressIndicator()),
            )
          else ...[
            // 1. Tin tức nổi bật trên cùng
            if (_featuredNews.isNotEmpty)
              _buildFeaturedCard(_featuredNews.first),

            const SizedBox(height: 8),

            // 2. Các Categories theo ID của thầy (219, 220, 221, 222)
            ..._officialCategories.map((cat) {
              final catId = cat['id'] as int;
              final catName = cat['name'] as String;
              final preview = _categoryPreviews[catId];
              return _buildOverviewCategoryCard(
                catUid: catId,
                catName: catName,
                previewItem: preview,
              );
            }),

            const SizedBox(height: 16),

            // 3. Nút "Xem thêm" ở dưới cùng
            Center(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 24.0),
                child: InkWell(
                  onTap: _openAllNews,
                  borderRadius: BorderRadius.circular(4),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEAEAEA),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'Xem thêm',
                      style: TextStyle(
                        color: uehOrange,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // --- 2. GIAO DIỆN DANH SÁCH BÀI VIẾT THEO CATEGORY (LAZYLOAD) ---
  Widget _buildCategoryListView() {
    return Column(
      children: [
        _buildBreadcrumb(_selectedCategoryName),
        const Divider(height: 1),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async {
              _openCategory(_selectedCatUid, _selectedCategoryName);
            },
            color: uehOrange,
            child: _isLoadingCategoryNews && _categoryNews.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    controller: _categoryScrollController,
                    physics: const AlwaysScrollableScrollPhysics(),
                    itemCount: _categoryNews.length + 1,
                    itemBuilder: (context, index) {
                      if (index == _categoryNews.length) {
                        if (_hasMoreCategoryNews) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 20.0),
                            child: Center(
                              child: CircularProgressIndicator(color: uehPrimary),
                            ),
                          );
                        } else {
                          return const Padding(
                            padding: EdgeInsets.symmetric(vertical: 24.0),
                            child: Center(
                              child: Text(
                                'Đã hiển thị tất cả bài viết',
                                style: TextStyle(color: Colors.grey, fontSize: 13),
                              ),
                            ),
                          );
                        }
                      }
                      return _buildFullNewsCard(_categoryNews[index]);
                    },
                  ),
          ),
        ),
      ],
    );
  }

  // --- 3. GIAO DIỆN TẤT CẢ BÀI VIẾT (LAZYLOAD) ---
  Widget _buildAllNewsListView() {
    return Column(
      children: [
        _buildBreadcrumb('Tất cả tin tức'),
        const Divider(height: 1),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async {
              _openAllNews();
            },
            color: uehOrange,
            child: _isLoadingAllNews && _allNews.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    controller: _allNewsScrollController,
                    physics: const AlwaysScrollableScrollPhysics(),
                    itemCount: _allNews.length + 1,
                    itemBuilder: (context, index) {
                      if (index == _allNews.length) {
                        if (_hasMoreAllNews) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 20.0),
                            child: Center(
                              child: CircularProgressIndicator(color: uehPrimary),
                            ),
                          );
                        } else {
                          return const Padding(
                            padding: EdgeInsets.symmetric(vertical: 24.0),
                            child: Center(
                              child: Text(
                                'Đã hiển thị tất cả bài viết',
                                style: TextStyle(color: Colors.grey, fontSize: 13),
                              ),
                            ),
                          );
                        }
                      }
                      return _buildFullNewsCard(_allNews[index]);
                    },
                  ),
          ),
        ),
      ],
    );
  }

  // Chọn view tương ứng cho Tab 0
  Widget _buildNewsTab() {
    switch (_newsViewMode) {
      case NewsViewMode.category:
        return _buildCategoryListView();
      case NewsViewMode.allNews:
        return _buildAllNewsListView();
      case NewsViewMode.overview:
        return _buildOverviewView();
    }
  }

  @override
  Widget build(BuildContext context) {
    String appBarTitle = 'Trang chủ';
    if (_selectedIndex == 1) appBarTitle = 'Thông báo';
    if (_selectedIndex == 2) appBarTitle = 'Điểm danh';
    if (_selectedIndex == 3) appBarTitle = 'Tài khoản';

    return PopScope(
      canPop: _selectedIndex == 0 && _newsViewMode == NewsViewMode.overview,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        // Nếu đang ở màn hình danh mục hoặc tất cả tin tức -> bấm back quay về màn hình ngoài
        if (_newsViewMode != NewsViewMode.overview) {
          setState(() => _newsViewMode = NewsViewMode.overview);
        } else if (_selectedIndex != 0) {
          setState(() => _selectedIndex = 0);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: uehPrimary,
          foregroundColor: Colors.white,
          centerTitle: true,
          elevation: 0,
          title: Text(
            appBarTitle,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          leading: (_selectedIndex == 0 && _newsViewMode != NewsViewMode.overview)
              ? IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  tooltip: 'Quay lại',
                  onPressed: () {
                    setState(() {
                      _newsViewMode = NewsViewMode.overview;
                    });
                  },
                )
              : Builder(
                  builder: (context) => IconButton(
                    icon: const Icon(Icons.menu, color: Colors.white),
                    onPressed: () => Scaffold.of(context).openDrawer(),
                  ),
                ),
          actions: [
            if (_selectedIndex == 3)
              IconButton(
                icon: const Icon(Icons.logout, color: Colors.white),
                tooltip: 'Đăng xuất',
                onPressed: () async {
                  await const FlutterSecureStorage().deleteAll();
                  if (context.mounted) {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => const HomeScreen()),
                    );
                  }
                },
              )
            else
              IconButton(
                icon: const Icon(Icons.refresh, color: Colors.white),
                onPressed: _refreshCurrentData,
              ),
          ],
        ),
        drawer: _buildDrawer(),
        body: IndexedStack(
          index: _selectedIndex,
          children: [
            _buildNewsTab(),
            const NotificationsTab(),
            const AttendanceTab(),
            const AccountTab(),
          ],
        ),
        bottomNavigationBar: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          currentIndex: _selectedIndex,
          selectedItemColor: uehOrange,
          unselectedItemColor: const Color(0xFFB0B0B0),
          onTap: _onItemTapped,
          items: [
            const BottomNavigationBarItem(
              icon: Icon(Icons.home),
              label: 'Trang chủ',
            ),
            BottomNavigationBarItem(
              icon: _unreadNotificationsCount > 0
                  ? Badge(
                      backgroundColor: const Color(0xFFE53935),
                      label: Text(
                        '$_unreadNotificationsCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      child: const Icon(Icons.notifications_none),
                    )
                  : const Icon(Icons.notifications_none),
              activeIcon: _unreadNotificationsCount > 0
                  ? Badge(
                      backgroundColor: const Color(0xFFE53935),
                      label: Text(
                        '$_unreadNotificationsCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      child: const Icon(Icons.notifications),
                    )
                  : const Icon(Icons.notifications),
              label: 'Thông báo',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.check_circle_outline),
              activeIcon: Icon(Icons.check_circle),
              label: 'Điểm danh',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: 'Tài khoản',
            ),
          ],
        ),
      ),
    );
  }
}
