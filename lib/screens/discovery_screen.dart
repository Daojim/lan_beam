import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/app_state.dart';
import '../models/device.dart';
import '../models/transfer_session.dart';
import './transfer_progress_screen.dart';
import '../services/udp_discovery_service.dart';

class DiscoveryScreen extends StatelessWidget {
  const DiscoveryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final devices = appState.discoveredDevices;

    return Scaffold(
      appBar: AppBar(title: const Text('Device Discovery')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Expanded(
              child: devices.isEmpty
                  ? const Center(child: Text('No devices discovered yet.'))
                  : ListView.builder(
                      itemCount: devices.length,
                      itemBuilder: (context, index) {
                        final device = devices[index];
                        return ListTile(
                          leading: const Icon(Icons.devices),
                          title: Text(device.name),
                          subtitle: Text(device.ipAddress),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                device.status == DeviceStatus.available
                                    ? 'Available'
                                    : 'Busy',
                              ),
                              const SizedBox(width: 8),
                              ElevatedButton(
                                onPressed:
                                    appState.selectedFile == null ||
                                        device.status != DeviceStatus.available
                                    ? null
                                    : () {
                                        if (appState.selectedFile == null) {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                'Please pick a file first',
                                              ),
                                            ),
                                          );
                                          return;
                                        }

                                        if (device.status !=
                                            DeviceStatus.available) {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            const SnackBar(
                                              content: Text('Device is busy.'),
                                            ),
                                          );
                                          return;
                                        }

                                        appState.setActiveTransfer(
                                          TransferSession(
                                            direction:
                                                TransferDirection.sending,
                                            file: appState.selectedFile!,
                                            progress: 0.0,
                                            status: TransferStatus.connecting,
                                            peerDevice: device,
                                          ),
                                        );

                                        Navigator.of(context).push(
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                const TransferProgressScreen(),
                                          ),
                                        );
                                      },

                                child: const Text('Send'),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () async {
                final discovery = UdpDiscoveryService();

                // Start listening for incoming discovery responses
                await discovery.startListening((device) {
                  // Avoid duplicates by IP
                  final alreadyExists = appState.discoveredDevices.any(
                    (d) => d.ipAddress == device.ipAddress,
                  );
                  if (!alreadyExists) {
                    appState.addDevice(device);
                  }
                });

                // Broadcast your device info
                await discovery.broadcastHello(
                  appState.settings.localDeviceName,
                  DeviceStatus.available.name,
                );

                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text('Broadcast sent')));
              },
              child: const Text('Broadcast Discovery'),
            ),

            const SizedBox(height: 8),

            ElevatedButton(
              onPressed: () {
                appState.discoveredDevices.clear();
                appState.notifyListeners();
              },
              child: const Text('Clear Devices'),
            ),
          ],
        ),
      ),
    );
  }
}
