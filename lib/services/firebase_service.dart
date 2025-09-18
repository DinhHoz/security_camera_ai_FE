import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class FirebaseService {
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;

  Future<void> initFCM(BuildContext context) async {
    // Lấy token
    final token = await _fcm.getToken();
    print("FCM Token: $token");

    // Gửi token lên backend
    if (token != null) {
      await http.post(
        Uri.parse("http://192.168.2.28:3000/api/auth/register"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"token": token}),
      );
    }

    // Lắng nghe khi app đang mở
    FirebaseMessaging.onMessage.listen((msg) {
      final notification = msg.notification;
      if (notification != null) {
        // Hiển thị SnackBars
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("${notification.title}\n${notification.body}"),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );

        // Hoặc hiển thị Dialog
        showDialog(
          context: context,
          builder:
              (context) => AlertDialog(
                title: Text(notification.title ?? "Thông báo"),
                content: Text(notification.body ?? "Không có nội dung"),
                actions: [
                  TextButton(
                    child: const Text("Đóng"),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
        );
      }
    });
  }
}
