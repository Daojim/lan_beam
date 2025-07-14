import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/app_state.dart';
import '../models/transfer_session.dart';
import 'transfer_progress_screen.dart';

class IncomingRequestScreen extends StatelessWidget {
  const IncomingRequestScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final pendingRequest = appState.activeTransfer;

    if (pendingRequest == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Incoming Request')),
        body: const Center(child: Text('No incoming request.')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Incoming Request')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Incoming File Transfer Request',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Text('From: ${pendingRequest.peerDevice.name}'),
            const SizedBox(height: 8),
            Text('File: ${pendingRequest.file.fileName}'),
            const SizedBox(height: 8),
            Text('Size: ${pendingRequest.file.formattedSize}'),
            const SizedBox(height: 8),
            Text('Type: ${pendingRequest.file.fileType}'),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  icon: const Icon(Icons.check),
                  label: const Text('Accept'),
                  onPressed: () {
                    final acceptedSession = pendingRequest.copyWith(
                      status: TransferStatus.transferring,
                      direction: TransferDirection.receiving,
                      progress: 0.0,
                    );
                    appState.setActiveTransfer(acceptedSession);
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const TransferProgressScreen(),
                      ),
                    );
                  },
                ),
                ElevatedButton.icon(
                  icon: const Icon(Icons.close),
                  label: const Text('Reject'),
                  onPressed: () {
                    appState.setActiveTransfer(null);
                    Navigator.of(context).pop();
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
