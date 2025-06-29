import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'models/app_state.dart';
import 'models/app_settings.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => AppState(
        discoveredDevices: [],
        selectedFile: null,
        activeTransfer: null,
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
    return MaterialApp(
      title: 'LAN Beam',
      home: Scaffold(
        appBar: AppBar(title: const Text('LAN Beam')),
        body: const Center(child: Text('Welcome to LAN Beam!')),
      ),
    );
  }
}
