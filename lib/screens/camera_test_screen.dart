// import 'dart:async';
// import 'dart:convert';
// import 'package:flutter/material.dart';
// import 'package:camera/camera.dart';
// import 'package:http/http.dart' as http;
// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:flutter/foundation.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import '../services/api_config.dart';
// import 'alertDetailScreen.dart'; // 👈 thêm import để chuyển màn hình

// class CameraScreen extends StatefulWidget {
//   const CameraScreen({super.key});

//   @override
//   State<CameraScreen> createState() => _CameraScreenState();
// }

// class _CameraScreenState extends State<CameraScreen> {
//   CameraController? _controller;
//   Future<void>? _initializeControllerFuture;
//   String _result = "Đang khởi tạo camera...";
//   Timer? _timer;
//   bool _isProcessing = false;
//   String? _authToken;

//   @override
//   void initState() {
//     super.initState();
//     _loadTokenAndSetupCamera();
//   }

//   Future<void> _loadTokenAndSetupCamera() async {
//     final prefs = await SharedPreferences.getInstance();
//     final token = prefs.getString('id_token');
//     if (token == null || token.isEmpty) {
//       setState(() => _result = "Chưa có token, cần đăng nhập lại!");
//       await Future.delayed(const Duration(seconds: 2));
//       if (mounted) {
//         Navigator.pushReplacementNamed(context, '/login');
//       }
//       return;
//     }
//     _authToken = token;
//     if (kDebugMode) print("Loaded token: ${_authToken!.substring(0, 10)}...");

//     try {
//       final cameras = await availableCameras();
//       if (cameras.isEmpty) {
//         setState(() => _result = "Không tìm thấy camera");
//         return;
//       }
//       final firstCamera = cameras.first;
//       _controller = CameraController(
//         firstCamera,
//         ResolutionPreset.medium,
//         enableAudio: false,
//       );
//       _initializeControllerFuture = _controller!.initialize();
//       await _initializeControllerFuture;
//       if (!mounted) return;
//       setState(() {});
//       _timer = Timer.periodic(
//         const Duration(seconds: 3),
//         (_) => _captureAndSend(),
//       );
//     } catch (e) {
//       setState(() => _result = "Lỗi khởi tạo camera: $e");
//     }
//   }

//   Future<String?> _refreshTokenIfNeeded(String? currentToken) async {
//     if (currentToken == null) return null;
//     try {
//       final user = FirebaseAuth.instance.currentUser;
//       if (user != null) {
//         final newToken = await user.getIdToken(true);
//         if (newToken != null) {
//           _authToken = newToken;
//           final prefs = await SharedPreferences.getInstance();
//           await prefs.setString('id_token', newToken);
//           if (kDebugMode)
//             print("Refreshed token: ${newToken.substring(0, 10)}...");
//           return newToken;
//         }
//       }
//     } catch (e) {
//       if (kDebugMode) print("Error refreshing token: $e");
//     }
//     return currentToken;
//   }

//   Future<void> _captureAndSend() async {
//     if (!mounted ||
//         _controller == null ||
//         !_controller!.value.isInitialized ||
//         _isProcessing) {
//       return;
//     }
//     _isProcessing = true;
//     try {
//       final picture = await _controller!.takePicture();
//       var token = _authToken;
//       if (token == null || token.isEmpty) {
//         setState(() => _result = "Chưa có token!");
//         _isProcessing = false;
//         await Future.delayed(const Duration(seconds: 2));
//         if (mounted) {
//           Navigator.pushReplacementNamed(context, '/login');
//         }
//         return;
//       }

//       token = await _refreshTokenIfNeeded(token);
//       if (token == null || token.isEmpty) {
//         setState(() => _result = "Token không hợp lệ sau khi làm mới!");
//         _isProcessing = false;
//         await Future.delayed(const Duration(seconds: 2));
//         if (mounted) {
//           Navigator.pushReplacementNamed(context, '/login');
//         }
//         return;
//       }

//       final url = ApiConfig.getDetectUrl();
//       if (url.isEmpty) {
//         setState(() => _result = "URL API không hợp lệ!");
//         _isProcessing = false;
//         return;
//       }
//       Uri uri = Uri.parse(url);

//       var request = http.MultipartRequest("POST", uri);
//       request.headers.addAll({"Authorization": "Bearer $token"});
//       request.files.add(
//         await http.MultipartFile.fromPath("image", picture.path),
//       );

//       var response = await request.send().timeout(
//         const Duration(seconds: 10),
//         onTimeout: () {
//           throw Exception("Kết nối timeout đến $url");
//         },
//       );
//       final resBody = await response.stream.bytesToString();

//       if (response.statusCode != 200) {
//         setState(
//           () => _result = "Lỗi server: ${response.statusCode} - $resBody",
//         );
//         _isProcessing = false;
//         return;
//       }

//       dynamic jsonData;
//       try {
//         jsonData = jsonDecode(resBody);
//       } catch (e) {
//         setState(() => _result = "Phản hồi không phải JSON: $resBody - $e");
//         _isProcessing = false;
//         return;
//       }

//       final bool fireDetected = jsonData["fire_detected"] == true;
//       final String detectedClass = jsonData["class"] ?? "none";
//       final double? confidence =
//           jsonData["confidence"] != null
//               ? (jsonData["confidence"] as num).toDouble()
//               : null;

//       const double confidenceThreshold = 0.7;
//       if (fireDetected &&
//           confidence != null &&
//           confidence >= confidenceThreshold &&
//           (detectedClass == "fire" || detectedClass == "smoke")) {
//         // 👇 đổi logic: không showDialog, mà mở AlertDetailScreen
//         final alertData = {
//           "cameraId": "cam1",
//           "cameraName": "Test Camera",
//           "location": "Office",
//           "status": "fire_detected",
//           "timestamp": DateTime.now().toIso8601String(),
//           "imageUrl": "", // có thể lấy ảnh từ backend nếu có
//           "type": detectedClass,
//           "confidence": confidence,
//         };

//         if (mounted) {
//           Navigator.push(
//             context,
//             MaterialPageRoute(
//               builder: (context) => AlertDetailScreen(alert: alertData),
//             ),
//           );
//         }

//         setState(() {
//           _result =
//               "Phát hiện: $detectedClass\nĐộ tin cậy: ${(confidence * 100).toStringAsFixed(2)}%";
//         });
//       } else {
//         setState(() {
//           _result =
//               "Không phát hiện khói/lửa\nClass: $detectedClass\nConfidence: ${confidence != null ? "${(confidence * 100).toStringAsFixed(2)}%" : "N/A"}";
//         });
//       }
//     } catch (e) {
//       setState(() => _result = "Lỗi gửi ảnh: $e");
//     } finally {
//       _isProcessing = false;
//     }
//   }

//   @override
//   void dispose() {
//     _timer?.cancel();
//     _controller?.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text("Camera Phát hiện Khói/Lửa")),
//       body: Column(
//         children: [
//           if (_controller != null && _controller!.value.isInitialized)
//             SizedBox(height: 400, child: CameraPreview(_controller!))
//           else
//             const SizedBox(
//               height: 400,
//               child: Center(child: CircularProgressIndicator()),
//             ),
//           const SizedBox(height: 20),
//           Padding(
//             padding: const EdgeInsets.all(8.0),
//             child: Text(_result, style: const TextStyle(fontSize: 16)),
//           ),
//         ],
//       ),
//     );
//   }
// }
