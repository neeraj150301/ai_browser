class PageCache {
  final String url;
  final String? title;
  final String html;
  final DateTime updatedAt;

  PageCache({
    required this.url,
    required this.html,
    required this.updatedAt,
    this.title,
  });

  Map<String, dynamic> toMap() {
    return {
      'url': url,
      'title': title,
      'html': html,
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory PageCache.fromMap(Map<dynamic, dynamic> map) {
    return PageCache(
      url: map['url'] as String,
      title: map['title'] as String?,
      html: map['html'] as String,
      updatedAt: DateTime.parse(map['updatedAt'] as String),
    );
  }
}
