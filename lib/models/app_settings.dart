class AppSettings {
  final String localDeviceName;
  final String defaultSaveFolder;
  final bool showMyDeviceForTesting;

  AppSettings({
    required this.localDeviceName,
    required this.defaultSaveFolder,
    this.showMyDeviceForTesting = false,
  });
}
