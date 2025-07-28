import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'models/app_state.dart';
import 'models/app_settings.dart';
import 'screens/main_screen.dart';
import 'services/udp_discovery_service.dart';
import 'models/device.dart';
import 'utils/service_locator.dart';

// Initialize auto-discovery services using service locator
Future<void> initializeServices(AppState appState) async {
  try {
    // Initialize services through service locator
    await ServiceLocator.instance.initializeServices(appState);

    // Get UDP discovery service from service locator
    final udpDiscoveryService = ServiceLocator.instance
        .get<UdpDiscoveryService>();

    // Start listening for other devices
    final listenResult = await udpDiscoveryService.startListening((device) {
      final alreadyExists = appState.discoveredDevices.any(
        (d) => d.ipAddress == device.ipAddress,
      );
      if (!alreadyExists) {
        appState.addDevice(device);
      }
    });

    if (listenResult.isFailure) {
      print('Failed to start UDP listener: ${listenResult.error}');
      return;
    }

    // Start broadcasting this device
    udpDiscoveryService.startBroadcasting(
      appState.settings.localDeviceName,
      DeviceStatus.available.name,
    );

    // TCP receiver is already started by service locator
    appState.setListening(true);

    print('Auto-discovery services started successfully');
  } catch (e) {
    print('Failed to start auto-discovery services: $e');
    // Continue running the app even if discovery fails
  }
}

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
  // Initialize AppState first
  final initialState = AppState(
    discoveredDevices: [],
    selectedFile: null,
    activeTransfer: null,
    settings: AppSettings(
      localDeviceName: generateDeviceName(),
      defaultSaveFolder: getUserDesktopPath(),
      showMyDeviceForTesting: false, // Default to false for production use
    ),
    isListening: false,
  );

  runApp(
    ChangeNotifierProvider(
      create: (_) => initialState,
      child: LanBeamApp(appState: initialState),
    ),
  );
}

class LanBeamApp extends StatefulWidget {
  final AppState appState;

  const LanBeamApp({super.key, required this.appState});

  @override
  State<LanBeamApp> createState() => _LanBeamAppState();
}

class _LanBeamAppState extends State<LanBeamApp> {
  @override
  void initState() {
    super.initState();
    // Initialize auto-discovery services after the widget is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      initializeServices(widget.appState);
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(title: 'LAN Beam', home: const MainScreen());
  }
}
