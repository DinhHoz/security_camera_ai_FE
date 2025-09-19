// lib/services/camera_api.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/constants.dart';
import '../services/auth_service.dart'; // Giả sử bạn có file này để lấy token
import 'api_config.dart';

class CameraApi {
  static const String baseUrl = '${ApiConfig.baseUrl}/api';

  static Future<List<Map<String, dynamic>>> getCameras() async {
    final authHeader = await AuthService.getAuthHeader();
    if (authHeader == null) {
      throw Exception('Không có token xác thực.');
    }

    final response = await http.get(
      Uri.parse('$baseUrl/cameras'),
      headers: {'Authorization': authHeader},
    );

    if (response.statusCode == 200) {
      final configs = jsonDecode(response.body) as List<dynamic>;
      return configs.cast<Map<String, dynamic>>();
    } else {
      throw Exception('Lỗi khi tải danh sách camera: ${response.statusCode}');
    }
  }

  static Future<void> addCamera({
    required String cameraName,
    required String location,
    required String streamUrl,
  }) async {
    final authHeader = await AuthService.getAuthHeader();
    if (authHeader == null) {
      throw Exception('Không có token xác thực.');
    }

    final response = await http.post(
      Uri.parse('$baseUrl/cameras'),
      headers: {
        'Authorization': authHeader,
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'cameraName': cameraName,
        'location': location,
        'streamUrl': streamUrl,
        'status': true,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Lỗi khi thêm camera: ${response.statusCode}');
    }
  }

  // Thêm các phương thức PUT và DELETE nếu cần
  static Future<void> updateCamera({
    required String cameraId,
    String? cameraName,
    bool? status,
    String? streamUrl,
    String? location,
  }) async {
    final authHeader = await AuthService.getAuthHeader();
    if (authHeader == null) {
      throw Exception('Không có token xác thực.');
    }

    final response = await http.put(
      Uri.parse('$baseUrl/cameras/$cameraId'),
      headers: {
        'Authorization': authHeader,
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        if (cameraName != null) 'cameraName': cameraName,
        if (status != null) 'status': status,
        if (streamUrl != null) 'streamUrl': streamUrl,
        if (location != null) 'location': location,
        'updatedAt': DateTime.now().toIso8601String(),
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Lỗi khi cập nhật camera: ${response.statusCode}');
    }
  }

  static Future<void> deleteCamera(String cameraId) async {
    final authHeader = await AuthService.getAuthHeader();
    if (authHeader == null) {
      throw Exception('Không có token xác thực.');
    }

    final response = await http.delete(
      Uri.parse('$baseUrl/cameras/$cameraId'),
      headers: {'Authorization': authHeader},
    );

    if (response.statusCode != 200) {
      throw Exception('Lỗi khi xóa camera: ${response.statusCode}');
    }
  }
}
