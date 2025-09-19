import 'package:flutter/material.dart';
import '../screens/UI_device.dart'; // Import DeviceScreen
import '../screens/UI_notification.dart'; // Import NotificationScreen

class BottomNavBar extends StatefulWidget {
  final int initialIndex; // Chỉ số tab khởi đầu
  final Function(int) onTabChanged; // Callback khi tab thay đổi

  const BottomNavBar({
    super.key,
    required this.initialIndex,
    required this.onTabChanged,
  });

  @override
  _BottomNavBarState createState() => _BottomNavBarState();
}

class _BottomNavBarState extends State<BottomNavBar> {
  late int _selectedIndex;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
  }

  void _onItemTapped(int index) {
    if (_selectedIndex != index) {
      setState(() {
        _selectedIndex = index;
      });
      widget.onTabChanged(index); // Gọi callback để thông báo thay đổi tab
      switch (index) {
        case 0:
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const DeviceScreen()),
          );
          break;
        case 1:
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const NotificationScreen()),
          );
          break;
        // case 2:
        //   Navigator.pushReplacement(
        //     context,
        //     MaterialPageRoute(builder: (_) => ProfileScreen()),
        //   );
        //   break;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      backgroundColor: Colors.white,
      selectedItemColor: Colors.red,
      unselectedItemColor: Colors.grey,
      elevation: 8,
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Trang chủ'),
        BottomNavigationBarItem(
          icon: Icon(Icons.notifications_outlined),
          label: 'Thông báo',
        ),
        BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Tôi'),
      ],
      currentIndex: _selectedIndex,
      onTap: _onItemTapped,
    );
  }
}
