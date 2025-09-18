import 'package:flutter/material.dart';
import '../services/alert_api.dart';
import '../models/alert.dart';
import 'alert_detail_screen.dart';

class AlertsScreen extends StatefulWidget {
  const AlertsScreen({super.key});

  @override
  State<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends State<AlertsScreen> {
  final AlertApi api = AlertApi();
  late Future<List<Alert>> futureAlerts;

  @override
  void initState() {
    super.initState();
    futureAlerts = api.getAlerts();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Lịch sử cảnh báo")),
      body: FutureBuilder<List<Alert>>(
        future: futureAlerts,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          if (snapshot.hasError) return Center(child: Text("Error: ${snapshot.error}"));

          final alerts = snapshot.data ?? [];
          if (alerts.isEmpty) return const Center(child: Text("Chưa có cảnh báo"));

          return ListView.builder(
            itemCount: alerts.length,
            itemBuilder: (context, i) {
              final a = alerts[i];
              return Card(
                child: ListTile(
                  leading: Image.network(a.imageUrl, width: 60, height: 60, fit: BoxFit.cover),
                  title: Text("${a.type.toUpperCase()} - ${a.cameraName}"),
                  subtitle: Text("${a.location} • ${a.timestamp}"),
                  trailing: Text(a.status),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AlertDetailScreen(alert: a),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
