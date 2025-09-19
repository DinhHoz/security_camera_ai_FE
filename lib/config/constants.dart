// lib/config/constants.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppConstants {
  static const String configCollection = 'camera_config';

  // Khởi tạo dotenv
  static Future<void> initialize() async {
    await dotenv.load(fileName: ".env");
  }

  // Lấy tất cả cấu hình camera từ Firestore
  static Future<List<Map<String, dynamic>>> getAllCameraConfigs() async {
    final snapshot =
        await FirebaseFirestore.instance.collection(configCollection).get();
    return snapshot.docs.map((doc) => doc.data()).toList();
  }

  // Thêm camera mới vào Firestore với giá trị mặc định
  static Future<void> addCamera({
    String? cameraId,
    required String cameraName,
    required String location,
    required String streamUrl,
    bool status = true,
  }) async {
    await FirebaseFirestore.instance.collection(configCollection).add({
      'cameraId':
          cameraId ??
          'CAM_${DateTime.now().millisecondsSinceEpoch}', // Tự động tạo cameraId duy nhất
      'cameraName': cameraName,
      'location': location,
      'streamUrl': streamUrl,
      'status': status,
    });
  }

  // Getter cho các giá trị
  static Future<String> get apiUrl =>
      Future.value(dotenv.env['API_URL'] ?? 'http://default.api');
  static Future<String> get fieldName => Future.value('image');
  static Future<int> get sampleRate => Future.value(10);

  // Hàm tiện ích để lấy Firebase token
  static Future<String?> getFirebaseToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('id_token');
  }

  // Hàm tiện ích để kiểm tra và lấy token
  static Future<String?> getAuthHeader() async {
    final token = await getFirebaseToken();
    return token != null ? 'Bearer $token' : null;
  }
}
