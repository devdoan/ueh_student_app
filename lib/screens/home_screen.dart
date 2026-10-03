import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../models/menu_item.dart';
import '../models/news_item.dart';
import '../services/api_service.dart';
import '../database/database_helper.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'account_tab.dart';
import 'attendance_tab.dart';

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
  bool _hasMoreNews = true;
  int _currentPage = 0;
  int _selectedIndex = 0;

  final Color uehPrimary = const Color(0xFF005F69);
  

  @override
  void initState() {
    super.initState();
    _loadMenus();
    _loadNews();
    
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
        _loadNews();
      }
    });
  }

  Future<void> _loadMenus() async {
    final localMenus = await _dbHelper.getMenus();
    if (localMenus.isNotEmpty) {
      setState(() {
        _menus = localMenus;
        _isLoadingMenu = false;
      });
    }

    try {
      final remoteMenus = await _apiService.fetchMenus();
      await _dbHelper.insertMenu(remoteMenus);
      
      if (mounted) {
        setState(() {
          _menus = remoteMenus;
          _isLoadingMenu = false;
        });
      }
    } catch (e) {
      if (_menus.isEmpty && mounted) {
        setState(() => _isLoadingMenu = false);
      }
    }
  }

  Future<void> _loadNews() async {
    if (_isLoadingNews || !_hasMoreNews) return;

    setState(() => _isLoadingNews = true);

    try {
      final newItems = await _apiService.fetchNews(_currentPage);
      
      if (mounted) {
        setState(() {
          _currentPage++;
          _isLoadingNews = false;
          if (newItems.isEmpty) {
            _hasMoreNews = false;
          } else {
            _news.addAll(newItems);
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingNews = false);
      }
    }
  }

  Future<void> _refreshData() async {
    setState(() {
      _news.clear();
      _currentPage = 0;
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
    switch(iconPath) {
      case 'news': return Icons.article_outlined;
      case 'events': return Icons.calendar_month_outlined;
      case 'scores': return Icons.score_outlined;
      case 'face': return Icons.face_retouching_natural_outlined;
      case 'schedule': return Icons.schedule_outlined;
      case 'exams': return Icons.assignment_outlined;
      case 'health': return Icons.health_and_safety_outlined;
      case 'green': return Icons.eco_outlined;
      case 'contact': return Icons.contact_support_outlined;
      default: return Icons.apps;
    }
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
                child: _isLoadingMenu
                    ? const Center(child: CircularProgressIndicator(color: Colors.white))
                    : ListView.builder(
                        itemCount: _menus.length,
                        itemBuilder: (context, index) {
                          final menu = _menus[index];
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Colors.white24,
                              child: Icon(_getMenuIcon(menu.iconPath), color: Colors.white),
                            ),
                            title: Text(
                              menu.title,
                              style: const TextStyle(color: Colors.white, fontSize: 16),
                            ),
                            onTap: () {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Chức năng \${menu.title}')));
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
    return InkWell(
      onTap: () => context.push('/news_detail', extra: item),
      child: Container(
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: uehPrimary,
          boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8)],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Image.network(
              item.thumbnailUrl,
              height: 180,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (c,e,s) => Container(height: 180, color: Colors.grey),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Text(
                    item.category.toUpperCase(),
                    style: const TextStyle(color: Colors.white, fontSize: 18, letterSpacing: 1.2),
                  ),
                  const SizedBox(height: 12),
                  if (item.sdgIcons.isNotEmpty)
                    Image.asset(item.sdgIcons[0], height: 40, width: 40, errorBuilder: (c,e,s) => const SizedBox()),
                  const SizedBox(height: 12),
                  Text(
                    item.title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white, fontSize: 16),
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
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              item.category.toUpperCase(),
              style: TextStyle(color: uehPrimary, fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 8),
            Row(
              children: item.sdgIcons.map((path) => Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: Image.asset(path, height: 30, width: 30, errorBuilder: (c,e,s) => const SizedBox()),
              )).toList(),
            ),
            const SizedBox(height: 12),
            Text(
              item.title,
              style: const TextStyle(fontSize: 16, color: Colors.black87),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNewsTab() {
    return CustomScrollView(
      controller: _scrollController,
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.only(top: 24, bottom: 8),
            child: Column(
              children: [
                Text('Tin tức', style: TextStyle(color: uehPrimary, fontSize: 28, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                const Text('Thông tin mới nhất và kiến thức hữu ích từ UEH', style: TextStyle(color: Colors.grey, fontSize: 14)),
              ],
            ),
          ),
        ),
        if (_news.isEmpty && _isLoadingNews)
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(32.0),
              child: Center(child: CircularProgressIndicator()),
            ),
          )
        else
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                if (index == _news.length) {
                  return _hasMoreNews
                      ? const Padding(padding: EdgeInsets.all(16.0), child: Center(child: CircularProgressIndicator()))
                      : const SizedBox(height: 32);
                }
                
                final item = _news[index];
                if (item.isFeatured) {
                  return _buildFeaturedNews(item);
                } else {
                  return _buildStandardNews(item);
                }
              },
              childCount: _news.length + (_hasMoreNews ? 1 : 0),
            ),
          ),
      ],
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
            ? Image.asset('assets/images/logo-header.png', height: 40, errorBuilder: (c,e,s) => const Text('Tin tức UEH'))
            : Text(appBarTitle, style: const TextStyle(fontWeight: FontWeight.normal)),
        actions: [
          if (_selectedIndex == 3)
            IconButton(
              icon: const Icon(Icons.logout),
              tooltip: 'Đăng xuất',
              onPressed: () {
                // To call logout, we need a global key or just broadcast a state. 
                // Alternatively, keep a logout function callback or a stream.
                // For now, I'll clear secure storage and restart app to make it easiest.
                const FlutterSecureStorage().deleteAll().then((_) {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => const HomeScreen()),
                  );
                });
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
          const Center(child: Text('Màn hình Thông báo')),
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
