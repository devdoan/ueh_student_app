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

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ApiService _apiService = ApiService();
  final DatabaseHelper _dbHelper = DatabaseHelper();
  final ScrollController _scrollController = ScrollController();
  
  List<MenuItemModel> _menus = [];
  List<NewsItemModel> _news = [];
  
  bool _isLoadingMenu = true;
  bool _isLoadingNews = false;
  bool _isLoadingMore = false;
  bool _hasMoreNews = true;
  int _offset = 0;
  int _selectedIndex = 0;

  final Color uehPrimary = const Color(0xFF005F69);
  final Color uehOrange = const Color(0xFFED6B28);

  @override
  void initState() {
    super.initState();
    _loadMenus();
    _loadNews();

    _scrollController.addListener(() {
      if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 250) {
        _loadMoreNews();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadMenus() async {
    // 1. Đọc menu offline từ SQLite trước
    try {
      final localMenus = await _dbHelper.getMenus();
      if (localMenus.isNotEmpty) {
        setState(() {
          _menus = localMenus;
          _isLoadingMenu = false;
        });
      }
    } catch (_) {}

    // 2. Tải menu mới nhất từ API và cập nhật vào SQLite
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

  Future<void> _loadNews() async {
    if (_isLoadingNews) return;

    setState(() {
      _isLoadingNews = true;
      _offset = 0;
      _hasMoreNews = true;
    });

    try {
      final items = await _apiService.fetchFeaturedNews();
      if (mounted) {
        setState(() {
          _news = items;
          _isLoadingNews = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingNews = false);
      }
    }
  }

  Future<void> _loadMoreNews() async {
    if (_isLoadingMore || !_hasMoreNews || _isLoadingNews) return;

    setState(() => _isLoadingMore = true);

    try {
      final nextOffset = _offset + 4;
      final newItems = await _apiService.fetchMoreNews(nextOffset, limit: 12);
      if (mounted) {
        setState(() {
          _isLoadingMore = false;
          if (newItems.isEmpty) {
            _hasMoreNews = false;
          } else {
            final existingUids = _news.map((n) => n.uid).toSet();
            final uniqueItems = newItems.where((n) => !existingUids.contains(n.uid)).toList();
            if (uniqueItems.isEmpty) {
              _hasMoreNews = false;
            } else {
              _news.addAll(uniqueItems);
              _offset = nextOffset;
            }
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingMore = false);
      }
    }
  }

  Future<void> _refreshData() async {
    setState(() {
      _isLoadingMenu = true;
      _isLoadingNews = true;
      _offset = 0;
      _hasMoreNews = true;
    });
    await Future.wait([_loadMenus(), _loadNews()]);
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
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
                padding: const EdgeInsets.symmetric(vertical: 20),
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
                                setState(() { _selectedIndex = 0; });
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Tính năng ${menu.menuName} đang phát triển'))
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

  Widget _buildFeaturedNews(NewsItemModel item) {
    // Thầy dặn: "Có mỗi ảnh tin tức nổi bật trên cùng ở đầu là dùng ảnh background thôi nhé! còn lại dùng ảnh thumbnail hết"
    final imageUrl = (item.backgroundImg != null && item.backgroundImg!.isNotEmpty)
        ? item.backgroundImg!
        : (item.thumbnailImg ?? '');

    return InkWell(
      onTap: () => context.push('/news_detail', extra: item),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(4),
          boxShadow: const [
            BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 2)),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (imageUrl.isNotEmpty)
              Image.network(
                imageUrl,
                height: 180,
                fit: BoxFit.cover,
                errorBuilder: (c, e, s) => Container(
                  height: 180, 
                  color: Colors.grey.shade300,
                  child: const Icon(Icons.image, size: 50, color: Colors.grey),
                ),
              ),
            Container(
              color: const Color(0xFF355E6B),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Text(
                    'TIN TỨC NỔI BẬT',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
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
                      height: 1.3,
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

  Widget _buildStandardNews(NewsItemModel item) {
    return InkWell(
      onTap: () => context.push('/news_detail', extra: item),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: const [
            BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              item.categoryName.toUpperCase(),
              style: TextStyle(
                color: uehOrange,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            if (item.sdgs.isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(
                children: item.sdgs.map((sdg) => Padding(
                  padding: const EdgeInsets.only(right: 6.0),
                  child: Image.asset(
                    'assets/images/sdg/vi/sdg-$sdg.png',
                    height: 26,
                    width: 26,
                    errorBuilder: (c, e, s) => const SizedBox(),
                  ),
                )).toList(),
              ),
            ],
            const SizedBox(height: 10),
            Text(
              item.title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
                height: 1.3,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNewsTab() {
    return RefreshIndicator(
      onRefresh: _refreshData,
      color: uehPrimary,
      child: CustomScrollView(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(top: 24, bottom: 8),
              child: Column(
                children: [
                  Text(
                    'Tin tức', 
                    style: TextStyle(
                      color: uehOrange, 
                      fontSize: 26, 
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
          ),
          if (_news.isEmpty && _isLoadingNews)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(40.0),
                child: Center(child: CircularProgressIndicator()),
              ),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  if (index == _news.length) {
                    return _hasMoreNews
                        ? Padding(
                            padding: const EdgeInsets.symmetric(vertical: 24.0),
                            child: Center(
                              child: CircularProgressIndicator(color: uehPrimary),
                            ),
                          )
                        : const Padding(
                            padding: EdgeInsets.symmetric(vertical: 24.0),
                            child: Center(
                              child: Text(
                                'Đã hiển thị tất cả tin tức',
                                style: TextStyle(color: Colors.grey, fontSize: 13),
                              ),
                            ),
                          );
                  }
                  final item = _news[index];
                  // Tin đầu tiên hoặc tin nổi bật
                  if (item.isFeatured || index == 0) {
                    return _buildFeaturedNews(item);
                  } else {
                    return _buildStandardNews(item);
                  }
                },
                childCount: _news.length + (_news.isNotEmpty ? 1 : 0),
              ),
            ),
          const SliverToBoxAdapter(
            child: SizedBox(height: 24),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    String appBarTitle = 'Tin tức UEH';
    if (_selectedIndex == 1) appBarTitle = 'Thông báo';
    if (_selectedIndex == 2) appBarTitle = 'Điểm danh';
    if (_selectedIndex == 3) appBarTitle = 'Tài khoản';

    return Scaffold(
      appBar: AppBar(
        backgroundColor: uehPrimary,
        foregroundColor: Colors.white,
        centerTitle: true,
        title: _selectedIndex == 0 
            ? Image.asset('assets/images/logo-header.png', height: 40, errorBuilder: (c,e,s) => const Text('Trang chủ'))
            : Text(appBarTitle, style: const TextStyle(fontWeight: FontWeight.normal)),
        actions: [
          if (_selectedIndex == 3)
            IconButton(
              icon: const Icon(Icons.logout),
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
              icon: const Icon(Icons.refresh),
              onPressed: _refreshData,
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
        selectedItemColor: uehPrimary,
        unselectedItemColor: Colors.grey,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Trang chủ'),
          BottomNavigationBarItem(icon: Icon(Icons.notifications), label: 'Thông báo'),
          BottomNavigationBarItem(icon: Icon(Icons.check_circle_outline), label: 'Điểm danh'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Tài khoản'),
        ],
      ),
    );
  }
}
