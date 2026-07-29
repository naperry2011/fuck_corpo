import 'package:flutter/material.dart';

import '../core/theme/colors.dart';
import '../core/theme/radii.dart';
import '../core/theme/shadows.dart';
import '../core/theme/spacing.dart';

/// Toast kinds from `src/context/ToastContext.jsx` and `Toast.jsx`.
enum FcToastType {
  success(Icons.check_circle_outline, FcColors.green),
  info(Icons.info_outline, FcColors.gray),
  achievement(Icons.emoji_events_outlined, FcColors.gold),
  warning(Icons.warning_amber_outlined, FcColors.red);

  const FcToastType(this.icon, this.accent);

  final IconData icon;
  final Color accent;
}

@immutable
class FcToastData {
  const FcToastData({
    required this.id,
    required this.message,
    this.type = FcToastType.info,
  });

  final String id;
  final String message;
  final FcToastType type;
}

/// A single toast card: accent icon, message, dismiss button.
class FcToast extends StatelessWidget {
  const FcToast({super.key, required this.data, required this.onDismiss});

  final FcToastData data;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 360),
      margin: const EdgeInsets.only(bottom: FcSpacing.xs),
      padding: const EdgeInsets.symmetric(
        horizontal: FcSpacing.s,
        vertical: FcSpacing.xs + 4,
      ),
      decoration: BoxDecoration(
        color: FcColors.slate,
        borderRadius: FcRadii.md,
        border: Border(left: BorderSide(color: data.type.accent, width: 4)),
        boxShadow: FcShadows.md,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(data.type.icon, size: 18, color: data.type.accent),
          const SizedBox(width: FcSpacing.xs),
          Flexible(
            child: Text(
              data.message,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          const SizedBox(width: FcSpacing.xs),
          IconButton(
            onPressed: onDismiss,
            icon: const Icon(Icons.close, size: 14),
            color: FcColors.gray,
            tooltip: 'Dismiss notification',
            visualDensity: VisualDensity.compact,
            constraints: const BoxConstraints(),
            padding: EdgeInsets.zero,
          ),
        ],
      ),
    );
  }
}
