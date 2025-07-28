import 'package:flutter/foundation.dart';
import 'dart:async';
import 'device.dart';
import 'file_info.dart';
import 'transfer_item.dart';
import 'transfer_session.dart';
import 'app_settings.dart';

class AppState extends ChangeNotifier {
  List<Device> discoveredDevices;
  TransferItem? selectedItem; // Changed from selectedFile
  TransferSession? activeTransfer;
  AppSettings settings;
  bool isListening;

  // Debouncing for progress updates
  Timer? _progressUpdateTimer;
  TransferSession? _pendingProgressUpdate;

  AppState({
    required this.discoveredDevices,
    required this.selectedItem, // Changed from selectedFile
    required this.activeTransfer,
    required this.settings,
    required this.isListening,
  });

  void addDevice(Device device) {
    discoveredDevices.add(device);
    notifyListeners();
  }

  void setSelectedItem(TransferItem? item) {
    // Changed from setSelectedFile
    selectedItem = item;
    notifyListeners();
  }

  // Backward compatibility getter
  FileInfo? get selectedFile {
    if (selectedItem?.type == TransferItemType.file) {
      // Use the regular create method with file path for existing files
      return FileInfo.create(
        fileName: selectedItem!.name,
        fileSizeBytes: selectedItem!.totalSizeBytes,
        fileType: _getFileExtension(selectedItem!.name),
        filePath: selectedItem!.path,
      ).value;
    }
    return null;
  }

  // Helper method to extract file extension
  String _getFileExtension(String fileName) {
    final lastDot = fileName.lastIndexOf('.');
    if (lastDot > 0 && lastDot < fileName.length - 1) {
      return fileName.substring(lastDot);
    }
    return '';
  }

  // Backward compatibility setter
  void setSelectedFile(FileInfo? file) {
    if (file != null) {
      final itemResult = TransferItem.createFile(filePath: file.filePath);
      if (itemResult.isSuccess) {
        setSelectedItem(itemResult.value);
      }
    } else {
      setSelectedItem(null);
    }
  }

  void setActiveTransfer(TransferSession? session) {
    if (session != null &&
        session.status == TransferStatus.transferring &&
        activeTransfer?.status == TransferStatus.transferring &&
        activeTransfer?.file.fileName == session.file.fileName) {
      // Only debounce progress updates for ongoing transfers, not status changes
      _pendingProgressUpdate = session;
      _progressUpdateTimer?.cancel();
      _progressUpdateTimer = Timer(const Duration(milliseconds: 100), () {
        activeTransfer = _pendingProgressUpdate;
        notifyListeners();
        _pendingProgressUpdate = null;
      });
    } else {
      // Immediate updates for all status changes and initial transfers
      _progressUpdateTimer?.cancel();
      activeTransfer = session;
      notifyListeners();
    }
  }

  void setListening(bool value) {
    isListening = value;
    notifyListeners();
  }

  void updateSettings(AppSettings newSettings) {
    settings = newSettings;
    notifyListeners();
  }

  void toggleListening() {
    isListening = !isListening;
    notifyListeners();
  }

  @override
  void dispose() {
    _progressUpdateTimer?.cancel();
    super.dispose();
  }
}
