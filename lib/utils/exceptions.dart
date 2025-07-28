/// Base exception for all LAN Beam errors
abstract class LanBeamException implements Exception {
  const LanBeamException(this.message);
  final String message;

  @override
  String toString() => 'LanBeamException: $message';
}

/// Network-related exceptions
class NetworkException extends LanBeamException {
  const NetworkException(super.message);

  @override
  String toString() => 'NetworkException: $message';
}

/// File-related exceptions
class FileException extends LanBeamException {
  const FileException(super.message);

  @override
  String toString() => 'FileException: $message';
}

/// Device discovery exceptions
class DiscoveryException extends LanBeamException {
  const DiscoveryException(super.message);

  @override
  String toString() => 'DiscoveryException: $message';
}

/// Transfer-related exceptions
class TransferException extends LanBeamException {
  const TransferException(super.message);

  @override
  String toString() => 'TransferException: $message';
}

/// Connection-related exceptions
class ConnectionException extends NetworkException {
  const ConnectionException(super.message);

  @override
  String toString() => 'ConnectionException: $message';
}
