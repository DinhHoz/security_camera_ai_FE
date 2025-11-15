import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:frontend/screens/UI_notification.dart';
import 'package:frontend/screens/UI_profile.dart';
// import 'package:shared_preferences/shared_preferences.dart'; // KHÔNG CẦN DÙNG
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../widgets/bottom_nav_bar.dart';
import '../screens/UI_Add_Camera.dart';
import '../screens/CameraStreamScreen.dart';
import '../models/camera.dart';
import '../models/alert.dart';

class DeviceScreen extends StatefulWidget {
  const DeviceScreen({super.key});

  @override
  _DeviceScreenState createState() => _DeviceScreenState();
}

class _DeviceScreenState extends State<DeviceScreen> {
  // Thay đổi List thành Stream để nghe sự thay đổi của Firestore
  // Điều này giúp tự động cập nhật danh sách camera khi có thay đổi trên cloud
  Stream<List<Camera>>? _cameraStream;
  List<Alert> _alerts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _setupCameraStream(); // Thay thế _loadCameras
    _loadAlerts();
  }

  // Thay thế _loadCameras() bằng cách lắng nghe Stream từ Firestore
  void _setupCameraStream() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() {
        _isLoading = false;
      });
      return;
    }

    // Thiết lập Stream để lắng nghe thay đổi Realtime trên Firestore
    _cameraStream = FirebaseFirestore.instance
        .collection("users")
        .doc(user.uid)
        .collection("cameras")
        .snapshots() // Lắng nghe thay đổi
        .map((snapshot) {
          // Khi có dữ liệu mới, ánh xạ dữ liệu thành danh sách Camera
          return snapshot.docs.map((doc) {
            final data = doc.data();
            return Camera(
              id: doc.id,
              cameraName: data['cameraName'] ?? 'Camera',
              location: data['location'] ?? 'Không rõ',
              streamUrl: data['streamUrl'] ?? '',
            );
          }).toList();
        });
  }

  // Hàm này vẫn giữ nguyên để lấy cảnh báo chưa đọc
  Future<void> _loadAlerts() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() {
        _isLoading = false;
      });
      return;
    }

    final snapshot =
        await FirebaseFirestore.instance
            .collection("users")
            .doc(user.uid)
            .collection("alerts")
            .where('isRead', isEqualTo: false)
            .get();

    setState(() {
      _alerts = snapshot.docs.map((doc) => Alert.fromJson(doc.data())).toList();
      _isLoading = false;
    });
  }

  void _navigateToAddCameraScreen() async {
    // Sau khi thêm thành công, stream sẽ tự động cập nhật, không cần gọi _loadCameras()
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddCameraScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(80.0),
        child: Padding(
          padding: const EdgeInsets.only(top: 20.0),
          child: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            automaticallyImplyLeading: false,
            title: const Text(
              'Thiết bị',
              style: TextStyle(
                color: Colors.black,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(
                  Icons.add_circle_outline,
                  color: Colors.lightBlue,
                  size: 30.0,
                ),
                onPressed: _navigateToAddCameraScreen,
              ),
              Stack(
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.notifications_none,
                      color: Colors.lightBlue,
                      size: 30.0,
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const NotificationScreen(),
                        ),
                      );
                    },
                  ),
                  if (_alerts.isNotEmpty)
                    Positioned(
                      right: 10,
                      top: 10,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 12,
                          minHeight: 12,
                        ),
                        child: Text(
                          _alerts.length.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 8,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 16.0),
            ],
          ),
        ),
      ),
      // SỬ DỤNG StreamBuilder ĐỂ XỬ LÝ DỮ LIỆU REALTIME TỪ FIRESTORE
      body: StreamBuilder<List<Camera>>(
        stream: _cameraStream,
        builder: (context, snapshot) {
          if (_isLoading ||
              snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Lỗi tải dữ liệu: ${snapshot.error}'));
          }

          final cameras = snapshot.data ?? [];
          final camerasToShow = cameras.take(6).toList(); // Giới hạn 4 camera

          if (cameras.isEmpty) {
            return const Center(
              child: Text(
                'Chưa có camera nào. Thêm mới để bắt đầu!',
                style: TextStyle(fontSize: 16, color: Colors.black87),
              ),
            );
          }

          // Hiển thị GridView 2x2
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2, // 2 cột
                crossAxisSpacing: 16.0, // Khoảng cách ngang
                mainAxisSpacing: 16.0, // Khoảng cách dọc
                childAspectRatio: 1.0, // Tỷ lệ khung hình vuông (1:1)
              ),
              itemCount: camerasToShow.length, // Chỉ hiển thị tối đa 4 cam
              itemBuilder: (context, index) {
                final cam = camerasToShow[index];
                return GestureDetector(
                  onTap: () {
                    // Khi chạm vào, chuyển sang màn hình xem trực tiếp
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => CameraStreamScreen(camera: cam),
                      ),
                    );
                  },
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Stack(
                      alignment: Alignment.bottomLeft,
                      children: [
                        // Ảnh nền hoặc fallback (Giả định)
                        Image.asset(
                          "assets/warehouse${index + 1}.jpg",
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: double.infinity,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: Colors.grey[300],
                              child: const Center(
                                child: Icon(
                                  Icons.videocam,
                                  size: 50,
                                  color: Colors.black54,
                                ),
                              ),
                            );
                          },
                        ),
                        // Tên camera + trạng thái
                        Container(
                          margin: const EdgeInsets.all(8),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black45,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.circle,
                                size: 10,
                                color: Colors.red, // Trạng thái giả định
                              ),
                              const SizedBox(width: 5),
                              Text(
                                cam.cameraName,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
      bottomNavigationBar: BottomNavBar(
        initialIndex: 0,
        onTabChanged: (index) {
          switch (index) {
            case 0:
              break;
            case 1:
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const NotificationScreen()),
              );
              break;
            case 2:
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const ProfileScreen()),
              );
              break;
          }
        },
      ),
    );
  }
}
