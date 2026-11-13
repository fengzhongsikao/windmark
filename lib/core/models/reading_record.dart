enum ReadingKind { meihua, liuyao }

class ReadingRecord {
  const ReadingRecord({
    required this.id,
    required this.kind,
    required this.createdAt,
    required this.title,
    required this.summary,
    required this.payload,
  });

  final String id;
  final ReadingKind kind;
  final DateTime createdAt;
  final String title;
  final String summary;
  final Map<String, Object?> payload;

  Map<String, Object?> toJson() {
    return {
      'id': id,
      'kind': kind.name,
      'createdAt': createdAt.toIso8601String(),
      'title': title,
      'summary': summary,
      'payload': payload,
    };
  }

  factory ReadingRecord.fromJson(Map<String, dynamic> json) {
    return ReadingRecord(
      id: json['id'] as String,
      kind: ReadingKind.values.byName(json['kind'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
      title: json['title'] as String,
      summary: json['summary'] as String,
      payload: Map<String, Object?>.from(json['payload'] as Map),
    );
  }
}
