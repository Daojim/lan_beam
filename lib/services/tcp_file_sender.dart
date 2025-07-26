import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import '../models/file_info.dart';
import '../models/device.dart';
import '../models/app_state.dart';
import '../models/transfer_session.dart';

class TcpFileSender {
  final AppState appState;

  TcpFileSender(this.appState);

  static const int transferPort = 65001;

  Future<void> sendFile(FileInfo file, Device receiver) async {
    final socket = await Socket.connect(receiver.ipAddress, transferPort);
    if (kDebugMode) print("Connected to receiver at ${receiver.ipAddress}");

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

    while (sent < totalSize) {
      final remaining = totalSize - sent;
      final bytes = raf.readSync(remaining < chunkSize ? remaining : chunkSize);
      socket.add(bytes);
      sent += bytes.length;

      final progress = sent / totalSize;
      appState.setActiveTransfer(
        appState.activeTransfer!.copyWith(progress: progress),
      );
    }

    raf.close();
    socket.close();

    appState.setActiveTransfer(
      appState.activeTransfer!.copyWith(
        status: TransferStatus.completed,
        progress: 1.0,
      ),
    );

    if (kDebugMode) print("File sent successfully.");
  }
}
