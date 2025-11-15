import 'dart:async';
import 'dart:typed_data';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_vlc_player/flutter_vlc_player.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import '../services/auth_service.dart';
import '../models/camera.dart';

class CameraStreamScreen extends StatefulWidget {
  // 🚨 Dữ liệu Camera (streamUrl, id, location) được truyền vào từ Backend (Firestore)
  final Camera camera;

  const CameraStreamScreen({super.key, required this.camera});

  @override
  State<CameraStreamScreen> createState() => _CameraStreamScreenState();
}

class _CameraStreamScreenState extends State<CameraStreamScreen>
    with SingleTickerProviderStateMixin {
  late VlcPlayerController _vlcController;
  int _frameCounter = 0;
  bool _isProcessing = false;

  // Backend APIs
  final String _detectionApiUrl = "http://192.168.1.214:3000/api/detect";

  bool _isVisible = false;
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  final primaryColor = Colors.lightBlue.shade700;
  final gradient = LinearGradient(
    colors: [Colors.lightBlue.shade50, Colors.white],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  @override
  void initState() {
    super.initState();
    // 💡 Lấy streamUrl từ đối tượng Camera do Backend cung cấp để bắt đầu stream
    _vlcController = VlcPlayerController.network(
      widget.camera.streamUrl,
      hwAcc: HwAcc.full,
      autoPlay: true,
      options: VlcPlayerOptions(),
    );
    _vlcController.addListener(_frameProcessingListener);

    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeIn));

    Future.delayed(const Duration(milliseconds: 100), () {
      setState(() {
        _isVisible = true;
        _controller.forward();
      });
    });
  }

  void _frameProcessingListener() {
    if (_vlcController.value.isPlaying && !_isProcessing) {
      _processAndSendFrame();
    }
  }

  // 💡 HÀM GIÁM SÁT THÔNG MINH (Giữ nguyên logic Backend)
  Future<void> _processAndSendFrame() async {
    _isProcessing = true;
    _frameCounter++;

    // Xử lý mỗi 3 khung hình để giảm tải
    if (_frameCounter % 3 == 0) {
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

      // 💡 GỬI DỮ LIỆU CAMERA LẤY TỪ BACKEND ĐI KÈM VỚI FRAME ĐẾN API DETECT
      request.fields['cameraId'] = widget.camera.id;
      request.fields['cameraName'] = widget.camera.cameraName;
      request.fields['location'] = widget.camera.location;

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

        if (fireDetected && ["fire", "smoke"].contains(detectedClass)) {
          final timestamp = DateTime.now().toString();
          print("🔥 Phát hiện $detectedClass lúc $timestamp");
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
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        // Tiêu đề lấy từ dữ liệu Backend
        title: Text(
          widget.camera.cameraName,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(gradient: gradient),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 10.0,
            ),
            child: AnimatedOpacity(
              opacity: _isVisible ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 800),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AnimatedScale(
                    scale: _isVisible ? 1.0 : 0.8,
                    duration: const Duration(milliseconds: 600),
                    child: Icon(Icons.videocam, size: 50, color: primaryColor),
                  ),
                  const SizedBox(height: 16),
                  // Vị trí lấy từ dữ liệu Backend
                  Text(
                    'Vị trí: ${widget.camera.location}',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  const SizedBox(height: 24),
                  SlideTransition(
                    position: _slideAnimation,
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: Container(
                        height: MediaQuery.of(context).size.height * 0.6,
                        decoration: BoxDecoration(
                          color:
                              Theme.of(context).brightness == Brightness.dark
                                  ? Colors.grey.shade800
                                  : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: VlcPlayer(
                            controller: _vlcController,
                            aspectRatio: 16 / 9,
                            placeholder: const Center(
                              child: CircularProgressIndicator(),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),
                  SlideTransition(
                    position: _slideAnimation,
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.7),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildInfoItem(
                              Icons.info,
                              'Trạng thái',
                              'Đang hoạt động',
                            ),
                            _buildInfoItem(
                              Icons.schedule,
                              'Cập nhật',
                              'Realtime',
                            ),
                            _buildInfoItem(Icons.security, 'Giám sát', 'Bật'),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Widget phụ trợ để hiển thị thông tin
  Widget _buildInfoItem(IconData icon, String title, String value) {
    return Column(
      children: [
        Icon(icon, size: 20, color: primaryColor),
        const SizedBox(height: 4),
        Text(
          title,
          style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 10,
            color: primaryColor,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
