import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';  // Để lưu token nếu cần

class AuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static String? _token;

  // Đăng nhập với email/password
  static Future<String?> signInWithEmailAndPassword(String email, String password) async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(email: email, password: password);
      final idToken = await userCredential.user?.getIdToken();  // Lấy ID token
      _token = idToken;
      // Lưu token vào SharedPreferences nếu cần
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_token', _token!);
      return _token;
    } catch (e) {
      print('Sign-in error: $e');
      return null;
    }
  }

  // Lấy ID token hiện tại (gọi sau khi đăng nhập)
  static Future<String?> getToken() async {
    final user = _auth.currentUser;
    if (user != null) {
      _token = await user.getIdToken();  // Lấy token mới nhất (tự động refresh nếu cần)
      return _token;
    }
    // Nếu chưa có, tải từ SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('auth_token');
    return _token;
  }

  // Đăng xuất
  static Future<void> signOut() async {
    await _auth.signOut();
    _token = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
  }

  // Listener cho thay đổi token (tự động cập nhật)
  static Stream<User?> get authStateChanges => _auth.authStateChanges();
}