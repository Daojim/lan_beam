import '../utils/result.dart';
import 'dart:io';

/// Represents a file or folder for transfer
class TransferItem {
  final String name;
  final int totalSizeBytes;
  final String path;
  final TransferItemType type;
  final List<FileSystemEntity>? contents; // For folders
  final int? fileCount; // For folders

  TransferItem._({
    required this.name,
    required this.totalSizeBytes,
    required this.path,
    required this.type,
    this.contents,
    this.fileCount,
  });

  /// Factory constructor for files
  static Result<TransferItem> createFile({required String filePath}) {
    final file = File(filePath);

    if (!file.existsSync()) {
      return Result.failure('File does not exist: $filePath');
    }

    try {
      final stat = file.statSync();
      final fileName = file.uri.pathSegments.last;

      return Result.success(
        TransferItem._(
          name: fileName,
          totalSizeBytes: stat.size,
          path: filePath,
          type: TransferItemType.file,
        ),
      );
    } catch (e) {
      return Result.failure('Cannot access file: $e');
    }
  }

  /// Factory constructor for folders
  static Future<Result<TransferItem>> createFolder({
    required String folderPath,
  }) async {
    final directory = Directory(folderPath);

    if (!directory.existsSync()) {
      return Result.failure('Folder does not exist: $folderPath');
    }

    try {
      final contents = <FileSystemEntity>[];
      int totalSize = 0;
      int fileCount = 0;

      await for (final entity in directory.list(recursive: true)) {
        if (entity is File) {
          final stat = await entity.stat();
          totalSize += stat.size;
          fileCount++;
          contents.add(entity);
        } else if (entity is Directory) {
          contents.add(entity);
        }
      }

      final folderName = directory.uri.pathSegments
          .where((segment) => segment.isNotEmpty)
          .last;

      return Result.success(
        TransferItem._(
          name: folderName,
          totalSizeBytes: totalSize,
          path: folderPath,
          type: TransferItemType.folder,
          contents: contents,
          fileCount: fileCount,
        ),
      );
    } catch (e) {
      return Result.failure('Cannot access folder: $e');
    }
  }

  /// Factory constructor for incoming transfers
  static Result<TransferItem> createForIncomingTransfer({
    required String name,
    required int totalSizeBytes,
    required TransferItemType type,
    int? fileCount,
  }) {
    if (name.trim().isEmpty) {
      return const Result.failure('Name cannot be empty');
    }

    if (totalSizeBytes < 0) {
      return const Result.failure('Size cannot be negative');
    }

    return Result.success(
      TransferItem._(
        name: name.trim(),
        totalSizeBytes: totalSizeBytes,
        path: '', // Will be set when user accepts transfer
        type: type,
        fileCount: fileCount,
      ),
    );
  }

  /// Get formatted size string
  String get formattedSize {
    if (totalSizeBytes < 1024) return '$totalSizeBytes B';
    if (totalSizeBytes < 1024 * 1024) {
      return '${(totalSizeBytes / 1024).toStringAsFixed(1)} KB';
    }
    if (totalSizeBytes < 1024 * 1024 * 1024) {
      return '${(totalSizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(totalSizeBytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  /// Get description for UI display
  String get description {
    switch (type) {
      case TransferItemType.file:
        final extension = path.split('.').last;
        return extension.isNotEmpty ? '.$extension file' : 'File';
      case TransferItemType.folder:
        final count = fileCount ?? 0;
        return '$count file${count != 1 ? 's' : ''}';
    }
  }

  /// Get appropriate icon
  String get iconPath {
    switch (type) {
      case TransferItemType.file:
        return 'file';
      case TransferItemType.folder:
        return 'folder';
    }
  }

  /// Check if this is a valid transfer item
  bool get isValid => name.isNotEmpty && totalSizeBytes >= 0;

  @override
  String toString() =>
      'TransferItem(name: $name, size: $formattedSize, type: $type)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TransferItem &&
        other.name == name &&
        other.totalSizeBytes == totalSizeBytes &&
        other.path == path &&
        other.type == type;
  }

  @override
  int get hashCode => Object.hash(name, totalSizeBytes, path, type);
}

enum TransferItemType { file, folder }

extension TransferItemTypeExtension on TransferItemType {
  String get name {
    switch (this) {
      case TransferItemType.file:
        return 'file';
      case TransferItemType.folder:
        return 'folder';
    }
  }
}
