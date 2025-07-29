import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:async/async.dart';
import 'package:flutter/foundation.dart';
import '../models/file_info.dart';
import '../models/device.dart';
import '../models/app_state.dart';
import '../models/transfer_session.dart';
import '../utils/constants.dart';

class TcpFileSender {
  final AppState appState;

  TcpFileSender(this.appState);

  Future<void> sendFile(FileInfo file, Device receiver) async {
    StreamQueue<String>? lineQueue;
    Socket? socket;

    try {
      socket = await Socket.connect(
        receiver.ipAddress,
        AppConstants.transferPort,
      );
      if (kDebugMode) print("Connected to receiver at ${receiver.ipAddress}");

      // Buffer the socket stream to allow multiple reads
      lineQueue = StreamQueue<String>(
        socket
            .cast<List<int>>()
            .transform(utf8.decoder)
            .transform(const LineSplitter()),
      );

      final fileToSend = File(file.filePath);
      final totalSize = file.fileSizeBytes;
      final deviceName = appState.settings.localDeviceName;

      // Step 1: Send metadata
      final metadata = {
        "fileName": file.fileName,
        "fileSizeBytes": totalSize,
        "fileType": file.fileType,
        "deviceName": deviceName,
      };
      socket.write(jsonEncode(metadata) + '\n');
      await socket.flush();

      // Step 1.5: Wait for receiver to accept (with timeout)
      final response = await lineQueue.next.timeout(
        const Duration(seconds: 30),
        onTimeout: () => throw TimeoutException(
          "Receiver did not respond within 30 seconds",
        ),
      );

      if (response != 'ACCEPTED') {
        throw Exception("Receiver rejected the transfer: $response");
      }

      // Step 2: Start transfer session
      appState.setActiveTransfer(
        TransferSession(
          direction: TransferDirection.sending,
          file: file,
          progress: 0.0,
          status: TransferStatus.transferring,
          peerDevice: receiver,
        ),
      );

      // Step 3: Start listening for progress updates immediately in parallel
      final progressCompleter = Completer<void>();
      late StreamSubscription progressSubscription;

      // Listen for progress updates from receiver
      progressSubscription = lineQueue.rest.listen(
        (response) {
          if (response.startsWith('PROGRESS:')) {
            final progressStr = response.substring(9);
            final receiverProgress = double.tryParse(progressStr) ?? 0.0;
            appState.setActiveTransfer(
              appState.activeTransfer!.copyWith(progress: receiverProgress),
            );
          } else if (response == 'RECEIVED') {
            appState.setActiveTransfer(
              appState.activeTransfer!.copyWith(
                status: TransferStatus.completed,
                progress: 1.0,
              ),
            );
            if (kDebugMode) print("File sent successfully.");
            progressCompleter.complete();
          } else if (response == 'FAILED' || response == 'CANCELLED') {
            progressCompleter.completeError(
              Exception("Transfer failed or was cancelled by receiver"),
            );
          }
        },
        onError: (error) => progressCompleter.completeError(error),
        onDone: () {
          if (!progressCompleter.isCompleted) {
            progressCompleter.complete();
          }
        },
      );

      // Step 4: Stream file bytes with dynamic chunk size
      int sent = 0;
      final chunkSize = _getOptimalChunkSize(totalSize);
      final raf = fileToSend.openSync();

      try {
        while (sent < totalSize) {
          // Check if transfer was cancelled
          if (appState.activeTransfer?.status == TransferStatus.failed) {
            break;
          }

          final remaining = totalSize - sent;
          final bytes = raf.readSync(
            remaining < chunkSize ? remaining : chunkSize,
          );
          socket.add(bytes);
          sent += bytes.length;

          if (kDebugMode && sent % (chunkSize * 10) == 0) {
            print("Sent $sent / $totalSize bytes");
          }
        }
      } catch (e) {
        if (kDebugMode) print("Error during file streaming: $e");
        throw Exception("File streaming failed: $e");
      } finally {
        raf.close();
      }

      // Check if transfer was cancelled
      if (appState.activeTransfer?.status == TransferStatus.failed) {
        socket.write('CANCELLED\n');
        await socket.flush();
        socket.destroy();
        await progressSubscription.cancel();
        return;
      }

      // Ensure all data is flushed before waiting for completion
      await socket.flush();

      // Wait for transfer completion
      try {
        await progressCompleter.future.timeout(const Duration(seconds: 60));
      } finally {
        await progressSubscription.cancel();
      }
    } catch (e) {
      if (kDebugMode) print("Error during file transfer: $e");
      appState.setActiveTransfer(
        appState.activeTransfer?.copyWith(status: TransferStatus.failed),
      );
      rethrow;
    } finally {
      // Clean up resources
      try {
        await lineQueue?.cancel();
        await socket?.close();
      } catch (e) {
        if (kDebugMode) print("Error during cleanup: $e");
      }
    }
  }

  /// Determines optimal chunk size based on file size for better performance
  int _getOptimalChunkSize(int fileSize) {
    const mb = 1024 * 1024;
    const gb = 1024 * mb;

    if (fileSize < 10 * mb) {
      return 4096; // 4KB for small files
    } else if (fileSize < 100 * mb) {
      return 65536; // 64KB for medium files
    } else if (fileSize < gb) {
      return 524288; // 512KB for large files
    } else {
      return 2097152; // 2MB for very large files
    }
  }
}
