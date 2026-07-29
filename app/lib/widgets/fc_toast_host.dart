import 'package:flutter/material.dart';

import '../core/theme/spacing.dart';
import 'fc_toast.dart';

/// Stacks the queued toasts over the app, top-right, like `.toast-container`.
/// The queue itself lives in state, so this stays a pure render.
class FcToastHost extends StatelessWidget {
  const FcToastHost({
    super.key,
    required this.toasts,
    required this.child,
    this.onDismiss,
  });

  final List<FcToastData> toasts;
  final Widget child;
  final ValueChanged<String>? onDismiss;

  @override
  Widget build(BuildContext context) {
    // Expanded rather than shrink-wrapped: the overlay is positioned against
    // the full viewport, and a shrink-wrapped Stack would place the toasts
    // outside its own bounds, where they stop receiving taps.
    return Stack(
      fit: StackFit.expand,
      children: <Widget>[
        child,
        if (toasts.isNotEmpty)
          Positioned(
            top: FcSpacing.s,
            right: FcSpacing.s,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                for (final FcToastData toast in toasts)
                  FcToast(
                    key: ValueKey<String>(toast.id),
                    data: toast,
                    onDismiss: () => onDismiss?.call(toast.id),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}
