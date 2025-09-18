import 'package:http/http.dart' as http;
import 'dart:convert';
import '../services/api_config.dart';

class FcmApi {
  Future<void> registerFcmToken(String fcmToken) async {
    try {
      final url =
          "${ApiConfig.getBaseUrl()}/api/auth/register"; // Endpoint backend để đăng ký FCM token
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'fcm_token': fcmToken}),
      );
      if (response.statusCode != 200) {
        print("Failed to register FCM token: ${response.body}");
      }
    } catch (e) {
      print("FCM registration error: $e");
    }
  }
}
