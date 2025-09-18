import 'package:flutter/material.dart';
import '../models/alert.dart';

class AlertDetailScreen extends StatelessWidget {
  final Alert alert;
  const AlertDetailScreen({super.key, required this.alert});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Chi tiết cảnh báo")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Camera: ${alert.cameraName}", style: const TextStyle(fontSize: 18)),
            Text("Vị trí: ${alert.location}"),
            Text("Loại: ${alert.type}"),
            Text("Trạng thái: ${alert.status}"),
            Text("Thời gian: ${alert.timestamp}"),
            const SizedBox(height: 16),
            if (alert.imageUrl.isNotEmpty)
              Image.network(alert.imageUrl, fit: BoxFit.cover),
          ],
        ),
      ),
    );
  }
}
