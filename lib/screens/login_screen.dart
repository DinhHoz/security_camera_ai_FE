import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:frontend/repositories/fcm_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:frontend/services/notification_service.dart'; // Thêm import
import '../services/auth_service.dart';
import 'UI_device.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String _errorMessage = '';
  bool _isLoading = false;

  Future<void> _login() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      // Đăng nhập với Firebase
      final userCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(
            email: _emailController.text.trim(),
            password: _passwordController.text.trim(),
          );

      // --- Sắp xếp lại logic ở đây ---
      final user = userCredential.user;
      if (user != null) {
        // 1. Khởi tạo NotificationService và yêu cầu quyền thông báo
        final notificationService = NotificationService();
        await notificationService.initialize();
        bool hasPermission = await notificationService.requestPermission();

        // 2. Nếu có quyền, lưu token FCM và token đăng nhập
        await FcmRepository.saveFcmToken(user.uid);
        if (hasPermission) {
          await FcmRepository.saveFcmToken(user.uid);
          print("FCM token đã lưu vào Firestore cho user ${user.uid}");

          // Lấy ID token và lưu vào SharedPreferences
          final idToken = await user.getIdToken();
          if (idToken != null) {
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString('id_token', idToken);
            print(
              'Login successful, token saved: ${idToken.substring(0, 10)}...',
            );
          }
        }

        // 3. Chuyển đến DeviceScreen sau khi hoàn tất các bước
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const DeviceScreen()),
          );
        }
      } else {
        setState(() {
          _errorMessage = 'Không thể lấy thông tin người dùng';
        });
      }
    } on FirebaseAuthException catch (e) {
      setState(() {
        _errorMessage = e.message ?? 'Đã xảy ra lỗi khi đăng nhập';
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Lỗi không xác định: $e';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _logout(BuildContext context) async {
    await AuthService.signOut();
    // Sau khi xóa token & password -> quay lại màn hình Login
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Đăng nhập')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: 'Email'),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(labelText: 'Mật khẩu'),
              obscureText: true,
            ),
            const SizedBox(height: 16),
            if (_errorMessage.isNotEmpty)
              Text(_errorMessage, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 16),
            _isLoading
                ? const CircularProgressIndicator()
                : ElevatedButton(
                  onPressed: _login,
                  child: const Text('Đăng nhập'),
                ),
          ],
        ),
      ),
    );
  }
}
