import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/app_state.dart';
import '../models/transfer_session.dart';
import '../models/device.dart';
import '../screens/incoming_request_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();

    final selectedFile = appState.selectedFile;

    return Scaffold(
      appBar: AppBar(title: const Text('Home')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Device Name: ${appState.settings.localDeviceName}'),
            const SizedBox(height: 8),
            Text('Default Save Folder: ${appState.settings.defaultSaveFolder}'),
            const SizedBox(height: 8),
            Text(
              'Listening for Incoming Requests: ${appState.isListening ? "Yes" : "No"}',
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                appState.toggleListening();
              },
              child: Text(
                appState.isListening ? 'Stop Listening' : 'Start Listening',
              ),
            ),

            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                // Only allow simulating if there's a file selected
                if (appState.selectedFile == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please pick a file first.')),
                  );
                  return;
                }

                // Create a fake sending TransferSession to simulate an incoming request
                appState.setActiveTransfer(
                  TransferSession(
                    direction: TransferDirection.sending,
                    file: appState.selectedFile!,
                    progress: 0.0,
                    status: TransferStatus.idle,
                    peerDevice: Device(
                      name: 'TestSender-PC',
                      ipAddress: '192.168.1.99',
                      status: DeviceStatus.available,
                    ),
                  ),
                );

                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const IncomingRequestScreen(),
                  ),
                );
              },
              child: const Text('Simulate Incoming Request'),
            ),

            const SizedBox(height: 32),
            Text(
              'Selected File:',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            if (selectedFile == null)
              const Text('No file selected.')
            else ...[
              Text('File Name: ${selectedFile.fileName}'),
              Text('File Type: ${selectedFile.fileType}'),
              Text('File Size: ${selectedFile.formattedSize}'),
            ],
          ],
        ),
      ),
    );
  }
}
