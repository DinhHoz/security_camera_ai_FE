import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../services/auth_service.dart';
import '../models/camera.dart'; // 👈 import model Camera
import '../screens/CameraStreamScreen.dart';
import 'UI_device.dart'; // 👈 import màn hình stream

class AddCameraScreen extends StatefulWidget {
  const AddCameraScreen({Key? key}) : super(key: key);

  @override
  State<AddCameraScreen> createState() => _AddCameraScreenState();
}

class _AddCameraScreenState extends State<AddCameraScreen> {
  final _cameraNameController = TextEditingController();
  final _streamUrlController = TextEditingController();
  final _locationController = TextEditingController();

  bool _isLoading = false;

  /// 👉 Lưu camera vào SharedPreferences (cache offline)
  Future<void> _saveCamera(Map<String, dynamic> camera) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> cameras = prefs.getStringList('cameras') ?? [];
    cameras.add(jsonEncode(camera));
    await prefs.setStringList('cameras', cameras);
  }

  /// 👉 Gửi request thêm camera
  Future<void> _addNewCamera() async {
    final cameraName = _cameraNameController.text.trim();
    final streamUrl = _streamUrlController.text.trim();
    final location = _locationController.text.trim();

    if (cameraName.isEmpty || streamUrl.isEmpty || location.isEmpty) {
      _showSnackBar('⚠️ Vui lòng điền đầy đủ thông tin.', Colors.red);
      return;
    }

    setState(() => _isLoading = true);

    try {
      const String apiUrl = 'http://192.168.1.214:3000/api/cameras';
      final authHeader = await AuthService.getAuthHeader();

      if (authHeader == null) {
        _showSnackBar('❌ Không thể lấy token xác thực.', Colors.red);
        setState(() => _isLoading = false);
        return;
      }

      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': authHeader,
        },
        body: jsonEncode({
          'cameraName': cameraName,
          'streamUrl': streamUrl,
          'location': location,
          'status': 'active',
        }),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        _showSnackBar('Thêm camera thành công!', Colors.green);

        // 👉 Tạo object Camera từ dữ liệu nhập
        final newCamera = Camera(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          cameraName: cameraName,
          location: location,
          streamUrl: streamUrl,
        );

        // 👉 Lưu vào local
        await _saveCamera({
          'id': newCamera.id,
          'cameraName': newCamera.cameraName,
          'streamUrl': newCamera.streamUrl,
          'location': newCamera.location,
        });

        if (mounted) {
          // 👉 Chuyển sang CameraStreamScreen hiển thị live stream
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => DeviceScreen()),
          );
        }
      } else {
        _showSnackBar(
          '❌ Lỗi khi thêm camera: ${response.statusCode}',
          Colors.red,
        );
      }
    } catch (e) {
      _showSnackBar('⚠️ Có lỗi xảy ra: $e', Colors.red);
      print('Lỗi kết nối: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// 👉 Hiển thị SnackBar
  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message), backgroundColor: color));
  }

  @override
  void dispose() {
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
            TextField(
              controller: _cameraNameController,
              decoration: const InputDecoration(
                labelText: 'Tên Camera',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _streamUrlController,
              decoration: const InputDecoration(
                labelText: 'RTSP / Stream URL',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _locationController,
              decoration: const InputDecoration(
                labelText: 'Vị trí',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 30),
            _isLoading
                ? const CircularProgressIndicator()
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
