import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'models/app_state.dart';
import 'models/app_settings.dart';
import 'screens/main_screen.dart';
import 'services/tcp_file_receiver.dart';

// Create global access to TcpFileReceiver
late TcpFileReceiver tcpFileReceiver;

void main() {
  // Initialize AppState first so you can pass it to TcpFileReceiver
  final initialState = AppState(
    discoveredDevices: [],
    selectedFile: null,
    activeTransfer: null,
    settings: AppSettings(
      localDeviceName: 'MyDevice',
      defaultSaveFolder: 'C:/Users/Jimmy/Desktop',
    ),
    isListening: false,
  );

  // Initialize the TCP receiver with that app state
  tcpFileReceiver = TcpFileReceiver(initialState);

  runApp(
    ChangeNotifierProvider(
      create: (_) => initialState,
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
