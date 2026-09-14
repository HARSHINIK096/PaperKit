
enum FileTypeCategory {
  pdf,
  image,
  audio,
  video,
  document,
  archive,
  other,
}

class DocumentFile {
  final String id;
  final String name;
  final String path;
  final int size;
  final DateTime modifiedAt;
  final FileTypeCategory type;
  final bool isFavorite;
  final String? thumbnailPath;
  final int? pageCount;

  DocumentFile({
    required this.id,
    required this.name,
    required this.path,
    required this.size,
    required this.modifiedAt,
    required this.type,
    this.isFavorite = false,
    this.thumbnailPath,
    this.pageCount,
  });

  String get formattedSize {
    if (size < 1024) return '$size B';
    if (size < 1024 * 1024) return '${(size / 1024).toStringAsFixed(1)} KB';
    return '${(size / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  static FileTypeCategory getTypeFromExtension(String ext) {
    final e = ext.toLowerCase().replaceAll('.', '');
    if (e == 'pdf') return FileTypeCategory.pdf;
    if (['jpg', 'jpeg', 'png', 'webp', 'heic', 'gif', 'bmp'].contains(e)) return FileTypeCategory.image;
    if (['mp3', 'wav', 'ogg', 'm4a', 'aac', 'flac'].contains(e)) return FileTypeCategory.audio;
    if (['mp4', 'mov', 'webm', 'avi', 'mkv'].contains(e)) return FileTypeCategory.video;
    if (['doc', 'docx', 'xls', 'xlsx', 'ppt', 'pptx', 'txt'].contains(e)) return FileTypeCategory.document;
    if (['zip', 'rar', 'tar', 'gz', '7z', 'bz2'].contains(e)) return FileTypeCategory.archive;
    return FileTypeCategory.other;
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'path': path,
    'size': size,
    'modifiedAt': modifiedAt.toIso8601String(),
    'type': type.index,
    'isFavorite': isFavorite,
    'thumbnailPath': thumbnailPath,
    'pageCount': pageCount,
  };

  factory DocumentFile.fromJson(Map<String, dynamic> json) => DocumentFile(
    id: json['id'],
    name: json['name'],
    path: json['path'],
    size: json['size'],
    modifiedAt: DateTime.parse(json['modifiedAt']),
    type: FileTypeCategory.values[json['type']],
    isFavorite: json['isFavorite'] ?? false,
    thumbnailPath: json['thumbnailPath'],
    pageCount: json['pageCount'],
  );
}
