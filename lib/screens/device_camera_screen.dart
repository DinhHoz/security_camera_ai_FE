import 'package:flutter/material.dart';
import 'package:flutter_vlc_player/flutter_vlc_player.dart';
import 'dart:developer' as developer; // ⬅️ Thêm thư viện này để logging

class DeviceCameraScreen extends StatefulWidget {
  final String streamUrl; // Truyền URL camera

  const DeviceCameraScreen({super.key, required this.streamUrl});

  @override
  State<DeviceCameraScreen> createState() => _DeviceCameraScreenState();
}

class _DeviceCameraScreenState extends State<DeviceCameraScreen> {
  late VlcPlayerController _vlcController;
  String _status = "Đang khởi tạo...";
  bool _isError = false; // ⬅️ Thêm biến trạng thái lỗi

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  void _initializePlayer() {
    _vlcController = VlcPlayerController.network(
      widget.streamUrl,
      hwAcc: HwAcc.auto,
      autoPlay: true,
      options: VlcPlayerOptions(
        advanced: VlcAdvancedOptions([VlcAdvancedOptions.networkCaching(1500)]),
        rtp: VlcRtpOptions([VlcRtpOptions.rtpOverRtsp(true)]),
        sout: VlcStreamOutputOptions(["--no-audio"]),
      ),
    );

    _vlcController.addListener(() {
      final value = _vlcController.value;
      setState(() {
        if (value.hasError) {
          _status = "❌ Lỗi: ${value.errorDescription}";
          _isError = true; // Cập nhật trạng thái lỗi
          // ⬅️ Ghi lại lỗi vào console để dev dễ fix
          developer.log(
            'VLC Player Error: ${value.errorDescription}',
            name: 'DeviceCameraScreen',
          );
        } else if (!value.isInitialized) {
          _status = "⏳ Đang load stream...";
          _isError = false;
        } else if (value.isPlaying) {
          _status = "▶️ Đang phát";
          _isError = false;
        } else {
          _status = "⏸ Tạm dừng";
          _isError = false;
        }
      });
    });
  }

  @override
  void dispose() {
    _vlcController.stop();
    _vlcController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Test Camera Stream"),
        actions: [
          IconButton(
            icon: const Icon(Icons.play_arrow),
            onPressed: () => _vlcController.play(),
          ),
          IconButton(
            icon: const Icon(Icons.pause),
            onPressed: () => _vlcController.pause(),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Center(
              child:
                  _isError // ⬅️ Dùng biến _isError để điều kiện hiển thị
                      ? const Text(
                        "Đã xảy ra lỗi. Vui lòng kiểm tra lại đường truyền hoặc liên hệ hỗ trợ.",
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.red, fontSize: 16),
                      )
                      : VlcPlayer(
                        controller: _vlcController,
                        aspectRatio: 16 / 9,
                        placeholder: const Center(
                          child: CircularProgressIndicator(),
                        ),
                      ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(_status, style: const TextStyle(fontSize: 16)),
          ),
        ],
      ),
    );
  }
}
