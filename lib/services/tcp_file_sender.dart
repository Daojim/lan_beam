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

      // Step 3: Stream file bytes
      int sent = 0;
      final chunkSize = 4096;
      final raf = fileToSend.openSync();

      try {
        while (sent < totalSize) {
          final remaining = totalSize - sent;
          final bytes = raf.readSync(
            remaining < chunkSize ? remaining : chunkSize,
          );
          socket.add(bytes);
          sent += bytes.length;

          if (kDebugMode && sent % (chunkSize * 25) == 0) {
            print("Sent $sent / $totalSize bytes");
          }

          final progress = sent / totalSize;
          appState.setActiveTransfer(
            appState.activeTransfer!.copyWith(progress: progress),
          );
        }
      } catch (e) {
        if (kDebugMode) print("Error during file streaming: $e");
        throw Exception("File streaming failed: $e");
      } finally {
        raf.close();
      }

      // Ensure all data is flushed before waiting for final response
      await socket.flush();

      // Step 4: Wait for receiver acknowledgment (with timeout)
      final finalResponse = await lineQueue.next.timeout(
        const Duration(seconds: 10),
        onTimeout: () =>
            throw TimeoutException("Receiver did not confirm receipt"),
      );

      if (finalResponse != 'RECEIVED') {
        throw Exception(
          "Receiver did not confirm file receipt: $finalResponse",
        );
      }

      appState.setActiveTransfer(
        appState.activeTransfer!.copyWith(
          status: TransferStatus.completed,
          progress: 1.0,
        ),
      );

      if (kDebugMode) print("File sent successfully.");
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
}
