import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../models/camera.dart';
import 'api_config.dart';

class CameraApi {
  Future<List<Camera>> getCameras() async {
    final res = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/cameras'),
      headers: ApiConfig.headers,
    );

    if (res.statusCode == 200) {
      final List data = jsonDecode(res.body);
      return data.map((e) => Camera.fromJson(e)).toList();
    } else {
      throw Exception("Failed to load cameras: ${res.statusCode}");
    }
  }

  Future<String> detectFireSmoke(String cameraId) async {
    final res = await http.post(
      Uri.parse("${ApiConfig.baseUrl}/cameras/$cameraId/detect"),
      headers: ApiConfig.headers,
    );

    if (res.statusCode == 200) {
      final data = json.decode(res.body);
      return data['result'] ?? "UNKNOWN";
    } else {
      throw Exception("Failed to detect fire/smoke: ${res.statusCode}");
    }
  }
}
