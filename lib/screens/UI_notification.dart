import 'package:flutter/material.dart';
import '../screens/UI_device.dart'; // Import DeviceScreen
import '../widgets/bottom_nav_bar.dart'; // Import BottomNavBar

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  _NotificationScreenState createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFFF5E6E8), // Màu nền hồng nhạt
        elevation: 0,
        title: const Text(
          'Thông báo',
          style: TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list, color: Colors.black),
            onSelected: (value) {
              // Xử lý lọc (Tất cả/Chưa đọc)
            },
            itemBuilder:
                (BuildContext context) => <PopupMenuEntry<String>>[
                  const PopupMenuItem<String>(
                    value: 'all',
                    child: Text('Tất cả'),
                  ),
                  const PopupMenuItem<String>(
                    value: 'unread',
                    child: Text('Chưa đọc'),
                  ),
                ],
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFF5F5F5), Colors.white],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Hình minh họa
              Container(
                height: 200,
                width: 200,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(
                  Icons.inbox,
                  size: 100,
                  color: Colors.grey,
                ), // Placeholder cho hình minh họa
              ),
              const SizedBox(height: 30),
              // Văn bản "Không có dữ liệu"
              const Text(
                'Không có dữ liệu.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.black87,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavBar(
        initialIndex: 1, // Khởi đầu với tab "Thông báo"
        onTabChanged:
            (
              index,
            ) {}, // Callback rỗng, vì điều hướng đã xử lý trong BottomNavBar
      ),
    );
  }
}
