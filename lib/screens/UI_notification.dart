import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:frontend/screens/UI_profile.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/bottom_nav_bar.dart';
import 'UI_alert_detail.dart';
import 'UI_device.dart';
import '../models/camera.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  _NotificationScreenState createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen>
    with SingleTickerProviderStateMixin {
  final User? currentUser = FirebaseAuth.instance.currentUser;
  String _filterStatus = 'all';
  String? _filterCamera;
  String _filterDate = 'all';
  DateTime? _startDate;
  DateTime? _endDate;
  List<Camera> _cameras = [];
  bool _isVisible = false;
  bool _isLoadingCameras = true;
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  final primaryColor = Colors.lightBlue.shade700;
  final gradient = LinearGradient(
    colors: [Colors.lightBlue.shade50, Colors.white],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  @override
  void initState() {
    super.initState();
    _loadCameras();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeIn));

    Future.delayed(const Duration(milliseconds: 100), () {
      setState(() {
        _isVisible = true;
        _controller.forward();
      });
    });
  }

  Future<void> _loadCameras() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      List<String> saved = prefs.getStringList('cameras') ?? [];
      setState(() {
        _cameras =
            saved.map((c) {
              try {
                final data = jsonDecode(c) as Map<String, dynamic>;
                return Camera(
                  id:
                      data['id'] ??
                      DateTime.now().millisecondsSinceEpoch.toString(),
                  cameraName: data['cameraName'] ?? 'Camera',
                  location: data['location'] ?? 'Không rõ',
                  streamUrl: data['streamUrl'] ?? '',
                );
              } catch (e) {
                print('Error decoding camera data: $e');
                return Camera(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  cameraName: 'Camera lỗi',
                  location: 'Không rõ',
                  streamUrl: '',
                );
              }
            }).toList();
        _isLoadingCameras = false;
      });
    } catch (e) {
      print('Error loading cameras: $e');
      setState(() {
        _isLoadingCameras = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Lỗi tải danh sách camera: $e')));
      }
    }
  }

  Future<void> _showCustomDatePicker() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      builder:
          (context, child) => Theme(
            data: ThemeData.light().copyWith(
              colorScheme: ColorScheme.light(primary: primaryColor),
            ),
            child: child!,
          ),
    );
    if (picked != null &&
        picked.start != null &&
        picked.end != null &&
        mounted) {
      setState(() {
        _filterDate = 'custom';
        _startDate = picked.start;
        _endDate = picked.end;
      });
    }
  }

  Future<void> _markAsRead(String alertId) async {
    if (currentUser == null) return;
    try {
      await FirebaseFirestore.instance
          .collection("users")
          .doc(currentUser!.uid)
          .collection("alerts")
          .doc(alertId)
          .set({'isRead': true}, SetOptions(merge: true));
    } catch (e) {
      print('Error marking alert as read: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Lỗi khi đánh dấu đã đọc: $e')));
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Query<Map<String, dynamic>> query = FirebaseFirestore.instance
        .collection("users")
        .doc(currentUser?.uid)
        .collection("alerts")
        .orderBy("timestamp", descending: true)
        .limit(50); // Add limit to prevent excessive data fetch

    List<Query<Map<String, dynamic>>> filters = [];

    if (_filterStatus == 'unread') {
      filters.add(query.where('isRead', isEqualTo: false));
    }

    if (_filterCamera != null && _filterCamera != 'all') {
      filters.add(query.where('cameraName', isEqualTo: _filterCamera));
    }

    if (_filterDate != 'all') {
      DateTime now = DateTime.now();
      DateTime startDate;
      DateTime endDate = now.add(const Duration(days: 1));

      if (_filterDate == 'today') {
        startDate = DateTime(now.year, now.month, now.day);
      } else if (_filterDate == 'last7days') {
        startDate = now.subtract(const Duration(days: 7));
      } else if (_filterDate == 'custom' &&
          _startDate != null &&
          _endDate != null) {
        startDate = _startDate!;
        endDate = _endDate!.add(const Duration(days: 1));
      } else {
        startDate = now.subtract(
          const Duration(days: 30),
        ); // Fallback to last 30 days
      }

      filters.add(
        query.where(
          'timestamp',
          isGreaterThanOrEqualTo: Timestamp.fromDate(startDate),
        ),
      );
      filters.add(
        query.where('timestamp', isLessThan: Timestamp.fromDate(endDate)),
      );
    }

    // Apply filters sequentially
    for (var filter in filters) {
      query = filter;
    }

    print(
      'Query built: status=$_filterStatus, camera=$_filterCamera, date=$_filterDate, '
      'start=$_startDate, end=$_endDate',
    );

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(80.0),
        child: Padding(
          padding: const EdgeInsets.only(top: 20.0),
          child: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            title: const Text(
              'Thông báo',
              style: TextStyle(
                color: Colors.black87,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            actions: [
              _isLoadingCameras
                  ? Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: primaryColor,
                      ),
                    ),
                  )
                  : PopupMenuButton<String>(
                    icon: Icon(Icons.filter_list, color: primaryColor),
                    onSelected: (value) {
                      setState(() {
                        if (value == 'reset') {
                          _filterStatus = 'all';
                          _filterCamera = null;
                          _filterDate = 'all';
                          _startDate = null;
                          _endDate = null;
                        } else if (value.startsWith('status_')) {
                          _filterStatus = value.replaceFirst('status_', '');
                        } else if (value.startsWith('camera_')) {
                          _filterCamera = value.replaceFirst('camera_', '');
                        } else if (value.startsWith('date_')) {
                          _filterDate = value.replaceFirst('date_', '');
                          if (_filterDate == 'custom') {
                            _showCustomDatePicker();
                          }
                        }
                      });
                    },
                    itemBuilder:
                        (BuildContext context) => <PopupMenuEntry<String>>[
                          const PopupMenuItem<String>(
                            value: 'status_all',
                            child: Row(
                              children: [
                                Icon(Icons.all_inclusive, size: 20),
                                SizedBox(width: 8),
                                Text('Tất cả trạng thái'),
                              ],
                            ),
                          ),
                          const PopupMenuItem<String>(
                            value: 'status_unread',
                            child: Row(
                              children: [
                                Icon(Icons.mark_email_unread, size: 20),
                                SizedBox(width: 8),
                                Text('Chưa đọc'),
                              ],
                            ),
                          ),
                          const PopupMenuDivider(),
                          const PopupMenuItem<String>(
                            value: 'camera_all',
                            child: Row(
                              children: [
                                Icon(Icons.videocam, size: 20),
                                SizedBox(width: 8),
                                Text('Tất cả camera'),
                              ],
                            ),
                          ),
                          ..._cameras.map(
                            (camera) => PopupMenuItem<String>(
                              value: 'camera_${camera.cameraName}',
                              child: Row(
                                children: [
                                  Icon(Icons.camera_alt, size: 20),
                                  SizedBox(width: 8),
                                  Text(camera.cameraName),
                                ],
                              ),
                            ),
                          ),
                          const PopupMenuDivider(),
                          const PopupMenuItem<String>(
                            value: 'date_all',
                            child: Row(
                              children: [
                                Icon(Icons.calendar_today, size: 20),
                                SizedBox(width: 8),
                                Text('Tất cả ngày'),
                              ],
                            ),
                          ),
                          const PopupMenuItem<String>(
                            value: 'date_today',
                            child: Row(
                              children: [
                                Icon(Icons.today, size: 20),
                                SizedBox(width: 8),
                                Text('Hôm nay'),
                              ],
                            ),
                          ),
                          const PopupMenuItem<String>(
                            value: 'date_last7days',
                            child: Row(
                              children: [
                                Icon(Icons.calendar_view_week, size: 20),
                                SizedBox(width: 8),
                                Text('7 ngày qua'),
                              ],
                            ),
                          ),
                          const PopupMenuItem<String>(
                            value: 'date_custom',
                            child: Row(
                              children: [
                                Icon(Icons.date_range, size: 20),
                                SizedBox(width: 8),
                                Text('Tùy chỉnh'),
                              ],
                            ),
                          ),
                          const PopupMenuDivider(),
                          const PopupMenuItem<String>(
                            value: 'reset',
                            child: Row(
                              children: [
                                Icon(
                                  Icons.refresh,
                                  size: 20,
                                  color: Colors.red,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  'Đặt lại bộ lọc',
                                  style: TextStyle(color: Colors.red),
                                ),
                              ],
                            ),
                          ),
                        ],
                  ),
              const SizedBox(width: 16.0),
            ],
          ),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(gradient: gradient),
        child: SafeArea(
          child:
              currentUser == null
                  ? Center(
                    child: Text(
                      'Chưa đăng nhập',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  )
                  : StreamBuilder<QuerySnapshot>(
                    stream: query.snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        print('Firestore query error: ${snapshot.error}');
                        return Center(
                          child: Text(
                            'Lỗi tải dữ liệu: ${snapshot.error}',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        );
                      }
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Center(
                          child: CircularProgressIndicator(color: primaryColor),
                        );
                      }

                      final docs = snapshot.data!.docs;

                      if (docs.isEmpty) {
                        return _buildEmptyState();
                      }

                      return AnimatedOpacity(
                        opacity: _isVisible ? 1.0 : 0.0,
                        duration: const Duration(milliseconds: 800),
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: docs.length,
                          itemBuilder: (context, index) {
                            final docId = docs[index].id;
                            final alert =
                                docs[index].data() as Map<String, dynamic>;
                            final alertId = docs[index].id;
                            final cameraName =
                                alert["cameraName"] ?? "Không rõ";
                            final location = alert["location"] ?? "";
                            final type = alert["type"] ?? "";
                            final isRead = alert["isRead"] ?? false;
                            final timestamp =
                                (alert["timestamp"] as Timestamp?)?.toDate();

                            return SlideTransition(
                              position: _slideAnimation,
                              child: FadeTransition(
                                opacity: _fadeAnimation,
                                child: GestureDetector(
                                  onTap: () {
                                    _markAsRead(docId);
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder:
                                            (_) => AlertDetailScreen(
                                              alertId: alertId,
                                            ),
                                      ),
                                    );
                                  },
                                  child: Card(
                                    margin: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    color:
                                        Theme.of(context).brightness ==
                                                Brightness.dark
                                            ? Colors.grey.shade800
                                            : isRead
                                            ? Colors.white
                                            : Colors.blue.withOpacity(0.1),
                                    elevation: 4,
                                    shadowColor: Colors.black.withOpacity(0.05),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: ListTile(
                                      leading: Icon(
                                        type == "fire"
                                            ? Icons.local_fire_department
                                            : Icons.smoke_free,
                                        color:
                                            type == "fire"
                                                ? Colors.red.shade700
                                                : Colors.grey,
                                        size: 36,
                                      ),
                                      title: Text(
                                        "Camera: $cameraName",
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w500,
                                          color:
                                              Theme.of(context).brightness ==
                                                      Brightness.dark
                                                  ? Colors.white
                                                  : Colors.black87,
                                        ),
                                      ),
                                      subtitle: Text(
                                        "$location\n${timestamp != null ? timestamp.toString() : 'Không rõ thời gian'}",
                                        style: TextStyle(
                                          fontSize: 14,
                                          color:
                                              Theme.of(context).brightness ==
                                                      Brightness.dark
                                                  ? Colors.grey.shade300
                                                  : Colors.grey.shade600,
                                        ),
                                      ),
                                      isThreeLine: true,
                                      trailing: Icon(
                                        Icons.chevron_right,
                                        color: primaryColor,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
        ),
      ),
      bottomNavigationBar: BottomNavBar(
        initialIndex: 1,
        onTabChanged: (index) {
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
            case 2:
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const ProfileScreen()),
              );
              break;
          }
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: AnimatedOpacity(
        opacity: _isVisible ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 800),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedScale(
              scale: _isVisible ? 1.0 : 0.8,
              duration: const Duration(milliseconds: 600),
              child: Container(
                height: 150,
                width: 150,
                decoration: BoxDecoration(
                  color:
                      Theme.of(context).brightness == Brightness.dark
                          ? Colors.grey.shade800
                          : Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.inbox,
                  size: 80,
                  color:
                      Theme.of(context).brightness == Brightness.dark
                          ? Colors.grey.shade300
                          : Colors.grey.shade600,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Không có thông báo nào.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color:
                    Theme.of(context).brightness == Brightness.dark
                        ? Colors.grey.shade300
                        : Colors.grey.shade600,
                fontWeight: FontWeight.w400,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
