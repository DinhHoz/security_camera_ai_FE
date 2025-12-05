import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart'; // Import Google Fonts
import 'package:flutter_animate/flutter_animate.dart'; // Import Animation
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart'; // Import Staggered Grid

class AlertDetailScreen extends StatelessWidget {
  final String alertId;

  const AlertDetailScreen({super.key, required this.alertId});

  static const Color primaryColor = Colors.lightBlue;
  // Màu nền nhẹ nhàng hơn cho các card
  static const Color surfaceColor = Color(0xFFF5F7FA);

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      return const Scaffold(body: Center(child: Text("Chưa đăng nhập")));
    }

    final uid = currentUser.uid;
    final alertRef = FirebaseFirestore.instance
        .collection("users")
        .doc(uid)
        .collection("alerts")
        .doc(alertId);

    return Scaffold(
      backgroundColor: surfaceColor,
      body: FutureBuilder<DocumentSnapshot>(
        future: alertRef.get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: primaryColor),
            );
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text("Alert không tồn tại"));
          }

          final data = snapshot.data!.data() as Map<String, dynamic>? ?? {};
          final timestamp = data['timestamp'];
          final timeString = timestamp is Timestamp
              ? _formatTimestamp(timestamp)
              : timestamp is String
                  ? _formatTimestamp(
                      Timestamp.fromDate(DateTime.parse(timestamp)),
                    )
                  : 'Unknown Time';

          WidgetsBinding.instance.addPostFrameCallback((_) {
            _updateReadStatus(alertRef);
          });

          return _buildDetailedUI(context, data, timeString);
        },
      ),
    );
  }

  Widget _buildDetailedUI(
    BuildContext context,
    Map<String, dynamic> data,
    String timeString,
  ) {
    final title = data['cameraName'] ?? 'Chi tiết Cảnh báo';
    final imageUrl = data['imageUrl'];
    final alertType = data['type'] ?? 'Không xác định';
    final location = data['location'] ?? 'N/A';
    final cameraId = data['cameraId'] ?? 'N/A';

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: <Widget>[
        // 1. Header ảnh lớn co giãn (Parallax Effect)
        SliverAppBar(
          expandedHeight: 320.0,
          floating: false,
          pinned: true,
          backgroundColor: primaryColor,
          iconTheme: const IconThemeData(color: Colors.white),
          flexibleSpace: FlexibleSpaceBar(
            title: Text(
              title,
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 16,
                shadows: [
                  const Shadow(blurRadius: 10, color: Colors.black54),
                ],
              ),
            ),
            background: Stack(
              fit: StackFit.expand,
              children: [
                if (imageUrl != null)
                  Hero(
                    tag: 'alert_image_$alertId',
                    child: FadeInImage.assetNetwork(
                      placeholder: 'assets/placeholder.png',
                      image: imageUrl,
                      fit: BoxFit.cover,
                      imageErrorBuilder: (_, __, ___) => Container(
                        color: Colors.grey.shade300,
                        child: const Icon(Icons.broken_image,
                            size: 50, color: Colors.grey),
                      ),
                    ),
                  )
                else
                  Container(
                    color: primaryColor,
                    child: const Icon(Icons.notifications,
                        size: 80, color: Colors.white54),
                  ),
                // Gradient mờ bên dưới để text dễ đọc
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.7),
                      ],
                      stops: const [0.6, 1.0],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // 2. Nội dung chính
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Thông tin chi tiết",
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ).animate().fadeIn().slideX(begin: -0.1),
                const SizedBox(height: 16),

                // 3. Grid thông tin (Staggered Grid)
                StaggeredGrid.count(
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  children: [
                    _buildStatTile(
                      icon: alertType == 'fire'
                          ? Icons.local_fire_department
                          : Icons.warning_amber_rounded,
                      color: alertType == 'fire'
                          ? Colors.redAccent
                          : Colors.orangeAccent,
                      title: "Loại cảnh báo",
                      value: alertType.toUpperCase(),
                      isHighlight: true,
                    ),
                    _buildStatTile(
                      icon: Icons.access_time_filled,
                      color: Colors.blueAccent,
                      title: "Thời gian",
                      value: timeString,
                    ),
                    _buildStatTile(
                      icon: Icons.location_on,
                      color: Colors.green,
                      title: "Vị trí",
                      value: location,
                    ),
                    _buildStatTile(
                      icon: Icons.videocam,
                      color: Colors.grey.shade700,
                      title: "Camera ID",
                      value: cameraId,
                    ),
                  ].animate(interval: 100.ms)
                    .fadeIn(duration: 400.ms)
                    .slideY(begin: 0.2, end: 0, curve: Curves.easeOutQuad),
                ),
                    

                const SizedBox(height: 30),

                // 4. Nút hành động
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Đang mở hành động liên quan..."),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                    icon: const Icon(Icons.play_circle_outline, size: 24),
                    label: Text(
                      "Xem lại Video ghi hình",
                      style: GoogleFonts.poppins(
                          fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                      elevation: 4,
                      shadowColor: primaryColor.withOpacity(0.4),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ).animate().fadeIn(delay: 400.ms).scale(),
                
                const SizedBox(height: 50),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // Widget con: Thẻ thông tin dạng Grid
  Widget _buildStatTile({
    required IconData icon,
    required Color color,
    required String title,
    required String value,
    bool isHighlight = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: isHighlight
            ? Border.all(color: color.withOpacity(0.5), width: 1.5)
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: Colors.grey.shade500,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 15,
              color: Colors.black87,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  // --- LOGIC XỬ LÝ (GIỮ NGUYÊN) ---
  Future<void> _updateReadStatus(DocumentReference alertRef) async {
    try {
      await alertRef.update({'isRead': true});
      print("✅ Đã cập nhật trạng thái isRead cho alert: $alertId");
    } catch (e) {
      print("❌ Lỗi cập nhật isRead: $e");
    }
  }

  String _formatTimestamp(Timestamp timestamp) {
    final dateTime = timestamp.toDate();
    return "${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')} - ${dateTime.day.toString().padLeft(2, '0')}/${dateTime.month.toString().padLeft(2, '0')}/${dateTime.year}";
  }
}