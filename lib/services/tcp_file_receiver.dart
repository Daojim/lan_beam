import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import '../models/device.dart';
import '../models/file_info.dart';
import '../models/transfer_session.dart';
import '../models/app_state.dart';
import '../utils/constants.dart';

class TcpFileReceiver {
  final AppState appState;
  ServerSocket? _server;

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

            // Buffer for all incoming data - single subscription approach
            final dataBuffer = <int>[];
            bool metadataParsed = false;
            FileInfo? fileInfo;
            Device? peer;
            int metadataEndIndex = -1;

            // Create a completer to track when transfer is done
            final transferCompleter = Completer<void>();

            // Single stream subscription to handle everything
            final socketSubscription = client.listen(
              (data) async {
                try {
                  dataBuffer.addAll(data);

                  // Parse metadata if not done yet
                  if (!metadataParsed) {
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

                        // Start waiting for user acceptance in background
                        _handleUserAcceptanceAndFileTransfer(
                          client,
                          dataBuffer,
                          metadataEndIndex,
                          fileInfo!,
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
                    // Metadata already parsed, continue collecting file data
                    // The file writing will be handled in _handleUserAcceptanceAndFileTransfer
                    if (kDebugMode)
                      print(
                        "Received ${data.length} more bytes (total buffer: ${dataBuffer.length})",
                      );
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

  Future<void> _handleUserAcceptanceAndFileTransfer(
    Socket client,
    List<int> dataBuffer,
    int metadataEndIndex,
    FileInfo fileInfo,
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

      // Prepare save location with collision handling
      final savePath = _generateUniqueFilePath(
        appState.settings.defaultSaveFolder,
        fileInfo.fileName,
      );
      final file = File(savePath);
      final sink = file.openWrite();

      // Update transfer session with actual save path
      appState.setActiveTransfer(
        appState.activeTransfer!.copyWith(actualSavePath: savePath),
      );

      int received = 0;
      int totalExpected = fileInfo.fileSizeBytes;
      int lastProgressUpdate = 0;
      const progressUpdateThreshold =
          32768; // Update progress every 32KB to reduce UI lag

      // Process any file data that came with the metadata
      if (dataBuffer.length > metadataEndIndex + 1) {
        final initialFileData = dataBuffer.sublist(metadataEndIndex + 1);
        sink.add(initialFileData);
        received = initialFileData.length;

        final progress = received / totalExpected;
        appState.setActiveTransfer(
          appState.activeTransfer!.copyWith(progress: progress),
        );

        // Send progress update to sender
        _sendProgressUpdate(client, progress);

        if (kDebugMode) print("Initial file data: $received bytes");
      }

      // Wait until we've received all data, checking the buffer periodically
      while (received < totalExpected) {
        // Check if transfer was cancelled
        if (appState.activeTransfer?.status == TransferStatus.failed) {
          break;
        }

        await Future.delayed(
          const Duration(milliseconds: 25),
        ); // Reduced delay for better responsiveness

        // Check if more data has arrived in the buffer
        if (dataBuffer.length > metadataEndIndex + 1) {
          final allFileData = dataBuffer.sublist(metadataEndIndex + 1);
          if (allFileData.length > received) {
            final newData = allFileData.sublist(received);
            sink.add(newData);
            received = allFileData.length;

            // Batch progress updates to reduce UI lag
            if (received - lastProgressUpdate > progressUpdateThreshold ||
                received == totalExpected) {
              final progress = received / totalExpected;
              appState.setActiveTransfer(
                appState.activeTransfer!.copyWith(progress: progress),
              );

              // Send progress update to sender
              _sendProgressUpdate(client, progress);

              lastProgressUpdate = received;

              if (kDebugMode)
                print("Progress: $received / $totalExpected bytes");
            }
          }
        }
      }

      await sink.close();

      // Check if transfer was cancelled
      if (appState.activeTransfer?.status == TransferStatus.failed) {
        // Clean up partial file
        try {
          await file.delete();
        } catch (e) {
          if (kDebugMode) print("Could not delete partial file: $e");
        }
        client.write('CANCELLED\n');
        await client.flush();
        client.destroy();
        transferCompleter.complete();
        return;
      }

      // Verify file size
      final actualFileSize = await file.length();
      if (actualFileSize != fileInfo.fileSizeBytes) {
        if (kDebugMode)
          print(
            "File size mismatch: expected ${fileInfo.fileSizeBytes}, got $actualFileSize",
          );

        // Clean up partial file
        try {
          await file.delete();
        } catch (e) {
          if (kDebugMode) print("Could not delete partial file: $e");
        }

        appState.setActiveTransfer(
          appState.activeTransfer!.copyWith(status: TransferStatus.failed),
        );
        client.write('FAILED\n');
      } else {
        appState.setActiveTransfer(
          appState.activeTransfer!.copyWith(
            progress: 1.0,
            status: TransferStatus.completed,
          ),
        );
        if (kDebugMode) print("File received and saved to $savePath");

        // Send final progress update and acknowledgment
        _sendProgressUpdate(client, 1.0);
        client.write('RECEIVED\n');
        await client.flush();
      }

      await Future.delayed(const Duration(milliseconds: 100));
      client.destroy();

      if (!transferCompleter.isCompleted) {
        transferCompleter.complete();
      }
    } catch (e) {
      if (kDebugMode) print("Error in file transfer handler: $e");
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
