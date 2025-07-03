import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/app_state.dart';
import '../models/transfer_session.dart';

class TransferProgressScreen extends StatelessWidget {
  const TransferProgressScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final session = appState.activeTransfer;

    return Scaffold(
      appBar: AppBar(title: const Text('Transfer Progress')),
      body: session == null
          ? const Center(child: Text('No active transfer session.'))
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('File: ${session.file.fileName}'),
                  const SizedBox(height: 8),
                  Text('Size: ${session.file.fileSizeBytes} bytes'),
                  const SizedBox(height: 8),
                  Text(
                    'Peer: ${session.peerDevice.name} (${session.peerDevice.ipAddress})',
                  ),
                  const SizedBox(height: 8),
                  Text('Direction: ${session.direction.name}'),
                  const SizedBox(height: 8),
                  Text('Status: ${session.status.name}'),
                  const SizedBox(height: 16),
                  LinearProgressIndicator(value: session.progress),
                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: () {
                      // For demo/testing: simulate progress
                      double newProgress = (session.progress + 0.1).clamp(
                        0.0,
                        1.0,
                      );
                      final updatedSession = session.copyWith(
                        progress: newProgress,
                      );
                      appState.setActiveTransfer(updatedSession);
                    },
                    child: const Text('Simulate Progress'),
                  ),
                ],
              ),
            ),
    );
  }
}
