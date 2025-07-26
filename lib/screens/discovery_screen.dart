import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/app_state.dart';
import '../models/device.dart';
import '../models/transfer_session.dart';
import './transfer_progress_screen.dart';
import '../services/udp_discovery_service.dart';
import '../services/tcp_file_sender.dart';

class DiscoveryScreen extends StatefulWidget {
  const DiscoveryScreen({super.key});

  @override
  State<DiscoveryScreen> createState() => _DiscoveryScreenState();
}

class _DiscoveryScreenState extends State<DiscoveryScreen> {
  final UdpDiscoveryService _discovery = UdpDiscoveryService();

  @override
  void initState() {
    super.initState();

    // Delay listening until after widget is built
    Future.microtask(() async {
      final appState = context.read<AppState>();

      await _discovery.startListening((device) {
        final alreadyExists = appState.discoveredDevices.any(
          (d) => d.ipAddress == device.ipAddress,
        );
        if (!alreadyExists) {
          appState.addDevice(device);
        }
      });

      _discovery.startBroadcasting(
        appState.settings.localDeviceName,
        DeviceStatus.available.name,
      );
    });
  }

  @override
  void dispose() {
    _discovery.dispose();
    super.dispose();
  }

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
                                    : () async {
                                        // Start transfer session visually first
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

                                        // Navigate to progress screen
                                        Navigator.of(context).push(
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                const TransferProgressScreen(),
                                          ),
                                        );

                                        // Start sending file over TCP
                                        final sender = TcpFileSender(appState);
                                        await sender.sendFile(
                                          appState.selectedFile!,
                                          device,
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
