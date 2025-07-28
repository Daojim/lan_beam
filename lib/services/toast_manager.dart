import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/toast_notification.dart';

/// Service for managing toast notifications
class ToastManager extends ChangeNotifier {
  static final ToastManager _instance = ToastManager._internal();
  factory ToastManager() => _instance;
  ToastManager._internal();

  static ToastManager get instance => _instance;

  final List<ToastNotification> _notifications = [];
  final Map<String, Timer> _timers = {};

  List<ToastNotification> get notifications =>
      List.unmodifiable(_notifications);

  /// Show a toast notification
  void showToast({
    required String message,
    ToastType type = ToastType.info,
    Duration? duration,
  }) {
    final toast = ToastNotification(
      message: message,
      type: type,
      duration: duration,
    );

    _notifications.insert(0, toast); // Add to top of stack
    notifyListeners();

    // Set up auto-dismiss timer
    _timers[toast.id] = Timer(toast.duration, () {
      dismissToast(toast.id);
    });
  }

  /// Dismiss a specific toast
  void dismissToast(String id) {
    final index = _notifications.indexWhere((toast) => toast.id == id);
    if (index != -1) {
      _notifications.removeAt(index);
      _timers[id]?.cancel();
      _timers.remove(id);
      notifyListeners();
    }
  }

  /// Clear all toasts
  void clearAll() {
    _notifications.clear();
    _timers.values.forEach((timer) => timer.cancel());
    _timers.clear();
    notifyListeners();
  }

  /// Convenience methods for different toast types
  void showSuccess(String message, [Duration? duration]) {
    showToast(message: message, type: ToastType.success, duration: duration);
  }

  void showError(String message, [Duration? duration]) {
    showToast(message: message, type: ToastType.error, duration: duration);
  }

  void showWarning(String message, [Duration? duration]) {
    showToast(message: message, type: ToastType.warning, duration: duration);
  }

  void showInfo(String message, [Duration? duration]) {
    showToast(message: message, type: ToastType.info, duration: duration);
  }

  @override
  void dispose() {
    clearAll();
    super.dispose();
  }
}
