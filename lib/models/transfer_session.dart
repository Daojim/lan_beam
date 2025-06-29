import 'device.dart';
import 'file_info.dart';

enum TransferDirection { sending, receiving }

enum TransferStatus { idle, connecting, transferring, completed, failed }

class TransferSession {
  final TransferDirection direction;
  final FileInfo file;
  final double progress; // 0.0 - 1.0, progress bar
  final TransferStatus status;
  final Device peerDevice;

  TransferSession({
    required this.direction,
    required this.file,
    required this.progress,
    required this.status,
    required this.peerDevice,
  });
}
