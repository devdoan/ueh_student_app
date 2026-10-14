import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:barcode_scan2/barcode_scan2.dart';
import 'package:permission_handler/permission_handler.dart';
import '../services/api_service.dart';

class AttendanceTab extends StatefulWidget {
  const AttendanceTab({super.key});

  @override
  State<AttendanceTab> createState() => _AttendanceTabState();
}

class _AttendanceTabState extends State<AttendanceTab> {
  final ApiService _apiService = ApiService();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  final TextEditingController _codeController = TextEditingController();
  
  bool _isLoading = false;

  Future<Position?> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    try {
      // Có timeLimit để chống treo ANR trên máy ảo
      serviceEnabled = await Geolocator.isLocationServiceEnabled().timeout(const Duration(seconds: 3));
      if (!serviceEnabled) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Vui lòng bật Dịch vụ định vị (GPS)')),
          );
        }
        return null;
      }

      permission = await Geolocator.checkPermission().timeout(const Duration(seconds: 2));
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission().timeout(const Duration(seconds: 5));
        if (permission == LocationPermission.denied) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Quyền truy cập vị trí bị từ chối')),
            );
          }
          return null;
        }
      }
      
      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Quyền vị trí bị từ chối vĩnh viễn')),
          );
        }
        return null;
      } 

      return await Geolocator.getCurrentPosition(
        timeLimit: const Duration(seconds: 15),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Không thể lấy vị trí GPS: ${e.toString()}'),
            backgroundColor: Colors.red.shade800,
          ),
        );
      }
      return null;
    }
  }

  Future<void> _submitAttendance(String code, {Position? preFetchedPosition}) async {
    if (code.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập mã điểm danh')),
      );
      return;
    }

    setState(() { _isLoading = true; });

    try {
      // Dùng vị trí đã lấy (nếu có) để tránh mất thêm 10s gọi lại GPS
      final position = preFetchedPosition ?? await _determinePosition();
      if (position == null) {
        setState(() { _isLoading = false; });
        return; // Đã dừng lại do lỗi GPS
      }

      final token = await _storage.read(key: 'token');
      if (token == null || token.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Vui lòng đăng nhập')),
          );
        }
        setState(() { _isLoading = false; });
        return;
      }

      // Việc kiểm tra khoảng cách 200m sẽ do SERVER của thầy thực hiện. 
      // App chỉ có nhiệm vụ lấy tọa độ GPS chính xác nhất gửi lên.
      final data = await _apiService.postAttendance(
        token, 
        code, 
        position.latitude, 
        position.longitude,
      );

      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Thành công'),
            content: Text(data['message'] ?? 'Điểm danh thành công!'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Đóng'),
              ),
            ],
          ),
        );
        _codeController.clear();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            duration: const Duration(seconds: 5),
            backgroundColor: Colors.red.shade800,
          ),
        );
      }
    } finally {
      if (mounted) setState(() { _isLoading = false; });
    }
  }

  Future<bool> _checkCameraPermission() async {
    var status = await Permission.camera.status;
    if (status.isGranted) {
      return true;
    }

    // Yêu cầu quyền truy cập Camera từ người dùng
    status = await Permission.camera.request();
    if (status.isGranted) {
      return true;
    }

    if (mounted) {
      if (status.isPermanentlyDenied) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Cần quyền truy cập Camera'),
            content: const Text(
              'Ứng dụng cần quyền Camera để quét mã QR điểm danh. '
              'Bạn đã từ chối quyền vĩnh viễn, vui lòng vào Cài đặt để bật quyền Camera.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Hủy'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  openAppSettings();
                },
                child: const Text('Mở Cài đặt'),
              ),
            ],
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Vui lòng cấp quyền Camera để quét mã QR điểm danh!'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
    return false;
  }

  Future<void> _scanQRCode() async {
    try {
      // 1. Kiểm tra và xin quyền Camera trước
      final hasPermission = await _checkCameraPermission();
      if (!hasPermission) return;

      // 2. Kiểm tra vị trí trước theo yêu cầu thầy giáo
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đang lấy vị trí GPS trước khi quét...')),
        );
      }
      final position = await _determinePosition();
      if (position == null) return; 

      // 3. Mở Camera quét QR
      var result = await BarcodeScanner.scan(
        options: const ScanOptions(
          strings: {
            'cancel': 'Hủy',
            'flash_on': 'Bật đèn flash',
            'flash_off': 'Tắt đèn flash',
          },
        ),
      );

      // Nếu quét thành công (camera tự đóng)
      if (result.type == ResultType.Barcode) {
        final code = result.rawContent;
        if (code.isNotEmpty) {
          _codeController.text = code;
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Đã quét được mã: $code. Đang điểm danh...'), backgroundColor: Colors.green),
            );
          }
          
          // Điểm danh ngay lập tức, truyền vị trí đã lấy vào để tiết kiệm thời gian
          _submitAttendance(code, preFetchedPosition: position);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi mở Camera: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color uehPrimary = const Color(0xFF005F69);
    
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 16),
          Center(
            child: Text(
              'Vui lòng nhập hoặc quét mã để điểm danh',
              style: TextStyle(
                color: uehPrimary,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 32),
          
          Center(
            child: Text('Nhập mã điểm danh', style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _codeController,
            textAlign: TextAlign.center,
            decoration: const InputDecoration(
              hintText: 'Nhập mã ở đây',
              hintStyle: TextStyle(color: Colors.black26),
              enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.black26)),
              focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.black54)),
            ),
          ),
          const SizedBox(height: 32),
          
          Row(
            children: [
              Expanded(child: Divider(color: Colors.grey.shade300)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Text('Hoặc', style: TextStyle(color: Colors.grey.shade400)),
              ),
              Expanded(child: Divider(color: Colors.grey.shade300)),
            ],
          ),
          const SizedBox(height: 32),
          
          _buildOutlinedButton(
            icon: Icons.qr_code_scanner, 
            label: 'Quét mã QR Code', 
            onPressed: _scanQRCode,
            color: uehPrimary,
          ),
          const SizedBox(height: 16),
          _buildOutlinedButton(
            icon: Icons.barcode_reader, 
            label: 'Quét mã Barcode', 
            onPressed: _scanQRCode,
            color: uehPrimary,
          ),
          const SizedBox(height: 16),
          _buildOutlinedButton(
            icon: Icons.face, 
            label: 'Xác thực khuôn mặt', 
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Tính năng khuôn mặt đang phát triển')));
            },
            color: uehPrimary,
          ),
          
          const Spacer(),
          
          SizedBox(
            height: 48,
            child: ElevatedButton(
              onPressed: _isLoading ? null : () => _submitAttendance(_codeController.text),
              style: ElevatedButton.styleFrom(
                backgroundColor: uehPrimary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              ),
              child: _isLoading 
                ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Text('Điểm danh', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildOutlinedButton({required IconData icon, required String label, required VoidCallback onPressed, required Color color}) {
    return SizedBox(
      height: 48,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: color,
          side: BorderSide(color: color),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 24),
            const SizedBox(width: 12),
            Text(label, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
