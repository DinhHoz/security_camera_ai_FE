import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:http/http.dart' as http;
import 'login_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _nameController = TextEditingController();

  String _errorMessage = '';
  bool _isLoading = false;
  bool _isVisible = false;

  final primaryColor = Colors.lightBlue.shade700;
  final gradient = LinearGradient(
    colors: [Colors.lightBlue.shade50, Colors.white],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 100), () {
      setState(() => _isVisible = true);
    });
  }

  // ============================================================
  // 🔥 ĐĂNG KÝ → LƯU USER VÀO FIRESTORE (đúng như hình bạn muốn)
  // ============================================================
  Future<void> _register() async {
    if (_passwordController.text.trim() !=
        _confirmPasswordController.text.trim()) {
      setState(() {
        _errorMessage = 'Mật khẩu và Xác nhận mật khẩu không khớp.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = "";
    });

    try {
      final credential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
            email: _emailController.text.trim(),
            password: _passwordController.text.trim(),
          );

      final user = credential.user;
      if (user == null) {
        setState(() => _errorMessage = "Không thể tạo user!");
        return;
      }

      // 🔥 Lấy FCM token
      final fcmToken = await FirebaseMessaging.instance.getToken();

      // 🔥 Tự đặt tên nếu user không nhập
      final name =
          _nameController.text.trim().isEmpty
              ? _emailController.text.trim().split("@").first
              : _nameController.text.trim();

      // =====================================================
      // 🔥 LƯU FIRESTORE: users/{uid}
      // =====================================================
      await FirebaseFirestore.instance.collection("users").doc(user.uid).set({
        "email": _emailController.text.trim(),
        "name": name,
        "role": "user",
        "fcmToken": fcmToken,
        "updatedAt": DateTime.now(),
      });

      // =====================================================
      // 🔥 Gửi token lên backend nếu bạn muốn (dùng .env)
      // =====================================================
      final apiBase = dotenv.env["API_BACKEND_URL"]!;
      final idToken = await user.getIdToken();

      await http.post(
        Uri.parse("$apiBase/users/update-token"),
        headers: {
          "Authorization": "Bearer $idToken",
          "Content-Type": "application/json",
        },
        body: jsonEncode({"fcmToken": fcmToken}),
      );

      // Chuyển về login
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Đăng ký thành công! Hãy đăng nhập.")),
        );

        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
      }
    } on FirebaseAuthException catch (e) {
      setState(() => _errorMessage = _friendlyError(e.code));
    } catch (e) {
      setState(() => _errorMessage = "Lỗi không xác định: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _friendlyError(String code) {
    switch (code) {
      case "weak-password":
        return "Mật khẩu quá yếu.";
      case "email-already-in-use":
        return "Email đã tồn tại.";
      case "invalid-email":
        return "Email không hợp lệ.";
      default:
        return "Đăng ký thất bại.";
    }
  }

  Widget _input({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool obscure = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            blurRadius: 10,
            offset: const Offset(0, 4),
            color: Colors.black.withOpacity(0.05),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        obscureText: obscure,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: primaryColor),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 18),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: BackButton(color: Colors.black87),
      ),
      body: Container(
        decoration: BoxDecoration(gradient: gradient),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
            child: AnimatedOpacity(
              opacity: _isVisible ? 1 : 0,
              duration: const Duration(milliseconds: 800),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Icon
                  AnimatedScale(
                    scale: _isVisible ? 1 : 0.8,
                    duration: const Duration(milliseconds: 600),
                    child: Icon(
                      Icons.person_add,
                      size: 90,
                      color: primaryColor,
                    ),
                  ),
                  const SizedBox(height: 32),

                  const Text(
                    "Tạo tài khoản mới",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // FULL INPUTS
                  _input(
                    controller: _nameController,
                    label: "Tên người dùng",
                    icon: Icons.person,
                  ),
                  const SizedBox(height: 20),

                  _input(
                    controller: _emailController,
                    label: "Email",
                    icon: Icons.email,
                  ),
                  const SizedBox(height: 20),

                  _input(
                    controller: _passwordController,
                    label: "Mật khẩu",
                    icon: Icons.lock,
                    obscure: true,
                  ),
                  const SizedBox(height: 20),

                  _input(
                    controller: _confirmPasswordController,
                    label: "Nhập lại mật khẩu",
                    icon: Icons.lock_outline,
                    obscure: true,
                  ),

                  const SizedBox(height: 20),

                  // ERROR
                  if (_errorMessage.isNotEmpty)
                    Text(
                      _errorMessage,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.red.shade700,
                        fontWeight: FontWeight.w600,
                      ),
                    ),

                  const SizedBox(height: 20),

                  // BUTTON
                  _isLoading
                      ? Center(
                        child: CircularProgressIndicator(color: primaryColor),
                      )
                      : ElevatedButton(
                        onPressed: _register,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Text(
                          "Đăng ký",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),

                  const SizedBox(height: 25),

                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      "Đã có tài khoản? Đăng nhập",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: primaryColor,
                        fontSize: 16,
                        decoration: TextDecoration.underline,
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
