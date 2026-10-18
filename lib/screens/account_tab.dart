// ============================================================================
// 🎤 [THUYẾT MINH - TAB TÀI KHOẢN & THẺ SINH VIÊN SỐ]:
// "Dạ thưa thầy, Tab Tài khoản quản lý xác thực người dùng sinh viên UEH.
// Nếu chưa đăng nhập, tab hiển thị Form đăng nhập chuẩn với MSSV và mật khẩu.
// Sau khi đăng nhập thành công, Access Token và Refresh Token được lưu an toàn
// vào FlutterSecureStorage. Ứng dụng sẽ hiển thị Thẻ sinh viên số (Digital Student Card)
// với đầy đủ thông tin cá nhân, ảnh đại diện có hiệu ứng radar động và mã QR cá nhân."
// ============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../services/api_service.dart';

class AccountTab extends StatefulWidget {
  const AccountTab({super.key});

  @override
  State<AccountTab> createState() => _AccountTabState();
}

class _AccountTabState extends State<AccountTab> with SingleTickerProviderStateMixin {
  final ApiService _apiService = ApiService();

  // 🎤 [THUYẾT MINH - BẢO MẬT TOKEN VỚI FLUTTER SECURE STORAGE]:
  // "Em sử dụng thư viện flutter_secure_storage để mã hóa và lưu trữ token an toàn
  // (sử dụng KeyStore trên Android và Keychain trên iOS), tránh rò rỉ dữ liệu."
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  
  final TextEditingController _mssvController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  
  // 🎤 [THUYẾT MINH - HIỆU ỨNG RADAR AVATAR]:
  // "Sử dụng AnimationController với thời lượng 2 giây, lặp vô tận (repeat)
  // để tạo vòng tròn xung động lan tỏa (pulsing radar) quanh ảnh đại diện sinh viên."
  late AnimationController _rippleController;
  
  bool _isLoading = false;
  bool _isLoggedIn = false;
  Map<String, dynamic>? _studentInfo;

  @override
  void initState() {
    super.initState();
    _rippleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    // 🎤 [THUYẾT MINH - TỰ ĐỘNG KHÔI PHỤC PHIÊN ĐĂNG NHẬP]:
    // "Khi người dùng mở tab, hệ thống tự động kiểm tra xem token đã lưu trước đó còn hợp lệ không."
    _checkLoginStatus();
  }

  @override
  void dispose() {
    _rippleController.dispose();
    _mssvController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // 🎤 [THUYẾT MINH - KIỂM TRA PHIÊN LÀM VIỆC]:
  // "Đọc token từ FlutterSecureStorage. Nếu tồn tại, đổi trạng thái _isLoggedIn = true
  // và gọi _fetchProfile() để tải thông tin sinh viên từ server."
  Future<void> _checkLoginStatus() async {
    final token = await _storage.read(key: 'token');
    if (token != null && token.isNotEmpty) {
      setState(() {
        _isLoggedIn = true;
      });
      _fetchProfile(token);
    }
  }

  // 🎤 [THUYẾT MINH - LẤY THÔNG TIN SINH VIÊN TỪ API]:
  // "Gửi request GET /v1/student/info kèm Bearer Token. Nếu token hết hạn hoặc lỗi,
  // hệ thống sẽ tự động gọi _logout() để xóa cache và đưa về màn hình đăng nhập."
  Future<void> _fetchProfile(String token) async {
    try {
      final info = await _apiService.getStudentInfo(token);
      if (mounted) {
        setState(() {
          _studentInfo = info;
        });
      }
    } catch (e) {
      // Token lỗi hoặc hết hạn
      _logout();
    }
  }

  // 🎤 [THUYẾT MINH - XỬ LÝ ĐĂNG NHẬP]:
  // "Validate dữ liệu đầu vào (MSSV và Mật khẩu). Sau đó gọi API login.
  // Khi thành công, lưu cả token và refresh_token vào secure storage để
  // phục vụ cơ chế tự động cấp phát lại token mới khi token cũ hết hạn (Refresh Token Flow)."
  Future<void> _login() async {
    final mssv = _mssvController.text.trim();
    final password = _passwordController.text.trim();

    if (mssv.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập đầy đủ MSSV và mật khẩu')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final data = await _apiService.login(mssv, password);
      final token = data['token'];
      await _storage.write(key: 'token', value: token);
      await _storage.write(key: 'refresh_token', value: data['refresh_token']);
      
      setState(() {
        _isLoggedIn = true;
      });
      
      _fetchProfile(token);
      
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
  
  // 🎤 [THUYẾT MINH - ĐĂNG XUẤT AN TOÀN]:
  // "Xóa sạch token và refresh_token khỏi bộ nhớ bảo mật, đặt lại state về rỗng."
  Future<void> _logout() async {
    await _storage.delete(key: 'token');
    await _storage.delete(key: 'refresh_token');
    setState(() {
      _isLoggedIn = false;
      _studentInfo = null;
      _mssvController.clear();
      _passwordController.clear();
    });
  }

  // 🎤 [THUYẾT MINH - GIAO DIỆN FORM ĐĂNG NHẬP]:
  // "Giao diện đăng nhập hiện đại với banner trường UEH, các ô nhập liệu tối giản
  // và nút 'ĐĂNG NHẬP' mang màu xanh thương hiệu #005F69."
  Widget _buildLoginScreen() {
    final Color uehPrimary = const Color(0xFF005F69);
    
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [

          Image.asset(
            'assets/images/nso-splash-landscape-1499x999.png',
            height: 200,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => Container(
              height: 200,
              color: Colors.grey.shade300,
              child: const Icon(Icons.school, size: 50, color: Colors.grey),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Chào mừng đến với UEH',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Nơi đào tạo nhà quản lý và doanh nhân thành đạt',
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
                const SizedBox(height: 32),
                
                const Text('Tên đăng nhập', style: TextStyle(fontSize: 12, color: Colors.grey)),
                TextField(
                  controller: _mssvController,
                  decoration: const InputDecoration(
                    hintText: 'Nhập tên đăng nhập',
                    hintStyle: TextStyle(color: Colors.black26),
                    enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.black12)),
                  ),
                ),
                const SizedBox(height: 24),
                
                const Text('Mật khẩu', style: TextStyle(fontSize: 12, color: Colors.grey)),
                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    hintText: 'Nhập mật khẩu',
                    hintStyle: TextStyle(color: Colors.black26),
                    enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.black12)),
                  ),
                ),
                const SizedBox(height: 32),
                
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _login,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: uehPrimary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                    ),
                    child: _isLoading 
                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Text('ĐĂNG NHẬP', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(height: 16),
                
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: OutlinedButton(
                    onPressed: () {},
                    style: OutlinedButton.styleFrom(
                      foregroundColor: uehPrimary,
                      side: BorderSide(color: uehPrimary),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                    ),
                    child: const Text('ĐĂNG NHẬP BẰNG EMAIL UEH'),
                  ),
                ),
                const SizedBox(height: 16),
                
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: OutlinedButton(
                    onPressed: () {},
                    style: OutlinedButton.styleFrom(
                      foregroundColor: uehPrimary,
                      side: BorderSide(color: uehPrimary),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                    ),
                    child: const Text('ĐĂNG NHẬP BẰNG EMAIL KHÁCH'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(String isoDate) {
    if (isoDate.isEmpty) return '';
    try {
      final parts = isoDate.split('T')[0].split('-');
      if (parts.length == 3) {
        return '${parts[2]}/${parts[1]}/${parts[0]}';
      }
    } catch (e) {
      // fall through
    }
    return isoDate;
  }

  // 🎤 [THUYẾT MINH - GIAO DIỆN THẺ SINH VIÊN SỐ (DIGITAL STUDENT CARD)]:
  // "Dạ thưa thầy, khi đã đăng nhập, màn hình sẽ hiển thị chiếc Thẻ sinh viên số
  // được thiết kế dạng Card sang trọng với màu xanh thương hiệu #005F69 của UEH.
  // Thẻ có bố cục chuẩn gồm thông tin cá nhân, avatar có radar động, và mã QR tích hợp."
  Widget _buildProfileScreen() {
    if (_studentInfo == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final Color uehPrimary = const Color(0xFF005F69);
    final String avatar = _studentInfo!['hinhDaiDien'] ?? '';
    final String name = _studentInfo!['hoVaTen'] ?? '';
    final String dob = _formatDate(_studentInfo!['ngaySinh'] ?? '');
    final String gender = (_studentInfo!['gioiTinh'] == true) ? 'Nam' : 'Nữ';
    final String cohort = _studentInfo!['nienKhoa'] ?? '';
    final String placeOfBirth = _studentInfo!['noiSinh'] ?? '';
    final String system = _studentInfo!['heDaoTao'] ?? '';
    final String academicYear = _studentInfo!['nienHoc'] ?? '';
    final String mssv = _studentInfo!['mssv'] ?? '';

    return LayoutBuilder(
      builder: (context, constraints) {
        return Stack(
          alignment: Alignment.topCenter,
          children: [
            // 🎤 [THUYẾT MINH - KHUNG THẺ SINH VIÊN UEH]:
            // "Thẻ chính bo tròn góc 24px, nền màu xanh cổ vịt #005F69,
            // khoảng đệm top 70px để chừa không gian nổi cho avatar ở phía trên."
            Positioned(
              top: 60,
              left: 16,
              right: 16,
              bottom: 16, // Kéo dài xuống sát đáy
              child: Container(
                padding: const EdgeInsets.only(top: 70, left: 24, right: 24, bottom: 24),
                decoration: BoxDecoration(
                  color: uehPrimary,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Text(
                        'SINH VIÊN',
                        style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 12),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Center(
                      child: Text(
                        name,
                        style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const Spacer(),
                    
                    // 🎤 [THUYẾT MINH - CÁC HÀNG THÔNG TIN SINH VIÊN]:
                    // "Hiển thị Ngày sinh, Giới tính, Khóa, Nơi sinh, Hệ đào tạo và Niên học
                    // được căn chỉnh dạng lưới 2 cột khoa học, dễ đọc."
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('NGÀY SINH', style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 10, letterSpacing: 1.2)),
                              const SizedBox(height: 6),
                              Text(dob, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('GIỚI TÍNH', style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 10, letterSpacing: 1.2)),
                              const SizedBox(height: 6),
                              Text(gender, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('KHOÁ', style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 10, letterSpacing: 1.2)),
                              const SizedBox(height: 6),
                              Text(cohort, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('NƠI SINH', style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 10, letterSpacing: 1.2)),
                              const SizedBox(height: 6),
                              Text(placeOfBirth, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    
                    Text('HỆ ĐẠI HỌC - NIÊN HỌC', style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 10, letterSpacing: 1.2)),
                    const SizedBox(height: 6),
                    Text('$system\n- Niên học: $academicYear', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 24),
                    
                    const Spacer(),
                    
                    // 🎤 [THUYẾT MINH - MÃ QR CÁ NHÂN HÓA MSSV]:
                    // "Ở góc dưới thẻ có logo UEH UNIVERSITY và mã QR Code được sinh động
                    // theo MSSV của sinh viên. Mã này dùng để xác minh hoặc quét nhanh khi vào cổng/thư viện."
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('UEH', style: TextStyle(color: Colors.white, fontSize: 48, fontWeight: FontWeight.w900, height: 1.0)),
                            Text('UNIVERSITY', style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                          ],
                        ),
                        Container(
                          width: 80,
                          height: 80,
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: Image.network(
                              'https://api.qrserver.com/v1/create-qr-code/?size=150x150&data=$mssv',
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            
            // 🎤 [THUYẾT MINH - HIỆU ỨNG RADAR SÓNG LAN TỎA QUANH AVATAR]:
            // "AnimatedBuilder lắng nghe _rippleController để vẽ vòng tròn mở rộng dần
            // và mờ dần (fade out) tạo cảm giác như sóng radar công nghệ hiện đại bao quanh ảnh thẻ."
            Positioned(
              top: 0,
              child: SizedBox(
                width: 150,
                height: 150,
                child: AnimatedBuilder(
                  animation: _rippleController,
                  builder: (context, child) {
                    return Stack(
                      alignment: Alignment.center,
                      children: [
                        // Vòng radar lan tỏa
                        Container(
                          width: 110 + (_rippleController.value * 40),
                          height: 110 + (_rippleController.value * 40),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: uehPrimary.withValues(alpha: 0.5 * (1 - _rippleController.value)),
                              width: 10 * (1 - _rippleController.value),
                            ),
                          ),
                        ),
                        // Avatar cố định
                        Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 4),
                          ),
                          child: CircleAvatar(
                            radius: 52,
                            backgroundColor: Colors.grey.shade200,
                            backgroundImage: avatar.isNotEmpty ? NetworkImage(avatar) : null,
                            child: avatar.isEmpty ? const Icon(Icons.person, size: 60, color: Colors.grey) : null,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ],
        );
      }
    );
  }

  @override
  Widget build(BuildContext context) {
    return _isLoggedIn ? _buildProfileScreen() : _buildLoginScreen();
  }
}
