import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import '../screens/UI_alert_detail.dart';

class FcmService {
  static void setupFcmListener(BuildContext context) {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print("Notification: ${message.notification?.title}");
      print("Body: ${message.notification?.body}");
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      final alertId = message.data['alertId'];
      if (alertId != null) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AlertDetailScreen(alertId: alertId),
          ),
        );
      }
    });
  }
}
