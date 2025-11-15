import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AlertDetailScreen extends StatelessWidget {
  final String alertId;

  const AlertDetailScreen({super.key, required this.alertId});

  static const Color primaryColor = Colors.lightBlue;
  static const Color secondaryColor = Colors.lightBlueAccent;

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
      backgroundColor: Colors.grey.shade100,
      body: FutureBuilder<DocumentSnapshot>(
        future: alertRef.get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(color: primaryColor),
            );
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text("Alert không tồn tại"));
          }

          final data = snapshot.data!.data() as Map<String, dynamic>? ?? {};
          final timestamp = data['timestamp'];
          final timeString =
              timestamp is Timestamp
                  ? _formatTimestamp(timestamp)
                  : timestamp is String
                  ? _formatTimestamp(
                    Timestamp.fromDate(DateTime.parse(timestamp)),
                  )
                  : 'Unknown Time';

          WidgetsBinding.instance.addPostFrameCallback((_) {
            _updateReadStatus(alertRef);
          });

          return _buildDetailedUI(context, data, timeString);
        },
      ),
    );
  }

  Widget _buildDetailedUI(
    BuildContext context,
    Map<String, dynamic> data,
    String timeString,
  ) {
    final title = data['cameraName'] ?? 'Chi tiết Cảnh báo';
    final imageUrl = data['imageUrl'];

    return CustomScrollView(
      slivers: <Widget>[
        SliverAppBar(
          title: Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
          backgroundColor: primaryColor,
          floating: true,
          pinned: true,
          elevation: 4,
        ),
        SliverList(
          delegate: SliverChildListDelegate([
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Card chứa thông tin chính (chữ nhỏ hơn)
                  Card(
                    elevation: 6,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildInfoRow(
                            icon: Icons.flash_on,
                            label: "Loại Cảnh báo",
                            value: data['type'] ?? 'Không xác định',
                            color: Colors.redAccent,
                            fontSize: 14, // Giảm cỡ chữ
                          ),
                          _buildDivider(),
                          _buildInfoRow(
                            icon: Icons.access_time,
                            label: "Thời gian",
                            value: timeString,
                            color: secondaryColor,
                            fontSize: 14, // Giảm cỡ chữ
                          ),
                          _buildDivider(),
                          _buildInfoRow(
                            icon: Icons.location_on,
                            label: "Vị trí",
                            value: data['location'] ?? 'N/A',
                            color: Colors.green,
                            fontSize: 14, // Giảm cỡ chữ
                          ),
                          _buildDivider(),
                          _buildInfoRow(
                            icon: Icons.camera_alt,
                            label: "ID Camera",
                            value: data['cameraId'] ?? 'N/A',
                            color: Colors.grey.shade600,
                            fontSize: 14, // Giảm cỡ chữ
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 30),

                  // Hình ảnh (to hơn)
                  if (imageUrl != null)
                    Hero(
                      tag: 'alert_image_$alertId',
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: FadeInImage.assetNetwork(
                          placeholder: 'assets/placeholder.png',
                          image: imageUrl,
                          fit: BoxFit.cover,
                          height:
                              300, // ✅ Tăng chiều cao của ảnh (từ 200 lên 300)
                          width: double.infinity,
                          imageErrorBuilder:
                              (context, error, stackTrace) => Container(
                                color: primaryColor,
                                height: 300, // ✅ Cập nhật chiều cao lỗi ảnh
                                child: const Center(
                                  child: Icon(
                                    Icons.broken_image,
                                    size: 80,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                        ),
                      ),
                    ),
                  if (imageUrl != null) const SizedBox(height: 30),

                  // Nút hành động
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("Đang mở hành động liên quan..."),
                          ),
                        );
                      },
                      icon: const Icon(Icons.videocam, size: 24),
                      label: const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12.0),
                        child: Text(
                          "Xem lại video",
                          style: TextStyle(fontSize: 18),
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 8,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ]),
        ),
      ],
    );
  }

  // Helper Widgets - Đã thêm tham số fontSize
  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    double fontSize = 16, // ✅ Thêm tham số fontSize mặc định 16
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: fontSize * 0.9,
                  color: Colors.grey,
                ), // Label nhỏ hơn chút so với value
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  fontSize: fontSize, // ✅ Sử dụng fontSize được truyền vào
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 4.0),
      child: Divider(height: 1, color: Colors.black12),
    );
  }

  Future<void> _updateReadStatus(DocumentReference alertRef) async {
    try {
      await alertRef.update({'isRead': true});
      print("✅ Đã cập nhật trạng thái isRead cho alert: $alertId");
    } catch (e) {
      print("❌ Lỗi cập nhật isRead: $e");
    }
  }

  String _formatTimestamp(Timestamp timestamp) {
    final dateTime = timestamp.toDate();
    return "${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')} - ${dateTime.day.toString().padLeft(2, '0')}/${dateTime.month.toString().padLeft(2, '0')}/${dateTime.year}";
  }
}
