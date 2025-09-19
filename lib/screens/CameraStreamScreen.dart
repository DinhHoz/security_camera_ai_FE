// lib/screens/camera_stream_screen.dart

import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_vlc_player/flutter_vlc_player.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
// Thay đổi đường dẫn này để trỏ đến file auth_service.dart của bạn
import '../services/auth_service.dart';

class CameraStreamScreen extends StatefulWidget {
  final String streamUrl;
  final String cameraName;

  const CameraStreamScreen({
    super.key,
    required this.streamUrl,
    required this.cameraName,
  });

  @override
  State<CameraStreamScreen> createState() => _CameraStreamScreenState();
}

class _CameraStreamScreenState extends State<CameraStreamScreen> {
  late VlcPlayerController _vlcController;
  int _frameCounter = 0;
  bool _isProcessing = false;
  // URL của backend. Dùng 10.0.2.2 cho Android Emulator để trỏ tới localhost của máy tính.
  // Nếu chạy trên máy thật, hãy dùng IP của máy tính trong mạng LAN (ví dụ: 192.168.1.10).
  final String _detectionApiUrl = "http://192.168.1.214:3000/api/detect";

  @override
  void initState() {
    super.initState();
    _vlcController = VlcPlayerController.network(
      widget.streamUrl,
      hwAcc: HwAcc.full,
      autoPlay: true,
      options: VlcPlayerOptions(),
    );
    // Thêm listener để theo dõi trạng thái của player và xử lý frame
    _vlcController.addListener(_frameProcessingListener);
  }

  void _frameProcessingListener() {
    // Chỉ xử lý khi video đang phát và không có tác vụ nào khác đang chạy
    if (_vlcController.value.isPlaying && !_isProcessing) {
      _processAndSendFrame();
    }
  }

  Future<void> _processAndSendFrame() async {
    _isProcessing = true;
    _frameCounter++;

    // Chỉ chụp và gửi frame thứ 10 để giảm tải
    if (_frameCounter % 10 == 0) {
      try {
        final Uint8List? imageData = await _vlcController.takeSnapshot();
        if (imageData != null) {
          await _sendFrameForDetection(imageData);
        }
      } catch (e) {
        print("Lỗi khi xử lý frame: $e");
      }
    }

    _isProcessing = false;
  }

  Future<void> _sendFrameForDetection(Uint8List imageData) async {
    try {
      // Lấy header xác thực đã được định dạng sẵn từ AuthService
      final authHeader = await AuthService.getAuthHeader();

      // Nếu không có header (người dùng chưa đăng nhập), dừng lại
      if (authHeader == null) {
        print("Không thể gửi request. Header xác thực không tồn tại.");
        return;
      }

      var request = http.MultipartRequest('POST', Uri.parse(_detectionApiUrl));

      // Thêm header vào request
      request.headers['Authorization'] = authHeader;

      // Đính kèm file ảnh
      request.files.add(
        http.MultipartFile.fromBytes(
          'image', // Tên field này phải khớp với backend
          imageData,
          filename: 'frame.jpg',
          contentType: MediaType('image', 'jpeg'),
        ),
      );

      print("Đang gửi frame đến backend...");
      final response = await request.send();

      if (response.statusCode == 200) {
        print("Backend xử lý frame thành công.");
      } else {
        print("Lỗi từ backend. Mã trạng thái: ${response.statusCode}");
      }
    } catch (e) {
      print("Lỗi mạng khi gửi request đến backend: $e");
    }
  }

  @override
  void dispose() {
    // Rất quan trọng: Luôn gỡ bỏ listener và dispose controller
    _vlcController.removeListener(_frameProcessingListener);
    _vlcController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.cameraName)),
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
