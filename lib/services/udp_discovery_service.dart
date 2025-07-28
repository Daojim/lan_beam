import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import '../models/device.dart';
import '../utils/result.dart';
import '../utils/constants.dart';
import 'dart:async';

class UdpDiscoveryService {
  Timer? _broadcastTimer;

  RawDatagramSocket? _socket;
  bool _isListening = false;

  Future<Result<void>> startListening(
    Function(Device) onDeviceDiscovered,
  ) async {
    if (_isListening) return const Result.success(null);

    try {
      _isListening = true;

      _socket = await RawDatagramSocket.bind(
        InternetAddress.anyIPv4,
        AppConstants.discoveryPort,
      );
      _socket!.broadcastEnabled = true;

      _socket!.listen((RawSocketEvent event) {
        if (event == RawSocketEvent.read) {
          final datagram = _socket!.receive();
          if (datagram == null) return;

          try {
            final message = utf8.decode(datagram.data);
            final decoded = jsonDecode(message);

            final device = Device(
              name: decoded['deviceName'],
              ipAddress: decoded['ipAddress'],
              status: decoded['status'] == 'available'
                  ? DeviceStatus.available
                  : DeviceStatus.busy,
            );

            onDeviceDiscovered(device);
          } catch (e) {
            if (kDebugMode) print("Failed to parse discovery packet: $e");
          }
        }
      });

      return const Result.success(null);
    } catch (e) {
      _isListening = false;
      return Result.failure(
        'Failed to start UDP discovery listener: $e',
        e is Exception ? e : Exception(e.toString()),
      );
    }
  }

  Future<Result<void>> broadcastHello(String deviceName, String status) async {
    try {
      final interfaces = await NetworkInterface.list(
        type: InternetAddressType.IPv4,
      );
      final ip = interfaces
          .expand((i) => i.addresses)
          .firstWhere(
            (a) => a.type == InternetAddressType.IPv4 && !a.isLoopback,
          )
          .address;

      final message = jsonEncode({
        'deviceName': deviceName,
        'ipAddress': ip,
        'status': status,
      });

      final socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
      socket.broadcastEnabled = true;
      socket.send(
        utf8.encode(message),
        InternetAddress(AppConstants.broadcastAddress),
        AppConstants.discoveryPort,
      );
      socket.close();

      return const Result.success(null);
    } catch (e) {
      return Result.failure(
        'Failed to broadcast discovery message: $e',
        e is Exception ? e : Exception(e.toString()),
      );
    }
  }

  void startBroadcasting(String deviceName, String status) {
    _broadcastTimer?.cancel(); // Avoid multiple timers

    _broadcastTimer = Timer.periodic(AppConstants.discoveryBroadcastInterval, (
      _,
    ) {
      broadcastHello(deviceName, status);
    });
  }

  void stopBroadcasting() {
    _broadcastTimer?.cancel();
    _broadcastTimer = null;
  }

  void dispose() {
    _socket?.close();
    _socket = null;
    _isListening = false;

    stopBroadcasting();
  }
}
