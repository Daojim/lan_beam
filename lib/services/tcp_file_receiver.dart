import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import '../models/device.dart';
import '../models/file_info.dart';
import '../models/transfer_session.dart';
import '../models/app_state.dart';

class TcpFileReceiver {
  final AppState appState;
  ServerSocket? _server;

  static const int transferPort = 65001;

  TcpFileReceiver(this.appState);

  Future<void> startListening() async {
    try {
      _server = await ServerSocket.bind(InternetAddress.anyIPv4, transferPort);
      if (kDebugMode) print("TCP receiver listening on port $transferPort");

      _server!.listen((Socket client) async {
        if (kDebugMode)
          print("Incoming TCP connection from ${client.remoteAddress.address}");

        // Step 1: Receive metadata (JSON-encoded)
        final metadataString = await _readLine(client);
        final metadata = jsonDecode(metadataString);

        final fileInfo = FileInfo(
          fileName: metadata['fileName'],
          fileSizeBytes: metadata['fileSizeBytes'],
          fileType: metadata['fileType'],
          filePath: '', // Set when accepted
        );

        final peer = Device(
          name: metadata['deviceName'] ?? 'Unknown Device',
          ipAddress: client.remoteAddress.address,
          status: DeviceStatus.available,
        );

        // Step 2: Show Incoming Request UI
        appState.setActiveTransfer(
          TransferSession(
            direction: TransferDirection.receiving,
            file: fileInfo,
            progress: 0.0,
            status: TransferStatus.idle,
            peerDevice: peer,
          ),
        );

        // Step 3: Wait for user to accept before continuing
        while (appState.activeTransfer?.status != TransferStatus.transferring) {
          await Future.delayed(const Duration(milliseconds: 100));
        }

        // Step 4: Prepare save location
        final savePath =
            '${appState.settings.defaultSaveFolder}/${fileInfo.fileName}';
        final file = File(savePath);
        final sink = file.openWrite();

        int received = 0;
        await for (final chunk in client) {
          sink.add(chunk);
          received += chunk.length;

          final progress = received / fileInfo.fileSizeBytes;
          appState.setActiveTransfer(
            appState.activeTransfer!.copyWith(progress: progress),
          );
        }

        await sink.close();
        appState.setActiveTransfer(
          appState.activeTransfer!.copyWith(
            progress: 1.0,
            status: TransferStatus.completed,
          ),
        );

        if (kDebugMode) print("File received and saved to $savePath");
        client.destroy();
      });
    } catch (e) {
      if (kDebugMode) print("Error starting TCP receiver: $e");
    }
  }

  Future<void> stopListening() async {
    await _server?.close();
    _server = null;
  }

  // Reads a single UTF-8 line from the socket
  Future<String> _readLine(Socket socket) async {
    final completer = Completer<String>();
    final buffer = StringBuffer();

    socket.listen((data) {
      final chunk = utf8.decode(data);
      buffer.write(chunk);
      if (chunk.contains('\n')) {
        completer.complete(buffer.toString().trim());
      }
    });

    return completer.future;
  }
}
