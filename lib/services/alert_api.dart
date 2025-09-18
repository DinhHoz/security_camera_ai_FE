import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../models/alert.dart';
import 'api_config.dart';

class AlertApi {
  Future<List<Alert>> getAlerts() async {
    final res = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/alerts'),
      headers: ApiConfig.headers,
    );

    if (res.statusCode == 200) {
      final List data = jsonDecode(res.body);
      return data.map((e) => Alert.fromJson(e)).toList();
    } else {
      throw Exception("Failed to load alerts: ${res.statusCode}");
    }
  }
}
