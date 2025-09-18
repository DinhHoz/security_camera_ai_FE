import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import 'login_screen.dart';
import '../screens/cameras_screen.dart'; // Thêm import

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _idToken = 'Đang tải...';
  String _userEmail = 'Đang tải...';

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('id_token');
    final user = FirebaseAuth.instance.currentUser;

    setState(() {
      _idToken = token ?? 'Không tìm thấy token';
      _userEmail = user?.email ?? 'Không tìm thấy email';
    });

    if (kDebugMode) {
      print(
        'Loaded token: ${_idToken.substring(0, token != null ? 10 : _idToken.length)}...',
      );
      print('User email: $_userEmail');
    }
  }

  Future<void> _logout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('id_token');
      await FirebaseAuth.instance.signOut();

      if (kDebugMode) {
        print('Logged out successfully');
      }

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error during logout: $e');
      }
    }
  }

  void _navigateToCamera() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CameraScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Trang chủ'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
            tooltip: 'Đăng xuất',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Email: $_userEmail', style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 16),
            Text(
              'ID Token: ${_idToken.length > 50 ? "${_idToken.substring(0, 50)}..." : _idToken}',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _navigateToCamera,
              child: const Text('Mở Camera'),
            ),
          ],
        ),
      ),
    );
  }
}
