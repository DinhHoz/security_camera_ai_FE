class Camera {
  final String id;           // 👈 String, không phải int
  final String cameraName;
  final String location;
  final bool status;
  final String? streamUrl;   // có thể null
  final DateTime? createdAt; // có thể null

  Camera({
    required this.id,
    required this.cameraName,
    required this.location,
    required this.status,
    this.streamUrl,
    this.createdAt,
  });

  factory Camera.fromJson(Map<String, dynamic> json) {
    return Camera(
      id: json['_id'] ?? '', // 👈 backend trả "_id"
      cameraName: json['cameraName'] ?? '',
      location: json['location'] ?? '',
      status: json['status'] ?? false,
      streamUrl: json['streamUrl'],
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'cameraName': cameraName,
      'location': location,
      'status': status,
      'streamUrl': streamUrl,
      'createdAt': createdAt?.toIso8601String(),
    };
  }
}
