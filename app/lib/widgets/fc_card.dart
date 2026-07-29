import 'package:flutter/material.dart';

import '../core/theme/colors.dart';
import '../core/theme/radii.dart';
import '../core/theme/shadows.dart';
import '../core/theme/spacing.dart';

/// Port of `.card` / `.card-elevated` in `src/components/shared/Card.css`.
class FcCard extends StatelessWidget {
  const FcCard({
    super.key,
    required this.child,
    this.elevated = false,
    this.padding = const EdgeInsets.all(FcSpacing.m),
    this.onTap,
  });

  static const Key surfaceKey = Key('fc_card_surface');

  final Widget child;

  /// The gold-bordered gradient treatment used for featured figures.
  final bool elevated;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final BoxDecoration decoration = elevated
        ? BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: <Color>[FcColors.slate, FcColors.navy],
            ),
            border: Border.all(color: FcColors.gold.withValues(alpha: 0.2)),
            borderRadius: FcRadii.md,
            boxShadow: FcShadows.lg,
          )
        : BoxDecoration(
            color: FcColors.slate,
            border: Border.all(color: FcColors.gray.withValues(alpha: 0.2)),
            borderRadius: FcRadii.md,
            boxShadow: FcShadows.sm,
          );

    Widget content = Padding(padding: padding, child: child);
    if (onTap != null) {
      content = Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onTap,
          borderRadius: FcRadii.md,
          child: content,
        ),
      );
    }

    return DecoratedBox(
      key: surfaceKey,
      decoration: decoration,
      child: content,
    );
  }
}
