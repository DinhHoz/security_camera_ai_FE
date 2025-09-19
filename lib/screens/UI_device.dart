import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/bottom_nav_bar.dart';
import '../screens/UI_Add_Camera.dart';
import '../screens/CameraStreamScreen.dart';

class DeviceScreen extends StatefulWidget {
  const DeviceScreen({super.key});

  @override
  _DeviceScreenState createState() => _DeviceScreenState();
}

class _DeviceScreenState extends State<DeviceScreen> {
  List<Map<String, dynamic>> _cameras = [];

  @override
  void initState() {
    super.initState();
    _loadCameras();
  }

  // 🔹 Load camera từ SharedPreferences
  Future<void> _loadCameras() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> saved = prefs.getStringList('cameras') ?? [];
    setState(() {
      _cameras =
          saved.map((c) => jsonDecode(c) as Map<String, dynamic>).toList();
    });
  }

  // 🔹 Điều hướng sang AddCameraScreen và reload khi thêm xong
  void _navigateToAddCameraScreen() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddCameraScreen()),
    );
    if (result == true) {
      _loadCameras(); // Reload danh sách
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
                        style: TextStyle(fontSize: 16, color: Colors.black87),
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
                        title: Text(cam['cameraName'] ?? 'Camera'),
                        subtitle: Text(
                          "Vị trí: ${cam['location'] ?? 'Không rõ'}",
                        ),
                        trailing: ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (_) => CameraStreamScreen(
                                      streamUrl: cam['streamUrl'],
                                      cameraName: cam['cameraName'],
                                    ),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text("Xem"),
                        ),
                      ),
                    );
                  },
                ),
      ),
      bottomNavigationBar: BottomNavBar(
        initialIndex: 0,
        onTabChanged: (index) {},
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToAddCameraScreen,
        backgroundColor: Colors.red,
        child: const Icon(Icons.add),
      ),
    );
  }
}
