class FeedSchedule {
  final String id;
  final int jam;
  final int menit;
  final bool enabled;

  FeedSchedule({required this.id, required this.jam, required this.menit, required this.enabled});

  factory FeedSchedule.fromJson(Map<String, dynamic> json) => FeedSchedule(
        id: json['id'] as String,
        jam: json['jam'] as int,
        menit: json['menit'] as int,
        enabled: json['enabled'] as bool,
      );

  String get label => '${jam.toString().padLeft(2, '0')}:${menit.toString().padLeft(2, '0')}';
}
