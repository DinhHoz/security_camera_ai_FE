import 'package:flutter/material.dart';
import '../models/camera.dart';

// Backend server configuration
const String SERVER_HOST = "172.20.10.2";
const int SERVER_PORT = 3000;

/// Trả về URL MJPEG stream từ backend
String streamUrl(String cameraId) =>
    "http://$SERVER_HOST:$SERVER_PORT/api/stream/$cameraId";

class CameraStreamScreen extends StatelessWidget {
  final Camera camera;

  const CameraStreamScreen({Key? key, required this.camera}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    print('🎥 Opening full-screen stream for: ${camera.cameraName}');
    print('📡 Backend MJPEG URL: ${streamUrl(camera.id)}');

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text(
          camera.cameraName,
          style: const TextStyle(color: Colors.white, fontSize: 18),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Center(
              child: Row(
                children: [
                  const Icon(
                    Icons.location_on,
                    size: 16,
                    color: Colors.white70,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    camera.location,
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      body: Center(
        child: InteractiveViewer(
          maxScale: 4.0,
          minScale: 0.5,
          child: Image.network(
            streamUrl(camera.id),
            fit: BoxFit.contain,
            gaplessPlayback: true,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) {
                print('✅ MJPEG stream loaded successfully');
                return child;
              }
              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(color: Colors.white),
                  const SizedBox(height: 16),
                  Text(
                    'Backend đang chuyển đổi RTSP...\n${camera.cameraName}',
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'FFmpeg: RTSP → MJPEG',
                    style: TextStyle(color: Colors.white38, fontSize: 10),
                  ),
                ],
              );
            },
            errorBuilder: (context, error, stackTrace) {
              print('❌ Stream error: $error');
              return Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: Colors.red,
                      size: 64,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Không thể kết nối tới stream',
                      style: TextStyle(color: Colors.white, fontSize: 18),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Camera: ${camera.cameraName}',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white10,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            '⚠️ Kiểm tra:',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            '• Backend đang chạy? (npm run dev)',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            '• Camera online? (RTSP accessible)',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            '• RTSP URL trong Firestore đúng?',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            '• FFmpeg đã cài đặt?',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton.icon(
                          onPressed: () {
                            // Force reload
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (_) => CameraStreamScreen(camera: camera),
                              ),
                            );
                          },
                          icon: const Icon(Icons.refresh),
                          label: const Text('Thử lại'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 12),
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text(
                            'Quay lại',
                            style: TextStyle(color: Colors.white70),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.white24,
        onPressed: () {
          // Có thể thêm chức năng chụp ảnh, ghi hình, v.v.
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Chức năng đang phát triển'),
              duration: Duration(seconds: 1),
            ),
          );
        },
        child: const Icon(Icons.camera_alt, color: Colors.white),
      ),
    );
  }
}
