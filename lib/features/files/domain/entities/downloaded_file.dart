class DownloadedFile {
  final String id;
  final String name;
  final String path;
  final String extension;
  final int sizeBytes;
  final DateTime createdAt;

  DownloadedFile({
    required this.id,
    required this.name,
    required this.path,
    required this.extension,
    required this.sizeBytes,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'path': path,
      'extension': extension,
      'sizeBytes': sizeBytes,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory DownloadedFile.fromMap(Map<dynamic, dynamic> map) {
    return DownloadedFile(
      id: map['id'] as String,
      name: map['name'] as String,
      path: map['path'] as String,
      extension: map['extension'] as String,
      sizeBytes: map['sizeBytes'] as int,
      createdAt: DateTime.parse(map['createdAt'] as String),
    );
  }
}
