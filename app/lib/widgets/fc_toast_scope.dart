import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../state/toast_controller.dart';
import 'fc_toast_host.dart';

/// Binds the toast queue to the overlay. Wraps the whole app, the way
/// `ToastProvider` wrapped the React tree.
class FcToastScope extends ConsumerWidget {
  const FcToastScope({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FcToastHost(
      toasts: ref.watch(toastControllerProvider),
      onDismiss: ref.read(toastControllerProvider.notifier).dismiss,
      child: child,
    );
  }
}
