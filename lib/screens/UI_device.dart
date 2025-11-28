// lib/screens/DeviceScreen.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/camera.dart';
import '../models/alert.dart';

import 'CameraStreamScreen.dart';
import '../widgets/camera_preview_tile.dart';
import '../widgets/bottom_nav_bar.dart';
import '../screens/UI_notification.dart';
import '../screens/UI_profile.dart';
import '../screens/UI_Add_Camera.dart';

const String SERVER_HOST = "172.20.10.2";
const int SERVER_PORT = 3000;

class DeviceScreen extends StatefulWidget {
  const DeviceScreen({Key? key}) : super(key: key);

  @override
  State<DeviceScreen> createState() => _DeviceScreenState();
}

class _DeviceScreenState extends State<DeviceScreen> {
  Stream<List<Camera>>? _cameraStream;

  List<Alert> _alerts = [];
  bool _isLoadingAlerts = true;

  String? _idToken;
  bool _isTokenReady = false;

  @override
  void initState() {
    super.initState();
    _setupCameraStream();
    _loadUnreadAlerts();
    _fetchIdToken();
  }

  void _setupCameraStream() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    _cameraStream = FirebaseFirestore.instance
        .collection("users")
        .doc(user.uid)
        .collection("cameras")
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            final d = doc.data();
            return Camera(
              id: doc.id,
              cameraName: d["cameraName"] ?? "Camera ${doc.id}",
              streamUrl: d["streamUrl"] ?? "",
              location: d["location"] ?? "Không xác định",
            );
          }).toList();
        });
  }

  Future<void> _fetchIdToken() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() => _isTokenReady = true);
      return;
    }
    final token = await user.getIdToken();
    setState(() {
      _idToken = token;
      _isTokenReady = true;
    });
  }

  String _snapshotUrl(String cameraId) {
    if (!_isTokenReady) return "";
    return "http://$SERVER_HOST:$SERVER_PORT/api/stream-frame/$cameraId?token=$_idToken";
  }

  Future<void> _loadUnreadAlerts() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final snapshot =
        await FirebaseFirestore.instance
            .collection("users")
            .doc(user.uid)
            .collection("alerts")
            .where("isRead", isEqualTo: false)
            .get();

    setState(() {
      _alerts = snapshot.docs.map((e) => Alert.fromJson(e.data())).toList();
      _isLoadingAlerts = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Camera>>(
      stream: _cameraStream,
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final cameras = snap.data!;
        if (cameras.isEmpty) {
          return const Scaffold(
            body: Center(child: Text("Chưa có camera nào")),
          );
        }

        return Scaffold(
          appBar: AppBar(title: const Text("Thiết bị")),
          body: GridView.builder(
            padding: const EdgeInsets.all(12),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: cameras.length,
            itemBuilder: (_, i) {
              final cam = cameras[i];

              return GestureDetector(
                onTap:
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => CameraStreamScreen(camera: cam),
                      ),
                    ),
                child: CameraPreviewTile(
                  cameraId: cam.id,
                  cameraName: cam.cameraName,
                  url: _snapshotUrl(cam.id),
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
                    MaterialPageRoute(
                      builder: (_) => const NotificationScreen(),
                    ),
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
      },
    );
  }
}
