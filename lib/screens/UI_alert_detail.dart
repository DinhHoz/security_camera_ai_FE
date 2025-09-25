import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AlertDetailScreen extends StatelessWidget {
  final String alertId;

  const AlertDetailScreen({super.key, required this.alertId});

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      return const Scaffold(body: Center(child: Text("Chưa đăng nhập")));
    }

    final uid = currentUser.uid;
    final alertRef = FirebaseFirestore.instance
        .collection("users")
        .doc(uid)
        .collection("alerts")
        .doc(alertId);

    return Scaffold(
      appBar: AppBar(title: const Text("Alert Detail")),
      body: FutureBuilder<DocumentSnapshot>(
        future: alertRef.get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text("Alert không tồn tại"));
          }

          final data = snapshot.data!.data() as Map<String, dynamic>? ?? {};
          final timestamp = data['timestamp'];
          final timeString =
              timestamp is Timestamp
                  ? timestamp.toDate().toString()
                  : timestamp is String
                  ? DateTime.parse(timestamp).toString()
                  : 'Unknown Time';

          // Cập nhật trạng thái isRead khi xem
          _updateReadStatus(alertRef);

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Text(
                    "📷 Camera: ${data['cameraName'] ?? 'Unknown'}",
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 12),
                  Text("🆔 Camera ID: ${data['cameraId'] ?? ''}"),
                  Text("📍 Location: ${data['location'] ?? ''}"),
                  Text("🔥 Type: ${data['type'] ?? ''}"),
                  Text("⏰ Time: $timeString"),
                  const SizedBox(height: 16),
                  if (data['imageUrl'] != null)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        data['imageUrl'],
                        fit: BoxFit.cover,
                        errorBuilder:
                            (context, error, stackTrace) =>
                                const Icon(Icons.broken_image, size: 80),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // Cập nhật trạng thái isRead
  Future<void> _updateReadStatus(DocumentReference alertRef) async {
    try {
      await alertRef.update({'isRead': true});
      print("✅ Đã cập nhật trạng thái isRead cho alert: $alertId");
    } catch (e) {
      print("❌ Lỗi cập nhật isRead: $e");
    }
  }
}
