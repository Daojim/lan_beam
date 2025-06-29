class FileInfo {
  final String fileName;
  final int fileSizeBytes;
  final String fileType;
  final String filePath;

  FileInfo({
    required this.fileName,
    required this.fileSizeBytes,
    required this.fileType,
    required this.filePath,
  });

  // Converts raw bytes into human-readable strings "1000 B, 5.7 MB, 1.2GB"
  String get formattedSize {
    if (fileSizeBytes < 1024) return '$fileSizeBytes B';
    if (fileSizeBytes < 1024 * 1024) {
      return '${(fileSizeBytes / 1024).toStringAsFixed(1)} KB';
    }
    if (fileSizeBytes < 1024 * 1024 * 1024) {
      return '${(fileSizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(fileSizeBytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
}
