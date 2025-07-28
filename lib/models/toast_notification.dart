import 'package:flutter/material.dart';

/// Toast notification data model
class ToastNotification {
  final String id;
  final String message;
  final ToastType type;
  final DateTime timestamp;
  final Duration duration;

  ToastNotification({
    required this.message,
    this.type = ToastType.info,
    Duration? duration,
  }) : id = DateTime.now().millisecondsSinceEpoch.toString(),
       timestamp = DateTime.now(),
       duration = duration ?? const Duration(seconds: 4);

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is ToastNotification && other.id == id;

  @override
  int get hashCode => id.hashCode;
}

/// Types of toast notifications
enum ToastType { info, success, warning, error }

/// Extension for toast type styling
extension ToastTypeExtension on ToastType {
  Color get backgroundColor {
    switch (this) {
      case ToastType.info:
        return Colors.blue.shade600;
      case ToastType.success:
        return Colors.green.shade600;
      case ToastType.warning:
        return Colors.orange.shade600;
      case ToastType.error:
        return Colors.red.shade600;
    }
  }

  IconData get icon {
    switch (this) {
      case ToastType.info:
        return Icons.info_outline;
      case ToastType.success:
        return Icons.check_circle_outline;
      case ToastType.warning:
        return Icons.warning_amber_outlined;
      case ToastType.error:
        return Icons.error_outline;
    }
  }
}
