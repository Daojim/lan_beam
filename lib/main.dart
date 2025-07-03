import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'models/app_state.dart';
import 'models/app_settings.dart';
import 'screens/main_screen.dart';
import 'models/transfer_session.dart';
import 'models/file_info.dart';
import 'models/device.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => AppState(
        discoveredDevices: [],
        selectedFile: null,
        activeTransfer: TransferSession(
          direction: TransferDirection.sending,
          file: FileInfo(
            fileName: 'example.zip',
            fileSizeBytes: 5982345,
            fileType: '.zip',
            filePath: '',
          ),
          progress: 0.0,
          status: TransferStatus.idle,
          peerDevice: Device(
            name: 'Jimmy-PC',
            ipAddress: '192.168.1.101',
            status: DeviceStatus.available,
          ),
        ),
        settings: AppSettings(
          localDeviceName: 'MyDevice',
          defaultSaveFolder: 'C:/Users/Jimmy/Downloads',
        ),
        isListening: false,
      ),
      child: const LanBeamApp(),
    ),
  );
}

class LanBeamApp extends StatelessWidget {
  const LanBeamApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(title: 'LAN Beam', home: const MainScreen());
  }
}
