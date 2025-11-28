// lib/widgets/camera_preview_tile.dart
import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class CameraPreviewTile extends StatefulWidget {
  final String cameraId;
  final String cameraName;
  final String url;

  const CameraPreviewTile({
    Key? key,
    required this.cameraId,
    required this.cameraName,
    required this.url,
  }) : super(key: key);

  @override
  State<CameraPreviewTile> createState() => _CameraPreviewTileState();
}

class _CameraPreviewTileState extends State<CameraPreviewTile> {
  Uint8List? _bufferA;
  Uint8List? _bufferB;
  Uint8List? _bufferC; // triple buffer

  bool _useAB = true; // switch A–B
  Timer? _timer;

  final http.Client _client = http.Client();

  // Adaptive interval: bắt đầu 350ms (≈3 FPS)
  int _intervalMs = 350;

  // Lưu thời điểm nhận frame để điều chỉnh FPS
  DateTime? _lastFrameTime;

  @override
  void initState() {
    super.initState();
    _startFetching();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _client.close();
    super.dispose();
  }

  /// Tự điều chỉnh FPS: nếu backend chậm → tự giảm FPS
  void _adaptiveTune() {
    if (_lastFrameTime == null) return;

    final delta = DateTime.now().difference(_lastFrameTime!).inMilliseconds;

    if (delta > 800) {
      // quá chậm → giảm FPS còn 1.2 FPS
      _intervalMs = 800;
    } else if (delta > 500) {
      // hơi chậm → 2 FPS
      _intervalMs = 500;
    } else {
      // backend nhanh → 3 FPS
      _intervalMs = 333;
    }
  }

  void _startFetching() {
    _timer = Timer.periodic(Duration(milliseconds: _intervalMs), (timer) async {
      try {
        final url = widget.url;
        if (url.isEmpty) return;

        final res = await _client
            .get(Uri.parse(url))
            .timeout(const Duration(seconds: 2));

        if (res.statusCode != 200) return;

        final bytes = res.bodyBytes;
        if (!mounted) return;

        // If frame identical → skip update
        if (_useAB && _bufferA != null && _bufferA!.hashCode == bytes.hashCode)
          return;
        if (!_useAB && _bufferB != null && _bufferB!.hashCode == bytes.hashCode)
          return;

        // Use triple buffer for smoothing
        setState(() {
          _bufferC = _bufferB; // giữ frame cũ để smoothing
          if (_useAB) {
            _bufferB = bytes;
          } else {
            _bufferA = bytes;
          }
          _useAB = !_useAB;
        });

        _lastFrameTime = DateTime.now();
        _adaptiveTune();
        timer.cancel();
        Future.delayed(Duration(milliseconds: _intervalMs), () {
          if (mounted) _startFetching();
        });
      } catch (_) {
        // skip errors
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    Uint8List? img = _useAB ? _bufferA : _bufferB;

    // fallback smoothing
    img ??= _bufferC;

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Stack(
        fit: StackFit.expand,
        children: [
          img == null
              ? Container(
                color: Colors.black,
                child: const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                ),
              )
              : Image.memory(
                img,
                fit: BoxFit.cover,
                gaplessPlayback: true, // tránh nháy trắng
              ),

          Positioned(
            left: 8,
            bottom: 8,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                widget.cameraName,
                style: const TextStyle(color: Colors.white, fontSize: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
