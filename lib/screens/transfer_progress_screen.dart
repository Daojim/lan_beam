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
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Card(
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'File: ${session.file.fileName}',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          Text('Size: ${session.file.formattedSize}'),
                          const SizedBox(height: 8),
                          Text('Type: ${session.file.fileType}'),
                          const SizedBox(height: 16),
                          Text(
                            'Sending To:',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${session.peerDevice.name} (${session.peerDevice.ipAddress})',
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Transfer Status:',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    session.status.name.toUpperCase(),
                    style: Theme.of(
                      context,
                    ).textTheme.headlineSmall?.copyWith(color: Colors.blue),
                  ),
                  const SizedBox(height: 16),
                  LinearProgressIndicator(value: session.progress),
                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: () {
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
