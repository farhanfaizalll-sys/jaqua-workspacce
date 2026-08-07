class SensorReading {
  final String id;
  final double suhu;
  final double levelPeletPersen;
  final DateTime recordedAt;

  SensorReading({
    required this.id,
    required this.suhu,
    required this.levelPeletPersen,
    required this.recordedAt,
  });

  factory SensorReading.fromJson(Map<String, dynamic> json) => SensorReading(
        id: json['id'] as String,
        suhu: (json['suhu'] as num).toDouble(),
        levelPeletPersen: (json['levelPeletPersen'] as num).toDouble(),
        recordedAt: DateTime.parse(json['recordedAt'] as String),
      );
}
