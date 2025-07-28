import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/toast_manager.dart';
import '../widgets/toast_widget.dart';

/// Overlay widget for displaying toast notifications
class ToastOverlay extends StatelessWidget {
  final Widget child;

  const ToastOverlay({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        Positioned(
          top: 16,
          right: 16,
          child: ChangeNotifierProvider.value(
            value: ToastManager.instance,
            child: Consumer<ToastManager>(
              builder: (context, toastManager, _) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: toastManager.notifications
                      .map(
                        (notification) => ToastWidget(
                          key: ValueKey(notification.id),
                          notification: notification,
                          onDismiss: () =>
                              toastManager.dismissToast(notification.id),
                        ),
                      )
                      .toList(),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}
