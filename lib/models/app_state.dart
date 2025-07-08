import 'package:flutter/foundation.dart';
import 'device.dart';
import 'file_info.dart';
import 'transfer_session.dart';
import 'app_settings.dart';

class AppState extends ChangeNotifier {
  List<Device> discoveredDevices;
  FileInfo? selectedFile;
  TransferSession? activeTransfer;
  AppSettings settings;
  bool isListening;

  AppState({
    required this.discoveredDevices,
    required this.selectedFile,
    required this.activeTransfer,
    required this.settings,
    required this.isListening,
  });

  void addDevice(Device device) {
    discoveredDevices.add(device);
    notifyListeners();
  }

  void setSelectedFile(FileInfo? file) {
    selectedFile = file;
    notifyListeners();
  }

  void setActiveTransfer(TransferSession? session) {
    activeTransfer = session;
    notifyListeners();
  }

  void setListening(bool value) {
    isListening = value;
    notifyListeners();
  }

  void updateSettings(AppSettings newSettings) {
    settings = newSettings;
    notifyListeners();
  }
}
