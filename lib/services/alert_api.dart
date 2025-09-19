import 'dart:convert';
import 'package:frontend/models/alert.dart';
import 'package:http/http.dart' as http;
import 'api_config.dart';
import '../models/alert.dart';

class AlertApi {
  Future<List<Alert>> getAlerts(String token) async {
    final res = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/api/alerts'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (res.statusCode == 200) {
      return json.decode(res.body);
    } else {
      throw Exception('Failed to load alerts');
    }
  }
}
