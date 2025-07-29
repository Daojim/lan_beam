import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import '../models/device.dart';
import '../models/file_info.dart';
import '../models/transfer_session.dart';
import '../models/app_state.dart';
import '../utils/constants.dart';

class _TransferState {
  IOSink? fileSink;
  int receivedBytes = 0;
  FileInfo? fileInfo;
  String? savePath; // Track the actual save path for cleanup
  bool isCancelled = false; // Flag for immediate cancellation detection
  bool isCompleted = false; // Flag to track successful completion
}

class TcpFileReceiver {
  final AppState appState;
  ServerSocket? _server;

  // Per-connection state for streaming transfers
  final Map<Socket, _TransferState> _activeTransfers = {};

  TcpFileReceiver(this.appState);

  Future<void> startListening() async {
    try {
      _server = await ServerSocket.bind(
        InternetAddress.anyIPv4,
        AppConstants.transferPort,
      );
      if (kDebugMode)
        print("TCP receiver listening on port ${AppConstants.transferPort}");

      _server!.listen(
        (Socket client) async {
          try {
            if (kDebugMode)
              print(
                "Incoming TCP connection from ${client.remoteAddress.address}",
              );

            // Buffer for incoming data - but limit size to prevent memory issues
            final dataBuffer = <int>[];
            bool metadataParsed = false;
            FileInfo? fileInfo;
            Device? peer;
            int metadataEndIndex = -1;

            // For streaming file directly to disk
            String? actualSavePath;

            // Create a completer to track when transfer is done
            final transferCompleter = Completer<void>();

            // Single stream subscription to handle everything
            final socketSubscription = client.listen(
              (data) async {
                try {
                  if (!metadataParsed) {
                    // Still parsing metadata
                    dataBuffer.addAll(data);

                    // Look for newline to find end of metadata
                    for (int i = 0; i < dataBuffer.length; i++) {
                      if (dataBuffer[i] == 10) {
                        // newline character
                        metadataEndIndex = i;
                        break;
                      }
                    }

                    if (metadataEndIndex != -1) {
                      // Extract and parse metadata
                      final metadataBytes = dataBuffer.sublist(
                        0,
                        metadataEndIndex,
                      );
                      final metadataString = utf8.decode(metadataBytes).trim();

                      try {
                        final metadata = jsonDecode(metadataString);

                        final fileInfoResult =
                            FileInfo.createForIncomingTransfer(
                              fileName: metadata['fileName'],
                              fileSizeBytes: metadata['fileSizeBytes'],
                              fileType: metadata['fileType'],
                            );

                        if (fileInfoResult.isFailure) {
                          if (kDebugMode)
                            print('Invalid file info: ${fileInfoResult.error}');
                          client.close();
                          return;
                        }

                        fileInfo = fileInfoResult.value;

                        peer = Device(
                          name: metadata['deviceName'] ?? 'Unknown Device',
                          ipAddress: client.remoteAddress.address,
                          status: DeviceStatus.available,
                        );

                        metadataParsed = true;

                        // Show incoming request UI
                        appState.setActiveTransfer(
                          TransferSession(
                            direction: TransferDirection.receiving,
                            file: fileInfo!,
                            progress: 0.0,
                            status: TransferStatus.idle,
                            peerDevice: peer!,
                          ),
                        );

                        if (kDebugMode)
                          print(
                            "Metadata parsed: ${fileInfo!.fileName}, ${fileInfo!.fileSizeBytes} bytes",
                          );

                        // Prepare file for streaming
                        actualSavePath = _generateUniqueFilePath(
                          appState.settings.defaultSaveFolder,
                          fileInfo!.fileName,
                        );

                        // Initialize transfer state for this connection
                        _activeTransfers[client] = _TransferState()
                          ..fileInfo = fileInfo;

                        // Start handling file transfer in background
                        _handleStreamingFileTransfer(
                          client,
                          dataBuffer,
                          metadataEndIndex,
                          fileInfo!,
                          actualSavePath!,
                          transferCompleter,
                        );
                      } catch (e) {
                        if (kDebugMode) print("Error parsing metadata: $e");
                        client.write('FAILED\n');
                        client.destroy();
                        transferCompleter.completeError(e);
                        return;
                      }
                    }
                  } else {
                    // Metadata already parsed, stream file data directly to disk
                    final transferState = _activeTransfers[client];
                    if (transferState != null &&
                        transferState.fileSink != null) {
                      // Check if transfer was cancelled BEFORE processing any data
                      if (appState.activeTransfer?.status ==
                              TransferStatus.failed ||
                          transferState.isCancelled) {
                        // Mark as cancelled and clean up immediately without processing data
                        transferState.isCancelled = true;
                        await _performImmediateCleanup(client, transferState);
                        return;
                      }

                      transferState.fileSink!.add(data);
                      transferState.receivedBytes += data.length;

                      // Check for cancellation after each chunk
                      if (appState.activeTransfer?.status ==
                          TransferStatus.failed) {
                        if (kDebugMode)
                          print(
                            "Transfer cancelled during data processing - cleaning up immediately",
                          );
                        transferState.isCancelled = true;
                        await _performImmediateCleanup(client, transferState);
                        transferCompleter
                            .complete(); // Complete normally to avoid error
                        return;
                      }

                      // Send frequent progress updates for smooth synchronization
                      final progress =
                          transferState.receivedBytes /
                          transferState.fileInfo!.fileSizeBytes;
                      if (transferState.receivedBytes % 8192 == 0 ||
                          progress >= 1.0) {
                        // Update every 8KB for smooth progress bars
                        appState.setActiveTransfer(
                          appState.activeTransfer!.copyWith(progress: progress),
                        );
                        _sendProgressUpdate(client, progress);

                        // Check if transfer is complete
                        if (progress >= 1.0) {
                          await transferState.fileSink!.close();

                          // Mark as completed before removing from active transfers
                          transferState.isCompleted = true;
                          _activeTransfers.remove(client);

                          appState.setActiveTransfer(
                            appState.activeTransfer!.copyWith(
                              status: TransferStatus.completed,
                              progress: 1.0,
                            ),
                          );

                          client.write('RECEIVED\n');
                          await client.flush();
                          transferCompleter.complete();
                        }
                      }
                    }
                  }
                } catch (e) {
                  if (kDebugMode) print("Error in data handler: $e");
                  transferCompleter.completeError(e);
                }
              },
              onError: (error) {
                if (kDebugMode) print("Socket error during receive: $error");

                // Force cleanup on socket error
                final transferState = _activeTransfers[client];
                if (transferState != null && !transferState.isCompleted) {
                  transferState.isCancelled = true;
                  _performImmediateCleanup(client, transferState);
                }

                appState.setActiveTransfer(
                  appState.activeTransfer?.copyWith(
                    status: TransferStatus.failed,
                  ),
                );
                if (!transferCompleter.isCompleted) {
                  transferCompleter.completeError(error);
                }
              },
              onDone: () {
                if (kDebugMode)
                  print(
                    "Socket connection closed during receive - sender likely cancelled",
                  );

                // Handle sender disconnection/cancellation
                final transferState = _activeTransfers[client];
                if (transferState != null && !transferState.isCompleted) {
                  // Mark as cancelled and clean up
                  transferState.isCancelled = true;

                  // Update app state to show cancellation
                  appState.setActiveTransfer(
                    appState.activeTransfer?.copyWith(
                      status: TransferStatus.failed,
                    ),
                  );

                  // Perform cleanup asynchronously
                  _performImmediateCleanup(client, transferState);
                }

                // Complete the transfer completer to stop waiting
                if (!transferCompleter.isCompleted) {
                  transferCompleter.complete();
                }
              },
            );

            // Wait for transfer to complete
            await transferCompleter.future;
            await socketSubscription.cancel();
          } catch (e) {
            if (kDebugMode) print("Error during file transfer: $e");

            // Force cleanup on exception
            final transferState = _activeTransfers[client];
            if (transferState != null && !transferState.isCompleted) {
              transferState.isCancelled = true;
              await _performImmediateCleanup(client, transferState);
            }

            appState.setActiveTransfer(
              appState.activeTransfer?.copyWith(status: TransferStatus.failed),
            );

            try {
              client.write('FAILED\n');
              await client.flush();
            } catch (writeError) {
              if (kDebugMode)
                print("Could not notify sender of error: $writeError");
            }

            try {
              client.destroy();
            } catch (closeError) {
              if (kDebugMode) print("Error closing client socket: $closeError");
            }
          }
        },
        onError: (error) {
          if (kDebugMode) print("Socket error: $error");
        },
        onDone: () {
          if (kDebugMode) print("Server socket connection closed");

          // Handle any incomplete transfers when server stops
          for (final entry in _activeTransfers.entries) {
            final client = entry.key;
            final transferState = entry.value;
            if (!transferState.isCompleted) {
              transferState.isCancelled = true;
              appState.setActiveTransfer(
                appState.activeTransfer?.copyWith(
                  status: TransferStatus.failed,
                ),
              );
              _performImmediateCleanup(client, transferState);
            }
          }
        },
      );
    } catch (e) {
      if (kDebugMode) print("Error starting TCP receiver: $e");
    }
  }

  Future<void> _handleStreamingFileTransfer(
    Socket client,
    List<int> dataBuffer,
    int metadataEndIndex,
    FileInfo fileInfo,
    String savePath,
    Completer<void> transferCompleter,
  ) async {
    try {
      // Wait for user to accept
      while (appState.activeTransfer?.status != TransferStatus.transferring) {
        await Future.delayed(const Duration(milliseconds: 100));
        // Check if transfer was cancelled during acceptance wait
        if (appState.activeTransfer?.status == TransferStatus.failed) {
          client.write('REJECTED\n');
          await client.flush();
          client.destroy();
          transferCompleter.complete();
          return;
        }
      }

      // Send acceptance confirmation
      client.write('ACCEPTED\n');
      await client.flush();

      // Update transfer session with actual save path
      appState.setActiveTransfer(
        appState.activeTransfer!.copyWith(actualSavePath: savePath),
      );

      // Open file for writing
      final file = File(savePath);
      final transferState = _activeTransfers[client];
      if (transferState != null) {
        transferState.fileSink = file.openWrite();
        transferState.receivedBytes = 0;
        transferState.savePath = savePath; // Store save path for cleanup

        // Process any file data that came with the metadata
        if (dataBuffer.length > metadataEndIndex + 1) {
          final initialFileData = dataBuffer.sublist(metadataEndIndex + 1);
          transferState.fileSink!.add(initialFileData);
          transferState.receivedBytes = initialFileData.length;

          final progress = transferState.receivedBytes / fileInfo.fileSizeBytes;
          appState.setActiveTransfer(
            appState.activeTransfer!.copyWith(progress: progress),
          );
          _sendProgressUpdate(client, progress);

          if (kDebugMode)
            print("Initial file data: ${transferState.receivedBytes} bytes");
        }

        // Clear the buffer to free memory - streaming will handle the rest
        dataBuffer.clear();

        // Start monitoring for cancellation
        _monitorCancellation(client, transferState);

        // Send immediate initial progress to sync both sides
        _sendProgressUpdate(client, 0.0);

        if (kDebugMode)
          print("Streaming mode enabled for ${fileInfo.fileName}");
      }
    } catch (e) {
      if (kDebugMode) print("Error in streaming setup: $e");
      if (!transferCompleter.isCompleted) {
        transferCompleter.completeError(e);
      }
    }
  }

  void _sendProgressUpdate(Socket client, double progress) {
    try {
      client.write('PROGRESS:${progress.toStringAsFixed(3)}\n');
    } catch (e) {
      if (kDebugMode) print("Could not send progress update: $e");
    }
  }

  /// Monitor for transfer cancellation and immediately mark transfer state
  void _monitorCancellation(Socket client, _TransferState transferState) {
    Timer.periodic(const Duration(milliseconds: 50), (timer) async {
      // Only cleanup if explicitly failed, not if completed successfully
      if (appState.activeTransfer?.status == TransferStatus.failed) {
        transferState.isCancelled = true;

        // Only perform cleanup if transfer wasn't completed successfully
        if (!transferState.isCompleted) {
          if (kDebugMode)
            print(
              "Cancellation detected in monitor - forcing immediate cleanup",
            );
          await _performImmediateCleanup(client, transferState);
        }

        timer.cancel();
      } else if (!_activeTransfers.containsKey(client)) {
        // Transfer finished (either completed or failed) - stop monitoring
        timer.cancel();
      }
    });
  }

  /// Perform immediate cleanup when cancellation is detected
  Future<void> _performImmediateCleanup(
    Socket client,
    _TransferState transferState,
  ) async {
    try {
      // Only cleanup if not already completed successfully
      if (transferState.isCompleted) {
        return;
      }

      // Close the file sink if it's open and wait for it to properly close
      if (transferState.fileSink != null) {
        try {
          await transferState.fileSink!.flush(); // Ensure all data is written
          await transferState.fileSink!.close(); // Close the file handle
          transferState.fileSink = null; // Clear the reference immediately

          // Give a longer delay to ensure file handle is fully released by Windows
          await Future.delayed(const Duration(milliseconds: 500));

          if (kDebugMode)
            print("File sink closed and nullified for cancellation cleanup");
        } catch (e) {
          if (kDebugMode) print("Error closing file sink: $e");
          transferState.fileSink = null; // Clear the reference even on error
        }
      }

      // Delete the partial file with retry logic
      if (transferState.savePath != null) {
        final partialFile = File(transferState.savePath!);
        if (await partialFile.exists()) {
          // Try to delete with retries in case file handle is still being released
          bool deleted = false;
          for (int attempt = 0; attempt < 3 && !deleted; attempt++) {
            try {
              await partialFile.delete();
              deleted = true;
              if (kDebugMode) {
                print(
                  "Successfully deleted partial file: ${transferState.savePath}",
                );
              }
            } catch (e) {
              if (kDebugMode) {
                print(
                  "Attempt ${attempt + 1} to delete partial file failed: $e",
                );
              }
              if (attempt < 2) {
                // Wait a bit longer before retrying
                await Future.delayed(
                  Duration(milliseconds: 200 * (attempt + 1)),
                );
              } else {
                if (kDebugMode) {
                  print(
                    "Failed to delete partial file after 3 attempts: ${transferState.savePath}",
                  );
                }
              }
            }
          }
        }
      }

      // Clean up the transfer state and notify sender (only if still active)
      if (_activeTransfers.containsKey(client)) {
        _activeTransfers.remove(client);
      }

      // Try to notify sender about cancellation
      try {
        client.write('CANCELLED\n');
        await client.flush();
      } catch (e) {
        // Socket operations might fail if connection is already closed
        if (kDebugMode) print("Could not notify sender of cancellation: $e");
      }

      try {
        client.destroy();
      } catch (e) {
        // Socket might already be destroyed
      }
    } catch (e) {
      if (kDebugMode) print("Error during immediate cleanup: $e");
    }
  }

  Future<void> stopListening() async {
    // Close all active file sinks before stopping the server
    for (final transferState in _activeTransfers.values) {
      if (transferState.fileSink != null) {
        try {
          await transferState.fileSink!.flush();
          await transferState.fileSink!.close();
          transferState.fileSink = null;
        } catch (e) {
          if (kDebugMode) print("Error closing file sink during shutdown: $e");
        }
      }
    }
    _activeTransfers.clear();

    await _server?.close();
    _server = null;
  }

  /// Force cleanup of all active transfers (useful for cancellation)
  Future<void> forceCleanupAllTransfers() async {
    final transfersCopy = Map.from(_activeTransfers);
    for (final entry in transfersCopy.entries) {
      final client = entry.key;
      final transferState = entry.value;
      if (!transferState.isCompleted) {
        transferState.isCancelled = true;
        await _performImmediateCleanup(client, transferState);
      }
    }
  }

  /// Generates a unique file path by adding incremental numbers if file exists
  String _generateUniqueFilePath(String saveFolder, String fileName) {
    // Parse the original filename and extension
    final lastDot = fileName.lastIndexOf('.');
    String nameWithoutExtension;
    String extension;

    if (lastDot > 0 && lastDot < fileName.length - 1) {
      nameWithoutExtension = fileName.substring(0, lastDot);
      extension = fileName.substring(lastDot);
    } else {
      nameWithoutExtension = fileName;
      extension = '';
    }

    // Start with the original path
    String candidatePath = '$saveFolder/$fileName';
    File candidateFile = File(candidatePath);

    // If file doesn't exist, use original name
    if (!candidateFile.existsSync()) {
      return candidatePath;
    }

    // File exists, find next available number
    int counter = 1;
    while (true) {
      final newFileName = '$nameWithoutExtension-$counter$extension';
      candidatePath = '$saveFolder/$newFileName';
      candidateFile = File(candidatePath);

      if (!candidateFile.existsSync()) {
        return candidatePath;
      }
      counter++;
    }
  }
}
