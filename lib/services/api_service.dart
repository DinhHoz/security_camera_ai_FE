import 'camera_api.dart';
import 'alert_api.dart';
import 'auth_api.dart';
import 'fcm_api.dart';

class ApiService {
  final camera = CameraApi();
  final alert = AlertApi();
  final auth = AuthApi();
  final fcm = FcmApi();
}
