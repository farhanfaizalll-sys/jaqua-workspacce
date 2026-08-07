class FeedEvent {
  final String id;
  final String triggeredBy; // "SCHEDULE" | "MANUAL"
  final DateTime createdAt;

  FeedEvent({required this.id, required this.triggeredBy, required this.createdAt});

  factory FeedEvent.fromJson(Map<String, dynamic> json) => FeedEvent(
        id: json['id'] as String,
        triggeredBy: json['triggeredBy'] as String,
        createdAt: DateTime.parse(json['createdAt'] as String),
      );
}
