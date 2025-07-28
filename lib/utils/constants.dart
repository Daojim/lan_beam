/// Application-wide constants
class AppConstants {
  // Network Constants
  static const int discoveryPort = 65000;
  static const int transferPort = 65001;
  static const Duration discoveryBroadcastInterval = Duration(seconds: 1);
  static const Duration listenDuration = Duration(seconds: 10);
  static const String broadcastAddress = '255.255.255.255';

  // UI Constants
  static const double defaultPadding = 16.0;
  static const double cardElevation = 2.0;
  static const double borderRadius = 8.0;
  static const double deviceListHeight = 300.0;

  // File Transfer Constants
  static const int maxFileSize = 10 * 1024 * 1024 * 1024; // 10GB
  static const int transferBufferSize = 64 * 1024; // 64KB chunks

  // Device Constants
  static const int maxDeviceNameLength = 50;
  static const int maxDevicesInList = 100;

  // Error Messages
  static const String networkErrorMessage = 'Network connection failed';
  static const String fileNotFoundMessage = 'File not found';
  static const String transferFailedMessage = 'File transfer failed';
  static const String deviceNotAvailableMessage = 'Device is not available';
}
