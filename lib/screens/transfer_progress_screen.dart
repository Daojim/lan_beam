import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import '../models/app_state.dart';
import '../models/transfer_session.dart';

class TransferProgressScreen extends StatelessWidget {
  const TransferProgressScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final session = appState.activeTransfer;

    return PopScope(
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) {
          _handleBackNavigation(context, appState, session);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Transfer Progress'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              _handleBackNavigation(context, appState, session);
              Navigator.of(context).pop();
            },
          ),
        ),
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
                              session.direction == TransferDirection.sending
                                  ? 'Sending To:'
                                  : 'Receiving From:',
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
                    const SizedBox(height: 24),

                    // Action buttons
                    _buildActionButtons(context, appState, session),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildActionButtons(
    BuildContext context,
    AppState appState,
    TransferSession session,
  ) {
    if (session.status == TransferStatus.completed) {
      // Show Done button when transfer is complete
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: () {
            _handleDoneAction(context, appState);
          },
          icon: const Icon(Icons.check),
          label: const Text('Done'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
          ),
        ),
      );
    } else if (session.status == TransferStatus.connecting ||
        session.status == TransferStatus.transferring) {
      // Show Cancel button during active transfer
      return SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: () {
            _handleCancelAction(context, appState, session);
          },
          icon: const Icon(Icons.cancel),
          label: const Text('Cancel Transfer'),
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.red,
            side: const BorderSide(color: Colors.red),
          ),
        ),
      );
    }

    // For other states (failed, idle), show no action button
    return const SizedBox.shrink();
  }

  void _handleBackNavigation(
    BuildContext context,
    AppState appState,
    TransferSession? session,
  ) {
    if (session != null) {
      // Different behavior based on direction and status
      if (session.direction == TransferDirection.sending) {
        // Sending side: keep selection unless completed
        if (session.status == TransferStatus.completed) {
          _clearState(appState);
        }
        // Otherwise keep the selection
      } else {
        // Receiving side: always clear state
        _clearState(appState);
      }
    }
  }

  void _handleDoneAction(BuildContext context, AppState appState) {
    _clearState(appState);
    Navigator.of(context).pop();
  }

  void _cleanupPartialFile(TransferSession session, AppState appState) {
    try {
      final savePath =
          '${appState.settings.defaultSaveFolder}/${session.file.fileName}';
      final file = File(savePath);
      if (file.existsSync()) {
        file.deleteSync();
      }
    } catch (e) {
      // Silently ignore cleanup errors
    }
  }

  void _handleCancelAction(
    BuildContext context,
    AppState appState,
    TransferSession session,
  ) {
    // Show confirmation dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Transfer'),
        content: const Text('Are you sure you want to cancel the transfer?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close dialog
              _cancelTransfer(context, appState, session);
            },
            child: const Text('Yes'),
          ),
        ],
      ),
    );
  }

  void _cancelTransfer(
    BuildContext context,
    AppState appState,
    TransferSession session,
  ) {
    // Update transfer status to failed/cancelled
    appState.setActiveTransfer(session.copyWith(status: TransferStatus.failed));

    // Clean up partial file if receiving
    if (session.direction == TransferDirection.receiving) {
      _cleanupPartialFile(session, appState);
    }

    // Always clear state and go to home screen for cancel
    _clearState(appState);

    // Navigate back to home screen, clearing all intermediate screens
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  void _clearState(AppState appState) {
    appState.setSelectedItem(null);
    appState.setActiveTransfer(null);
  }
}
