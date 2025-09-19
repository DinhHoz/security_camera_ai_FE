// Import các gói cần thiết
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart'; // 👈 thêm dòng này
import '../services/auth_service.dart';
import '../screens/CameraStreamScreen.dart';

// Màn hình để thêm camera mới
class AddCameraScreen extends StatefulWidget {
  const AddCameraScreen({Key? key}) : super(key: key);

  @override
  _AddCameraScreenState createState() => _AddCameraScreenState();
}

class _AddCameraScreenState extends State<AddCameraScreen> {
  // Bộ điều khiển (controller) để lấy dữ liệu từ các TextField
  final _cameraNameController = TextEditingController();
  final _streamUrlController = TextEditingController();
  final _locationController = TextEditingController();

  // Biến để quản lý trạng thái tải dữ liệu
  bool _isLoading = false;

  // 👉 Hàm lưu camera mới vào SharedPreferences
  Future<void> _saveCamera(Map<String, dynamic> camera) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> cameras = prefs.getStringList('cameras') ?? [];
    cameras.add(jsonEncode(camera));
    await prefs.setStringList('cameras', cameras);
  }

  // Thêm hàm này vào class _AddCameraScreenState
  Future<void> _addNewCamera() async {
    // Lấy dữ liệu từ các controller
    final cameraName = _cameraNameController.text.trim();
    final streamUrl = _streamUrlController.text.trim();
    final location = _locationController.text.trim();

    // Kiểm tra nếu các trường không được điền đầy đủ
    if (cameraName.isEmpty || streamUrl.isEmpty || location.isEmpty) {
      _showSnackBar('Vui lòng điền đầy đủ thông tin.', Colors.red);
      return;
    }

    // Cập nhật trạng thái tải
    setState(() {
      _isLoading = true;
    });

    try {
      // Địa chỉ API của bạn
      const String apiUrl =
          'http://192.168.1.214:3000/api/cameras'; // Thay đổi IP và port cho phù hợp

      // Gửi yêu cầu POST lên server
      final authHeader = await AuthService.getAuthHeader();

      if (authHeader == null) {
        _showSnackBar('Không thể lấy token xác thực.', Colors.red);
        setState(() {
          _isLoading = false;
        });
        return;
      }

      final response = await http.post(
        Uri.parse(apiUrl),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': authHeader, // Sử dụng header đã lấy
        },
        body: jsonEncode(<String, String>{
          'cameraName': cameraName,
          'streamUrl': streamUrl,
          'location': location,
          'status': 'active',
        }),
      );

      // Xử lý phản hồi từ server
      if (response.statusCode == 201 || response.statusCode == 200) {
        _showSnackBar('Thêm camera thành công!', Colors.green);

        // Tạo object camera
        final newCamera = {
          'id': DateTime.now().millisecondsSinceEpoch.toString(),
          'cameraName': cameraName,
          'streamUrl': streamUrl,
          'location': location,
        };

        // 👉 Lưu vào local
        await _saveCamera(newCamera);

        if (mounted) {
          Navigator.pop(context, true); // 👈 quay về HomeScreen, báo thành công
        }
      }
    } catch (e) {
      // Xử lý lỗi khi gửi yêu cầu (ví dụ: mất kết nối mạng)
      _showSnackBar('Có lỗi xảy ra: $e', Colors.red);
      print('Lỗi kết nối: $e');
    } finally {
      // Dù thành công hay thất bại, hãy tắt trạng thái tải
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Hàm trợ giúp để hiển thị SnackBar
  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message), backgroundColor: color));
  }

  @override
  void dispose() {
    // Giải phóng bộ điều khiển khi widget bị hủy
    _cameraNameController.dispose();
    _streamUrlController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Thêm Camera Mới')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Trường nhập tên camera
            TextField(
              controller: _cameraNameController,
              decoration: const InputDecoration(
                labelText: 'Tên Camera',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            // Trường nhập Stream URL
            TextField(
              controller: _streamUrlController,
              decoration: const InputDecoration(
                labelText: 'Stream URL',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            // Trường nhập vị trí
            TextField(
              controller: _locationController,
              decoration: const InputDecoration(
                labelText: 'Vị trí',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 30),
            // Nút Thêm Camera
            _isLoading
                ? const CircularProgressIndicator() // Hiển thị vòng tròn tải nếu đang xử lý
                : ElevatedButton(
                  onPressed: _addNewCamera,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 40,
                      vertical: 15,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                  ),
                  child: const Text(
                    'Thêm Camera',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
          ],
        ),
      ),
    );
  }
}
