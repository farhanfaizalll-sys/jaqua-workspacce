class Device {
  final String id;
  final String name;
  final String deviceCode;
  final bool isOn;
  final double? lastSuhu;
  final double? lastLevelPeletPersen;
  final DateTime? lastSeenAt;

  Device({
    required this.id,
    required this.name,
    required this.deviceCode,
    required this.isOn,
    this.lastSuhu,
    this.lastLevelPeletPersen,
    this.lastSeenAt,
  });

  factory Device.fromJson(Map<String, dynamic> json) => Device(
        id: json['id'] as String,
        name: json['name'] as String,
        deviceCode: json['deviceCode'] as String,
        isOn: json['isOn'] as bool,
        lastSuhu: (json['lastSuhu'] as num?)?.toDouble(),
        lastLevelPeletPersen: (json['lastLevelPeletPersen'] as num?)?.toDouble(),
        lastSeenAt: json['lastSeenAt'] != null ? DateTime.parse(json['lastSeenAt'] as String) : null,
      );

  /// Belum pernah kirim data sama sekali sejak didaftarkan di app.
  bool get hasData => lastSeenAt != null;
}
