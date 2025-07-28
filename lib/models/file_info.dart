import '../utils/result.dart';
import 'dart:io';

class FileInfo {
  final String fileName;
  final int fileSizeBytes;
  final String fileType;
  final String filePath;

  FileInfo._({
    required this.fileName,
    required this.fileSizeBytes,
    required this.fileType,
    required this.filePath,
  });

  /// Factory constructor with validation
  static Result<FileInfo> create({
    required String fileName,
    required int fileSizeBytes,
    required String fileType,
    required String filePath,
  }) {
    // Validate inputs
    if (fileName.trim().isEmpty) {
      return const Result.failure('File name cannot be empty');
    }

    if (fileSizeBytes < 0) {
      return const Result.failure('File size cannot be negative');
    }

    if (filePath.trim().isEmpty) {
      return const Result.failure('File path cannot be empty');
    }

    // Check if file exists (for local files)
    if (filePath.isNotEmpty && !File(filePath).existsSync()) {
      return Result.failure('File does not exist: $filePath');
    }

    return Result.success(
      FileInfo._(
        fileName: fileName.trim(),
        fileSizeBytes: fileSizeBytes,
        fileType: fileType.trim(),
        filePath: filePath.trim(),
      ),
    );
  }

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

  /// Check if this is a valid file
  bool get isValid =>
      fileName.isNotEmpty && fileSizeBytes >= 0 && filePath.isNotEmpty;

  @override
  String toString() =>
      'FileInfo(fileName: $fileName, size: $formattedSize, type: $fileType)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is FileInfo &&
        other.fileName == fileName &&
        other.fileSizeBytes == fileSizeBytes &&
        other.fileType == fileType &&
        other.filePath == filePath;
  }

  @override
  int get hashCode => Object.hash(fileName, fileSizeBytes, fileType, filePath);
}
