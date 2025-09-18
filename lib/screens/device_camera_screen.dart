import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class DeviceCameraScreen extends StatefulWidget {
  const DeviceCameraScreen({super.key});

  @override
  State<DeviceCameraScreen> createState() => _DeviceCameraScreenState();
}

class _DeviceCameraScreenState extends State<DeviceCameraScreen> {
  late VideoPlayerController _controller;

  @override
  void initState() {
    super.initState();
    // Thay bằng link RTSP/HTTP thật của camera thiết bị
    _controller = VideoPlayerController.networkUrl(
        Uri.parse("http://your-camera-ip:port/live"),
      )
      ..initialize().then((_) {
        setState(() {});
        _controller.play();
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Camera Thiết Bị")),
      body: Center(
        child:
            _controller.value.isInitialized
                ? AspectRatio(
                  aspectRatio: _controller.value.aspectRatio,
                  child: VideoPlayer(_controller),
                )
                : const CircularProgressIndicator(),
      ),
    );
  }
}
