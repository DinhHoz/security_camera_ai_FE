import 'dart:async';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../services/fcm_api.dart'; // Giả định file xử lý API FCM
import '../screens/cameras_screen.dart'; // Để điều hướng đến DetectionViewScreen

class FcmHandler {
  final FcmApi _fcmApi = FcmApi(); // Giả định class xử lý API FCM

  void initializeFcm(BuildContext context) {
    _setupFCM(context);
  }

  Future<void> _setupFCM(BuildContext context) async {
    // Yêu cầu quyền thông báo
    NotificationSettings settings = await FirebaseMessaging.instance
        .requestPermission(alert: true, badge: true, sound: true);
    if (kDebugMode)
      print('User granted permission: ${settings.authorizationStatus}');

    // Lấy FCM token và gửi đến backend
    String? fcmToken = await FirebaseMessaging.instance.getToken();
    if (fcmToken != null) {
      await _fcmApi.registerFcmToken(fcmToken);
      if (kDebugMode)
        print('FCM Token registered: ${fcmToken.substring(0, 10)}...');
    }

    // Xử lý thông báo khi ứng dụng đang mở (foreground)
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (kDebugMode)
        print('Received foreground message: ${message.notification?.title}');
      _handleRemoteAlert(context, message);
    });

    // Xử lý khi người dùng tap vào thông báo (khi ứng dụng tắt hoặc mở)
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      if (kDebugMode)
        print('Message opened app: ${message.notification?.title}');
      _handleRemoteAlert(context, message);
    });

    // Xử lý khi ứng dụng khởi động từ thông báo đã kill
    RemoteMessage? initialMessage =
        await FirebaseMessaging.instance.getInitialMessage();
    if (initialMessage != null) {
      _handleRemoteAlert(context, initialMessage);
    }
  }

  void _handleRemoteAlert(BuildContext context, RemoteMessage message) {
    final String? title = message.notification?.title;
    final String? body = message.notification?.body;
    final String? imageUrl = message.data['image_url'];
    final String? detectionType = message.data['detection_type'];
    final String? confidence = message.data['confidence'];

    if (title != null && body != null && detectionType != null) {
      _showAlertWithImage(
        context,
        title,
        body,
        imageUrl,
        detectionType,
        confidence,
      );
    }
  }

  void _showAlertWithImage(
    BuildContext context,
    String title,
    String body,
    String? imageUrl,
    String detectionType,
    String? confidence,
  ) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(title),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(body),
                if (confidence != null) Text("Độ tin cậy: $confidence%"),
                if (imageUrl != null && imageUrl.isNotEmpty)
                  FutureBuilder(
                    future: _loadImage(imageUrl),
                    builder: (context, snapshot) {
                      if (snapshot.hasData) {
                        return Image.network(
                          imageUrl,
                          height: 200,
                          fit: BoxFit.cover,
                        );
                      } else {
                        return const CircularProgressIndicator();
                      }
                    },
                  ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _navigateToDetectionView(context, detectionType, imageUrl);
                },
                child: const Text("Xem Camera & Ảnh"),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Đóng"),
              ),
            ],
          ),
    );
  }

  Future<Widget> _loadImage(String url) async {
    return Image.network(
      url,
      errorBuilder: (context, error, stackTrace) {
        return const Text("Không tải được ảnh");
      },
    );
  }

  void _navigateToDetectionView(
    BuildContext context,
    String detectionType,
    String? imageUrl,
  ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (_) => DetectionViewScreen(
              detectionType: detectionType,
              imageUrl: imageUrl,
            ),
      ),
    );
  }
}

// Màn hình xem chi tiết phát hiện (DetectionViewScreen)
class DetectionViewScreen extends StatelessWidget {
  final String detectionType;
  final String? imageUrl;

  const DetectionViewScreen({
    super.key,
    required this.detectionType,
    this.imageUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Chi tiết: $detectionType")),
      body: Column(
        children: [
          const Text("Mở camera để xem trực tiếp"),
          if (imageUrl != null)
            Expanded(
              child: Image.network(
                imageUrl!,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return const Text("Không tải được ảnh từ Cloudinary");
                },
              ),
            ),
        ],
      ),
    );
  }
}
