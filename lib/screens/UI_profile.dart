import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:frontend/screens/UI_device.dart';
import 'package:frontend/screens/login_screen.dart'; // 👉 THÊM IMPORT LOGIN
import 'package:frontend/widgets/bottom_nav_bar.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final User? currentUser = FirebaseAuth.instance.currentUser;
  final primaryColor = Colors.lightBlue;

  // Lấy tên hiển thị
  String _getDisplayName() {
    if (currentUser == null) return 'Khách';

    if (currentUser!.displayName != null &&
        currentUser!.displayName!.isNotEmpty) {
      return currentUser!.displayName!;
    }
    if (currentUser!.email != null) {
      return currentUser!.email!.split('@')[0];
    }
    return 'Người dùng';
  }

  // 👉 Hàm Đăng Xuất
  void _logout() async {
    await FirebaseAuth.instance.signOut();

    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  void _handleTabChange(int index) {}

  @override
  Widget build(BuildContext context) {
    final displayName = _getDisplayName();

    return Scaffold(
      backgroundColor: Colors.grey.shade50,

      // --------------------- APP BAR ---------------------
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(70),
        child: Padding(
          padding: const EdgeInsets.only(top: 30, right: 8, left: 4),
          child: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(
                Icons.arrow_back_ios,
                color: Colors.black,
                size: 24,
              ),
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const DeviceScreen()),
                );
              },
            ),
            actions: [
              IconButton(
                icon: Icon(
                  Icons.add_circle_outline,
                  color: primaryColor,
                  size: 30,
                ),
                onPressed: () {},
              ),
              IconButton(
                icon: Icon(
                  Icons.notifications_none,
                  color: primaryColor,
                  size: 30,
                ),
                onPressed: () {},
              ),
              const SizedBox(width: 8),
            ],
          ),
        ),
      ),

      // --------------------- BODY ---------------------
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 60),
        child: Column(
          children: [
            const SizedBox(height: 50),
            Row(
              children: const [
                Spacer(),
                Text(
                  'Thông tin cá nhân',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                Spacer(),
              ],
            ),
            const SizedBox(height: 30),

            // Avatar + Tên người dùng
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
              decoration: BoxDecoration(
                color: Colors.lightBlue.shade50,
                borderRadius: BorderRadius.circular(15),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 25,
                    backgroundColor: Colors.white,
                    child: Image.asset(
                      'assets/avatar_placeholder.png',
                      height: 35,
                      width: 35,
                      errorBuilder:
                          (context, error, stackTrace) => const Icon(
                            Icons.person,
                            color: Colors.deepOrange,
                            size: 30,
                          ),
                    ),
                  ),
                  const SizedBox(width: 15),
                  Text(
                    displayName,
                    style: const TextStyle(fontSize: 18, color: Colors.black87),
                  ),
                  const Spacer(),
                  Icon(Icons.more_horiz, color: Colors.grey.shade400, size: 30),
                ],
              ),
            ),

            const SizedBox(height: 35),

            // ------------------ Menu Options ------------------
            _buildOptionTile(
              icon: Icons.help_outline,
              title: 'Hỗ trợ',
              iconColor: Colors.lightBlue.shade300,
              onTap: () {},
            ),
            const SizedBox(height: 10),

            _buildOptionTile(
              icon: Icons.info_outline,
              title: 'Về chúng tôi',
              iconColor: Colors.lightBlue.shade300,
              onTap: () {},
            ),
            const SizedBox(height: 10),

            _buildOptionTile(
              icon: Icons.notifications_none,
              title: 'Thông báo',
              iconColor: Colors.lightBlue.shade300,
              onTap: () {},
            ),

            const SizedBox(height: 10),

            // ------------------ 🚀 NÚT ĐĂNG XUẤT ------------------
            _buildOptionTile(
              icon: Icons.logout,
              title: 'Đăng xuất',
              iconColor: Colors.red.shade300,
              onTap: () {
                showDialog(
                  context: context,
                  builder:
                      (_) => AlertDialog(
                        title: const Text("Đăng xuất"),
                        content: const Text(
                          "Bạn có chắc muốn đăng xuất tài khoản không?",
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text("Hủy"),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.pop(context);
                              _logout();
                            },
                            child: const Text(
                              "Đăng xuất",
                              style: TextStyle(color: Colors.red),
                            ),
                          ),
                        ],
                      ),
                );
              },
            ),
          ],
        ),
      ),

      // --------------------- BOTTOM NAV BAR ---------------------
      bottomNavigationBar: BottomNavBar(
        initialIndex: 2,
        onTabChanged: _handleTabChange,
      ),
    );
  }

  // ------------------ WIDGET MENU TILE ------------------
  Widget _buildOptionTile({
    required IconData icon,
    required String title,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, color: iconColor, size: 28),
            const SizedBox(width: 15),
            Text(
              title,
              style: const TextStyle(fontSize: 16, color: Colors.black87),
            ),
            const Spacer(),
            Icon(
              Icons.arrow_forward_ios,
              color: Colors.purple.shade100,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
