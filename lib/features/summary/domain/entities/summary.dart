class Summary {
  final String id;
  final String sourceId;
  final String sourceType;
  final String originalTextHash;
  final String summaryText;
  final int originalWordCount;
  final int summaryWordCount;
  final Map<String, String> translations;
    final DateTime createdAt;

  Summary({
    required this.id,
    required this.sourceId,
    required this.sourceType,
    required this.originalTextHash,
    required this.summaryText,
    required this.originalWordCount,
    required this.summaryWordCount,
    required this.translations,
     DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'sourceId': sourceId,
      'sourceType': sourceType,
      'originalTextHash': originalTextHash,
      'summaryText': summaryText,
      'originalWordCount': originalWordCount,
      'summaryWordCount': summaryWordCount,
      'translations': translations,
       'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Summary.fromMap(Map<dynamic, dynamic> map) {
    return Summary(
      id: map['id'] as String,
      sourceId: map['sourceId'] as String,
      sourceType: map['sourceType'] as String,
      originalTextHash: map['originalTextHash'] as String,
      summaryText: map['summaryText'] as String,
      originalWordCount: map['originalWordCount'] as int,
      summaryWordCount: map['summaryWordCount'] as int,
      translations:
          Map<String, String>.from(map['translations'] ?? <String, String>{}),
          createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'] as String)
          : DateTime.now(),
    );
  }
}
