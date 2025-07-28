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
                    if (transferState?.fileSink != null) {
                      transferState!.fileSink!.add(data);
                      transferState.receivedBytes += data.length;

                      // Throttle progress updates to prevent UI flooding
                      final progress =
                          transferState.receivedBytes /
                          transferState.fileInfo!.fileSizeBytes;
                      if (transferState.receivedBytes % 131072 == 0 ||
                          progress >= 1.0) {
                        // Update every 128KB
                        appState.setActiveTransfer(
                          appState.activeTransfer!.copyWith(progress: progress),
                        );
                        _sendProgressUpdate(client, progress);

                        // Check if transfer is complete
                        if (progress >= 1.0) {
                          await transferState.fileSink!.close();
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
                  print("Socket connection closed during receive");
                // Don't complete here - let _handleUserAcceptanceAndFileTransfer handle completion
              },
            );

            // Wait for transfer to complete
            await transferCompleter.future;
            await socketSubscription.cancel();
          } catch (e) {
            if (kDebugMode) print("Error during file transfer: $e");
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
          if (kDebugMode) print("Socket connection closed");
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

  Future<void> stopListening() async {
    await _server?.close();
    _server = null;
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
