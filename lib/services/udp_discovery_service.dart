import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import '../models/device.dart';

class UdpDiscoveryService {
  static const int discoveryPort = 65000;
  static const Duration listenDuration = Duration(seconds: 10);

  RawDatagramSocket? _socket;
  bool _isListening = false;

  Future<void> startListening(Function(Device) onDeviceDiscovered) async {
    if (_isListening) return;
    _isListening = true;

    _socket = await RawDatagramSocket.bind(
      InternetAddress.anyIPv4,
      discoveryPort,
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
  }

  Future<void> broadcastHello(String deviceName, String status) async {
    final interfaces = await NetworkInterface.list(
      type: InternetAddressType.IPv4,
    );
    final ip = interfaces
        .expand((i) => i.addresses)
        .firstWhere((a) => a.type == InternetAddressType.IPv4 && !a.isLoopback)
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
      InternetAddress('255.255.255.255'),
      discoveryPort,
    );
    socket.close();
  }

  void dispose() {
    _socket?.close();
    _socket = null;
    _isListening = false;
  }
}
