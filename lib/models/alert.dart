class Alert {
  final String alertId;
  final String cameraId;
  final String cameraName;
  final String location;
  final String type;
  final String imageUrl;
  final String status;
  final DateTime timestamp;

  Alert({
    required this.alertId,
    required this.cameraId,
    required this.cameraName,
    required this.location,
    required this.type,
    required this.imageUrl,
    required this.status,
    required this.timestamp,
  });

  factory Alert.fromJson(Map<String, dynamic> json) {
    return Alert(
      alertId: json['alertId'] ?? '',
      cameraId: json['cameraId'] ?? '',
      cameraName: json['cameraName'] ?? '',
      location: json['location'] ?? '',
      type: json['type'] ?? 'unknown',
      imageUrl: json['imageUrl'] ?? '',
      status: json['status'] ?? 'active',
      timestamp: DateTime.parse(json['timestamp']),
    );
  }
}
