import 'dart:convert';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:frontend/repositories/fcm_repository.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:frontend/services/notification_service.dart';
import '../services/auth_service.dart';
import 'UI_device.dart';
import 'UI_register.dart'; // Giả định tên file đăng ký của bạn

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String _errorMessage = '';
  bool _isLoading = false;
  bool _isVisible = false; // Để animation fade-in
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  // Màu chủ đạo (primary) và gradient cho năm 2025 style
  final primaryColor = Colors.lightBlue.shade700;
  final gradient = LinearGradient(
    colors: [Colors.lightBlue.shade50, Colors.white],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  @override
  void initState() {
    super.initState();
    // Khởi tạo AnimationController
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    // Slide animation cho các field và nút
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3), // Trượt lên từ dưới
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    // Fade animation
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeIn));

    // Trigger animation sau khi build
    Future.delayed(const Duration(milliseconds: 100), () {
      setState(() {
        _isVisible = true;
        _controller.forward();
      });
    });
  }

  // --------------------------------------------------
  // LOGIC XỬ LÝ (KHÔNG THAY ĐỔI)
  // --------------------------------------------------
  Future<void> _login() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final userCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(
            email: _emailController.text.trim(),
            password: _passwordController.text.trim(),
          );

      final user = userCredential.user;
      if (user != null) {
        final notificationService = NotificationService();
        await notificationService.initialize();
        bool hasPermission = await notificationService.requestPermission();

        await FcmRepository.saveFcmToken(user.uid);
        final fcmToken = await FirebaseMessaging.instance.getToken();
        print("🔥 FCM Token (client): $fcmToken");

        final idToken = await user.getIdToken();

        await http.post(
          Uri.parse("http://<IP_BACKEND>:3000/users/update-token"),
          headers: {
            "Authorization": "Bearer $idToken",
            "Content-Type": "application/json",
          },
          body: jsonEncode({"fcmToken": fcmToken}),
        );

        print("🔥 Token đã cập nhật lên backend!");
        if (hasPermission) {
          print("FCM token đã lưu vào Firestore cho user ${user.uid}");

          final idToken = await user.getIdToken();
          if (idToken != null) {
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString('id_token', idToken);
            print(
              'Login successful, token saved: ${idToken.substring(0, 10)}...',
            );
          }
        }

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
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  // 🚀 LOGIC ĐIỀU HƯỚNG ĐẾN TRANG ĐĂNG KÝ
  void _navigateToRegisterScreen() {
    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const RegisterScreen()),
      );
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _controller.dispose();
    super.dispose();
  }

  // --------------------------------------------------
  // UI HELPER: TextField với neumorphic style
  // --------------------------------------------------
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    bool obscureText = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color:
            Theme.of(context).brightness == Brightness.dark
                ? Colors.grey.shade800
                : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        obscureText: obscureText,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w400),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
            color: primaryColor.withOpacity(0.8),
            fontWeight: FontWeight.w500,
          ),
          prefixIcon: Icon(icon, color: primaryColor),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(
            vertical: 18,
            horizontal: 20,
          ),
        ),
      ),
    );
  }

  // --------------------------------------------------
  // UI BUILD
  // --------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true, // Để gradient phủ đầy
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        // leading: IconButton(
        //   icon: const Icon(Icons.arrow_back, color: Colors.black87),
        //   onPressed: () => Navigator.pop(context),
        // ),
      ),
      body: Container(
        decoration: BoxDecoration(gradient: gradient), // Gradient background
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: 28.0,
              vertical: 20.0,
            ),
            child: AnimatedOpacity(
              opacity: _isVisible ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 800),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 1. Icon / Logo với animation scale
                  AnimatedScale(
                    scale: _isVisible ? 1.0 : 0.8,
                    duration: const Duration(milliseconds: 600),
                    child: Icon(
                      Icons.security_update_good,
                      size: 90,
                      color: primaryColor,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // 2. Tiêu đề với font hệ thống
                  const Text(
                    'Đăng nhập Hệ thống',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Chào mừng trở lại! Vui lòng nhập thông tin của bạn.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  const SizedBox(height: 48),

                  // 3. Trường nhập Email với slide animation
                  SlideTransition(
                    position: _slideAnimation,
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: _buildTextField(
                        controller: _emailController,
                        label: 'Email',
                        icon: Icons.email,
                        keyboardType: TextInputType.emailAddress,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // 4. Trường nhập Mật khẩu với slide animation
                  SlideTransition(
                    position: _slideAnimation,
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: _buildTextField(
                        controller: _passwordController,
                        label: 'Mật khẩu',
                        icon: Icons.lock,
                        obscureText: true,
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // 5. Thông báo lỗi với animation
                  AnimatedOpacity(
                    opacity: _errorMessage.isNotEmpty ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 300),
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Text(
                        _errorMessage,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.red.shade700,
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ),

                  // 6. Nút Đăng nhập chính với elevation và scale animation khi nhấn
                  _isLoading
                      ? Center(
                        child: CircularProgressIndicator(color: primaryColor),
                      )
                      : SlideTransition(
                        position: _slideAnimation,
                        child: FadeTransition(
                          opacity: _fadeAnimation,
                          child: GestureDetector(
                            onTapDown: (_) {
                              _controller.reverse().then(
                                (_) => _controller.forward(),
                              );
                            },
                            child: AnimatedScale(
                              scale: _isLoading ? 0.95 : 1.0,
                              duration: const Duration(milliseconds: 100),
                              child: ElevatedButton(
                                onPressed: _login,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: primaryColor,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 18,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  elevation: 6,
                                  shadowColor: primaryColor.withOpacity(0.4),
                                ),
                                child: const Text(
                                  'Đăng nhập',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),

                  const SizedBox(height: 24),

                  // 7. Liên kết Đăng ký với slide animation
                  SlideTransition(
                    position: _slideAnimation,
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: TextButton(
                        onPressed: _navigateToRegisterScreen,
                        child: RichText(
                          textAlign: TextAlign.center,
                          text: TextSpan(
                            text: 'Chưa có tài khoản? ',
                            style: TextStyle(
                              color: primaryColor,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                            children: [
                              TextSpan(
                                text: 'Đăng ký ngay',
                                style: TextStyle(
                                  color: primaryColor,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
