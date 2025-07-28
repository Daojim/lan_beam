// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:lan_beam/models/app_state.dart';
import 'package:lan_beam/models/app_settings.dart';
import 'package:lan_beam/screens/main_screen.dart';

void main() {
  testWidgets('LAN Beam main screen loads correctly', (
    WidgetTester tester,
  ) async {
    // Create a test app state
    final testAppState = AppState(
      discoveredDevices: [],
      selectedItem: null, // Changed from selectedFile
      activeTransfer: null,
      settings: AppSettings(
        localDeviceName: 'Test Device',
        defaultSaveFolder: 'Desktop',
        showMyDeviceForTesting: false,
      ),
      isListening: false,
    );

    // Build our app and trigger a frame.
    await tester.pumpWidget(
      MaterialApp(
        home: ChangeNotifierProvider(
          create: (_) => testAppState,
          child: const MainScreen(),
        ),
      ),
    );

    // Allow the app to initialize
    await tester.pumpAndSettle();

    // Verify that key elements are present
    expect(find.text('Device Information'), findsOneWidget);
    expect(find.text('File Selection'), findsOneWidget);
    expect(find.text('No file selected.'), findsOneWidget);
    expect(find.text('Choose File'), findsOneWidget);
  });

  testWidgets('AppState manages file selection correctly', (
    WidgetTester tester,
  ) async {
    // Create a test app state
    final testAppState = AppState(
      discoveredDevices: [],
      selectedItem: null, // Changed from selectedFile
      activeTransfer: null,
      settings: AppSettings(
        localDeviceName: 'Test Device',
        defaultSaveFolder: 'Desktop',
        showMyDeviceForTesting: false,
      ),
      isListening: false,
    );

    // Test that initially no file is selected
    expect(testAppState.selectedFile, isNull);

    // Test that device name is correctly set
    expect(testAppState.settings.localDeviceName, equals('Test Device'));

    // Test device filtering setting
    expect(testAppState.settings.showMyDeviceForTesting, isFalse);
  });
}
