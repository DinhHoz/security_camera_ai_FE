import 'dart:async';
import 'dart:typed_data';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_vlc_player/flutter_vlc_player.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import '../services/auth_service.dart';
import '../models/camera.dart'; // import model Camera từ file camera.dart

class CameraStreamScreen extends StatefulWidget {
  final Camera camera; // dùng Camera từ model

  const CameraStreamScreen({super.key, required this.camera});

  @override
  State<CameraStreamScreen> createState() => _CameraStreamScreenState();
}

class _CameraStreamScreenState extends State<CameraStreamScreen> {
  late VlcPlayerController _vlcController;
  int _frameCounter = 0;
  bool _isProcessing = false;

  // Backend APIs
  final String _detectionApiUrl = "http://192.168.1.214:3000/api/detect";
  // Không cần _alertsApiUrl vì backend đã xử lý

  @override
  void initState() {
    super.initState();
    _vlcController = VlcPlayerController.network(
      widget.camera.streamUrl,
      hwAcc: HwAcc.full,
      autoPlay: true,
      options: VlcPlayerOptions(),
    );
    _vlcController.addListener(_frameProcessingListener);
  }

  void _frameProcessingListener() {
    if (_vlcController.value.isPlaying && !_isProcessing) {
      _processAndSendFrame();
    }
  }

  Future<void> _processAndSendFrame() async {
    _isProcessing = true;
    _frameCounter++;

    // Gửi 1 frame mỗi 10 lần (giảm tải)
    if (_frameCounter % 10 == 0) {
      try {
        final Uint8List? imageData = await _vlcController.takeSnapshot();
        if (imageData != null) {
          await _sendFrameForDetection(imageData);
        }
      } catch (e) {
        print("❌ Lỗi khi xử lý frame: $e");
      }
    }

    _isProcessing = false;
  }

  Future<void> _sendFrameForDetection(Uint8List imageData) async {
    try {
      final authHeader = await AuthService.getAuthHeader();
      if (authHeader == null) {
        print("❌ Không có token xác thực.");
        return;
      }

      var request = http.MultipartRequest('POST', Uri.parse(_detectionApiUrl));
      request.headers['Authorization'] = authHeader;

      // Metadata camera từ model
      request.fields['cameraId'] = widget.camera.id;
      request.fields['cameraName'] = widget.camera.cameraName;
      request.fields['location'] = widget.camera.location;

      // Gửi ảnh snapshot
      request.files.add(
        http.MultipartFile.fromBytes(
          'image',
          imageData,
          filename: 'frame.jpg',
          contentType: MediaType('image', 'jpeg'),
        ),
      );

      print("📤 Gửi frame [${_frameCounter}] đến backend detect...");
      final response = await request.send();
      final respStr = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        final jsonData = json.decode(respStr);

        final bool fireDetected = jsonData["fire_detected"] == true;
        final String detectedClass = jsonData["class"] ?? "none";
        final double? confidence =
            jsonData["confidence"] != null
                ? (jsonData["confidence"] as num).toDouble()
                : null;

        print(
          "✅ Detect → fire=$fireDetected, class=$detectedClass, conf=$confidence",
        );

        // Sửa includes thành contains
        if (fireDetected && ["fire", "smoke"].contains(detectedClass)) {
          final timestamp = DateTime.now().toString();
          print("🔥 Phát hiện $detectedClass lúc $timestamp");
          // Không gọi _sendAlertToBackend, để backend xử lý
        }
      } else {
        print("❌ Detect API lỗi: ${response.statusCode} Body: $respStr");
      }
    } catch (e) {
      print("❌ Lỗi mạng khi gọi detect: $e");
    }
  }

  @override
  void dispose() {
    _vlcController.removeListener(_frameProcessingListener);
    _vlcController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.camera.cameraName)),
      body: Center(
        child: VlcPlayer(
          controller: _vlcController,
          aspectRatio: 16 / 9,
          placeholder: const Center(child: CircularProgressIndicator()),
        ),
      ),
    );
  }
}
