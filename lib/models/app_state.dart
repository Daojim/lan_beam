import 'device.dart';
import 'file_info.dart';
import 'transfer_session.dart';
import 'app_settings.dart';

class AppState {
  final List<Device> discoveredDevices;
  final FileInfo? selectedFile;
  final TransferSession? activeTransfer;
  final AppSettings settings;
  final bool isListening;

  AppState({
    required this.discoveredDevices,
    required this.selectedFile,
    required this.activeTransfer,
    required this.settings,
    required this.isListening,
  });
}
