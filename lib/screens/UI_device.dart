import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:frontend/screens/UI_notification.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
  List<Camera> _cameras = [];
  List<Alert> _alerts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCameras();
    _loadAlerts();
  }

  Future<void> _loadCameras() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> saved = prefs.getStringList('cameras') ?? [];
    setState(() {
      _cameras =
          saved.map((c) {
            try {
              final data = jsonDecode(c) as Map<String, dynamic>;
              return Camera(
                id:
                    data['id'] ??
                    DateTime.now().millisecondsSinceEpoch.toString(),
                cameraName: data['cameraName'] ?? 'Camera',
                location: data['location'] ?? 'Không rõ',
                streamUrl: data['streamUrl'] ?? '',
              );
            } catch (e) {
              print("Lỗi giải mã camera: $e");
              return Camera(
                id: DateTime.now().millisecondsSinceEpoch.toString(),
                cameraName: 'Camera lỗi',
                location: 'Không rõ',
                streamUrl: '',
              );
            }
          }).toList();
    });
  }

  Future<void> _loadAlerts() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

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
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddCameraScreen()),
    );
    if (result == true) {
      _loadCameras();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.menu, color: Colors.black),
          onPressed: () {},
        ),
        title: const Text(
          'Thiết bị',
          style: TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Colors.black),
            onPressed: _navigateToAddCameraScreen,
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFF5F5F5), Colors.white],
          ),
        ),
        child:
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : Column(
                  children: [
                    if (_alerts.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Text(
                          'Cảnh báo mới: ${_alerts.length}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.red,
                          ),
                        ),
                      ),
                    Expanded(
                      child:
                          _cameras.isEmpty
                              ? Center(
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
                                      child: const Icon(
                                        Icons.devices,
                                        size: 100,
                                        color: Colors.grey,
                                      ),
                                    ),
                                    const SizedBox(height: 30),
                                    const Text(
                                      'Chưa có camera nào. Thêm mới để bắt đầu!',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Colors.black87,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                              : ListView.builder(
                                padding: const EdgeInsets.all(16),
                                itemCount: _cameras.length,
                                itemBuilder: (context, index) {
                                  final cam = _cameras[index];
                                  return Card(
                                    margin: const EdgeInsets.only(bottom: 16),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    elevation: 3,
                                    child: ListTile(
                                      contentPadding: const EdgeInsets.all(16),
                                      leading: const Icon(
                                        Icons.videocam,
                                        size: 40,
                                        color: Colors.red,
                                      ),
                                      title: Text(cam.cameraName),
                                      subtitle: Text("Vị trí: ${cam.location}"),
                                      trailing: ElevatedButton(
                                        onPressed: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder:
                                                  (_) => CameraStreamScreen(
                                                    camera: cam,
                                                  ),
                                            ),
                                          );
                                        },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.red,
                                          foregroundColor: Colors.white,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                        ),
                                        child: const Text("Xem"),
                                      ),
                                    ),
                                  );
                                },
                              ),
                    ),
                  ],
                ),
      ),
      bottomNavigationBar: BottomNavBar(
        initialIndex: 0,
        onTabChanged: (index) {
          switch (index) {
            case 0:
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const DeviceScreen()),
              );
              break;
            case 1:
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const NotificationScreen()),
              );
              break;
            // case 2:
            //   Navigator.pushReplacement(
            //     context,
            //     MaterialPageRoute(builder: (_) => ProfileScreen()),
            //   );
            //   break;
          }
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToAddCameraScreen,
        backgroundColor: Colors.red,
        child: const Icon(Icons.add),
      ),
    );
  }
}
