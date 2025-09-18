import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'api_config.dart';

class AuthApi {
  Future<String> verifyIdToken(String idToken) async {
    final res = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/api/auth/login'),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"idToken": idToken}),
    );
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      return data['token'] as String; // Nếu backend trả token mới
    } else {
      throw Exception("Verification failed: ${res.body}");
    }
  }
}