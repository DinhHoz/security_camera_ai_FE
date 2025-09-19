import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/alert_api.dart';
import '../models/alert.dart';
import 'alert_detail_screen.dart';

class AlertScreen extends StatelessWidget {
  final AlertApi alertService = AlertApi();

  // Hàm lấy idToken từ SharedPreferences
  Future<String?> _getIdToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('id_token');
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
      future: _getIdToken(), // Lấy idToken từ SharedPreferences
      builder: (context, tokenSnapshot) {
        if (tokenSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (tokenSnapshot.hasError ||
            !tokenSnapshot.hasData ||
            tokenSnapshot.data == null) {
          return const Center(
            child: Text('Không thể lấy token. Vui lòng đăng nhập lại.'),
          );
        }

        final userToken = tokenSnapshot.data!;

        // Gọi FutureBuilder thứ hai để lấy danh sách alerts
        return FutureBuilder<List<dynamic>>(
          future: alertService.getAlerts(userToken),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(child: Text('No alerts found.'));
            } else {
              return ListView.builder(
                itemCount: snapshot.data!.length,
                itemBuilder: (context, index) {
                  final alert = snapshot.data![index];
                  return ListTile(
                    title: Text(alert['cameraName'] ?? 'Unknown Camera'),
                    subtitle: Text(alert['timestamp'] ?? 'No timestamp'),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AlertDetailScreen(alert: alert),
                        ),
                      );
                    },
                  );
                },
              );
            }
          },
        );
      },
    );
  }
}
