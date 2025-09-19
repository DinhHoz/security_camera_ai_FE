import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/login_screen.dart';
import 'screens/UI_device.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print("Handling a background message: ${message.messageId}");
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load biến từ .env
  // await dotenv.load(fileName: ".env");

  // Khởi tạo Firebase
  await Firebase.initializeApp();

  // Đăng ký background handler cho FCM
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Firebase Auth Demo',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const AuthWrapper(),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  // Hàm kiểm tra token từ SharedPreferences (để đảm bảo tính nhất quán)
  Future<bool> _hasValidToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('id_token');
      return token != null && token.isNotEmpty;
    } catch (e) {
      print('Lỗi khi kiểm tra token: $e');
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Hiển thị loading trong khi đang kiểm tra trạng thái
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // Nếu có lỗi, fallback về LoginScreen
        if (snapshot.hasError) {
          print('Lỗi trong StreamBuilder: ${snapshot.error}');
          return const LoginScreen();
        }

        final user = snapshot.data;

        // Nếu không có user (chưa đăng nhập), gọi LoginScreen
        if (user == null) {
          print('Không có user, chuyển đến LoginScreen');
          return const LoginScreen();
        }

        // Nếu có user, kiểm tra thêm token để đảm bảo hợp lệ
        return FutureBuilder<bool>(
          future: _hasValidToken(),
          builder: (context, tokenSnapshot) {
            if (tokenSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            if (tokenSnapshot.hasError || !tokenSnapshot.data!) {
              print('Token không hợp lệ, chuyển đến LoginScreen');
              // Tùy chọn: Xóa token nếu không hợp lệ
              _clearInvalidToken();
              return const LoginScreen();
            }

            // Token hợp lệ, chuyển đến DeviceScreen
            print('User và token hợp lệ, chuyển đến DeviceScreen');
            return const DeviceScreen();
          },
        );
      },
    );
  }

  // Hàm xóa token nếu không hợp lệ (tùy chọn, để tránh lặp lại lỗi)
  Future<void> _clearInvalidToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('id_token');
    } catch (e) {
      print('Lỗi khi xóa token: $e');
    }
  }
}

// import 'package:flutter/material.dart';
// import 'screens/UI_notification.dart';
// import 'screens/UI_device.dart'; // Import DeviceScreen

// void main() {
//   runApp(MyApp());
// }

// class MyApp extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       title: 'Device Screen Demo',
//       theme: ThemeData(primarySwatch: Colors.blue),
//       home: const NotificationScreen(), // Khởi chạy DeviceScreen
//       debugShowCheckedModeBanner: false, // Tắt banner debug
//     );
//   }
// }
