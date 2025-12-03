class BrowserTab {
  final String id;
  final String url;
  final String? title;
  final bool isActive;
  final bool isLoading;
  final bool hasError;

  const BrowserTab({
    required this.id,
    required this.url,
    this.title,
    this.isActive = false,
    this.isLoading = false,
    this.hasError = false,
  });

  BrowserTab copyWith({
    String? url,
    String? title,
    bool? isActive,
    bool? isLoading,
    bool? hasError,
  }) {
    return BrowserTab(
      id: id,
      url: url ?? this.url,
      title: title ?? this.title,
      isActive: isActive ?? this.isActive,
      isLoading: isLoading ?? this.isLoading,
      hasError: hasError ?? this.hasError,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'url': url,
      'title': title,
      'isActive': isActive,
      'isLoading': isLoading,
      'hasError': hasError,
    };
  }

  factory BrowserTab.fromMap(Map<dynamic, dynamic> map) {
    return BrowserTab(
      id: map['id'] as String,
      url: map['url'] as String,
      title: map['title'] as String?,
      isActive: map['isActive'] as bool? ?? false,
      isLoading: map['isLoading'] as bool? ?? false,
      hasError: map['hasError'] as bool? ?? false,
    );
  }
}
