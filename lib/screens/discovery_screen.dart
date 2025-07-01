import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:math';
import '../models/app_state.dart';
import '../models/device.dart';

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
                          trailing: Text(
                            device.status == DeviceStatus.available
                                ? 'Available'
                                : 'Busy',
                          ),
                        );
                      },
                    ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                final random = Random();
                final fakeDevice = Device(
                  name: 'Device-${random.nextInt(1000)}',
                  ipAddress: '192.168.1.${random.nextInt(255)}',
                  status: random.nextBool()
                      ? DeviceStatus.available
                      : DeviceStatus.busy,
                );
                appState.addDevice(fakeDevice);
              },
              child: const Text('Add Fake Device'),
            ),
          ],
        ),
      ),
    );
  }
}
