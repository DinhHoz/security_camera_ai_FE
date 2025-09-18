import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../models/camera.dart';

class CameraDetailScreen extends StatefulWidget {
  final Camera camera;
  const CameraDetailScreen({super.key, required this.camera});

  @override
  State<CameraDetailScreen> createState() => _CameraDetailScreenState();
}

class _CameraDetailScreenState extends State<CameraDetailScreen> {
  VideoPlayerController? controller; // 👈 nullable để tránh crash
  bool isLoading = true;

  @override
  void initState() {
    super.initState();

    if (widget.camera.streamUrl != null && widget.camera.streamUrl!.isNotEmpty) {
      controller = VideoPlayerController.networkUrl(Uri.parse(widget.camera.streamUrl!))
        ..initialize().then((_) {
          setState(() {
            isLoading = false;
          });
          controller?.play();
        });
    } else {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.camera.cameraName)),
      body: Center(
        child: isLoading
            ? const CircularProgressIndicator()
            : controller != null && controller!.value.isInitialized
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      AspectRatio(
                        aspectRatio: controller!.value.aspectRatio,
                        child: VideoPlayer(controller!),
                      ),
                      const SizedBox(height: 16),
                      IconButton(
                        icon: Icon(
                          controller!.value.isPlaying ? Icons.pause : Icons.play_arrow,
                          size: 40,
                          color: Colors.blue,
                        ),
                        onPressed: () {
                          setState(() {
                            controller!.value.isPlaying
                                ? controller!.pause()
                                : controller!.play();
                          });
                        },
                      ),
                    ],
                  )
                : const Text("Không có streamUrl cho camera này"),
      ),
    );
  }
}
