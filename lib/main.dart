import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'models/app_state.dart';
import 'models/app_settings.dart';
import 'screens/main_screen.dart';
import 'services/tcp_file_receiver.dart';

// Create global access to TcpFileReceiver
late TcpFileReceiver tcpFileReceiver;

// Get the current user's desktop path
String getUserDesktopPath() {
  if (Platform.isWindows) {
    final userProfile = Platform.environment['USERPROFILE'];
    return userProfile != null
        ? '$userProfile\\Desktop'
        : 'C:\\Users\\Public\\Desktop';
  } else if (Platform.isMacOS) {
    final home = Platform.environment['HOME'];
    return home != null ? '$home/Desktop' : '/Users/Public/Desktop';
  } else if (Platform.isLinux) {
    final home = Platform.environment['HOME'];
    return home != null ? '$home/Desktop' : '/home/Public/Desktop';
  } else {
    return 'Desktop'; // Fallback for other platforms
  }
}

// Generate a unique device name based on adjective + animal format
String generateDeviceName() {
  final adjectives = [
    'Swift',
    'Bright',
    'Bold',
    'Quick',
    'Smart',
    'Cool',
    'Fast',
    'Sharp',
    'Clever',
    'Strong',
    'Brave',
    'Calm',
    'Clear',
    'Fresh',
    'Keen',
    'Wise',
    'Active',
    'Alert',
    'Lucky',
    'Happy',
    'Sleek',
    'Smooth',
    'Silent',
    'Steady',
  ];

  final animals = [
    'Fox',
    'Wolf',
    'Bear',
    'Lion',
    'Tiger',
    'Eagle',
    'Hawk',
    'Falcon',
    'Shark',
    'Dolphin',
    'Whale',
    'Leopard',
    'Cheetah',
    'Panther',
    'Raven',
    'Owl',
    'Lynx',
    'Puma',
    'Otter',
    'Badger',
    'Moose',
    'Deer',
    'Elk',
    'Bison',
  ];

  // Use current time as seed for randomization
  final random = DateTime.now().millisecondsSinceEpoch;
  final adjective = adjectives[random % adjectives.length];
  final animal = animals[(random ~/ adjectives.length) % animals.length];

  return '$adjective $animal';
}

void main() {
  // Initialize AppState first so you can pass it to TcpFileReceiver
  final initialState = AppState(
    discoveredDevices: [],
    selectedFile: null,
    activeTransfer: null,
    settings: AppSettings(
      localDeviceName: generateDeviceName(),
      defaultSaveFolder: getUserDesktopPath(),
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
