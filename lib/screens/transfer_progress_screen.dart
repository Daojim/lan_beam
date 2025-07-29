import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import '../models/app_state.dart';
import '../models/transfer_session.dart';
import '../services/tcp_file_receiver.dart';
import '../utils/service_locator.dart';

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
                      session.status == TransferStatus.failed
                          ? 'CANCELLED'
                          : session.status.name.toUpperCase(),
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            color: session.status == TransferStatus.failed
                                ? Colors.orange
                                : session.status == TransferStatus.completed
                                ? Colors.green
                                : Colors.blue,
                          ),
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
    } else if (session.status == TransferStatus.failed) {
      // Show Done button for failed/cancelled transfers
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: () {
            _clearState(appState);
            Navigator.of(context).popUntil((route) => route.isFirst);
          },
          icon: const Icon(Icons.close),
          label: const Text('Close'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.orange,
            foregroundColor: Colors.white,
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
    // Navigate back to home screen, clearing all intermediate screens
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  Future<void> _cleanupPartialFile(
    TransferSession session,
    AppState appState,
  ) async {
    // Use the service locator to get the receiver and force cleanup
    try {
      if (ServiceLocator.instance.isRegistered<TcpFileReceiver>()) {
        final receiver = ServiceLocator.instance.get<TcpFileReceiver>();
        await receiver.forceCleanupAllTransfers();
        if (kDebugMode) {
          print("Forced cleanup of all active transfers through receiver");
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print("Error during forced cleanup: $e");
      }
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
  ) async {
    // Don't clear state immediately - keep transfer session visible during cleanup
    // Update transfer status to failed/cancelled but keep the session active
    appState.setActiveTransfer(session.copyWith(status: TransferStatus.failed));

    // Clean up partial file if receiving
    if (session.direction == TransferDirection.receiving) {
      await _cleanupPartialFile(session, appState);
    }

    // Give a brief moment for cleanup to complete, then clear state
    await Future.delayed(const Duration(milliseconds: 500));

    // Now clear state and navigate
    _clearState(appState);

    // Navigate back to home screen, clearing all intermediate screens
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  void _clearState(AppState appState) {
    appState.setSelectedItem(null);
    appState.setActiveTransfer(null);
  }
}
