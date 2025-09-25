import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../widgets/bottom_nav_bar.dart';
import 'UI_alert_detail.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  _NotificationScreenState createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  final User? currentUser = FirebaseAuth.instance.currentUser;
  String _filterStatus = 'all'; // Thêm biến trạng thái để lọc

  // Hàm cập nhật trạng thái thông báo đã đọc/chưa đọc
  Future<void> _markAsRead(String alertId) async {
    if (currentUser == null) return;
    await FirebaseFirestore.instance
        .collection("users")
        .doc(currentUser!.uid)
        .collection("alerts")
        .doc(alertId)
        .set({'isRead': true}, SetOptions(merge: true));
  }

  @override
  Widget build(BuildContext context) {
    // Tạo truy vấn Firestore dựa trên trạng thái lọc
    Query query = FirebaseFirestore.instance
        .collection("users")
        .doc(currentUser?.uid)
        .collection("alerts")
        .orderBy("timestamp", descending: true);

    if (_filterStatus == 'unread') {
      // Chỉ lọc các tài liệu có isRead = false
      query = query.where('isRead', isEqualTo: false);
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFFF5E6E8),
        elevation: 0,
        title: const Text(
          'Thông báo',
          style: TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list, color: Colors.black),
            onSelected: (value) {
              setState(() {
                _filterStatus = value; // Cập nhật trạng thái lọc
              });
            },
            itemBuilder:
                (BuildContext context) => const [
                  PopupMenuItem<String>(value: 'all', child: Text('Tất cả')),
                  PopupMenuItem<String>(
                    value: 'unread',
                    child: Text('Chưa đọc'),
                  ),
                ],
          ),
        ],
      ),
      body:
          currentUser == null
              ? const Center(child: Text("Chưa đăng nhập"))
              : StreamBuilder<QuerySnapshot>(
                stream: query.snapshots(), // Sử dụng query đã được lọc
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return const Center(child: Text("Lỗi tải dữ liệu"));
                  }
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final docs = snapshot.data!.docs;

                  if (docs.isEmpty) {
                    return _buildEmptyState();
                  }

                  return ListView.builder(
                    itemCount: docs.length,
                    itemBuilder: (context, index) {
                      final docId = docs[index].id;
                      final alert = docs[index].data() as Map<String, dynamic>;
                      final alertId = docs[index].id;
                      final cameraName = alert["cameraName"] ?? "Không rõ";
                      final location = alert["location"] ?? "";
                      final type = alert["type"] ?? "";
                      final isRead = alert["isRead"] ?? false;
                      final timestamp = alert["timestamp"]?.toDate();

                      return Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        color:
                            isRead
                                ? Colors.white
                                : Colors.blue.withOpacity(
                                  0.1,
                                ), // Đổi màu nền nếu chưa đọc
                        child: ListTile(
                          leading: Icon(
                            type == "fire"
                                ? Icons.local_fire_department
                                : Icons.smoke_free,
                            color: type == "fire" ? Colors.red : Colors.grey,
                          ),
                          title: Text("Camera: $cameraName"),
                          subtitle: Text(
                            "$location\n${timestamp != null ? timestamp.toString() : ''}",
                          ),
                          isThreeLine: true,
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () {
                            // Đánh dấu đã đọc khi người dùng click
                            _markAsRead(docId);
                            // Điều hướng đến màn hình chi tiết
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (_) => AlertDetailScreen(alertId: alertId),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  );
                },
              ),
      bottomNavigationBar: BottomNavBar(
        initialIndex: 1,
        onTabChanged: (index) {},
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            height: 200,
            width: 200,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(Icons.inbox, size: 100, color: Colors.grey),
          ),
          const SizedBox(height: 30),
          const Text(
            'Không có dữ liệu.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: Colors.black87, height: 1.5),
          ),
        ],
      ),
    );
  }
}
