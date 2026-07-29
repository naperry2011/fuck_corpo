import 'package:flutter/material.dart';

import '../core/theme/colors.dart';
import '../core/theme/shadows.dart';
import '../core/theme/typography.dart';

/// Port of `.btn-*` in `src/components/shared/Button.css`.
enum FcButtonVariant { primary, secondary, danger, ghost }

/// Port of `.btn-sm` / `.btn-md` / `.btn-lg`.
enum FcButtonSize { sm, md, lg }

@immutable
class _FcButtonSizeSpec {
  const _FcButtonSizeSpec(this.padding, this.fontSize);

  final EdgeInsets padding;
  final double fontSize;
}

const Map<FcButtonSize, _FcButtonSizeSpec> _sizeSpecs =
    <FcButtonSize, _FcButtonSizeSpec>{
      FcButtonSize.sm: _FcButtonSizeSpec(
        EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        14,
      ),
      FcButtonSize.md: _FcButtonSizeSpec(
        EdgeInsets.symmetric(horizontal: 28, vertical: 14),
        16,
      ),
      FcButtonSize.lg: _FcButtonSizeSpec(
        EdgeInsets.symmetric(horizontal: 36, vertical: 18),
        18,
      ),
    };

/// The brand button. Four variants, three sizes, disabled when [onPressed] is
/// null, exactly like the React component.
class FcButton extends StatelessWidget {
  const FcButton({
    super.key,
    required this.label,
    this.onPressed,
    this.variant = FcButtonVariant.primary,
    this.size = FcButtonSize.md,
    this.icon,
    this.expand = false,
  });

  /// Key on the decorated surface, so tests and callers can inspect the paint
  /// without depending on the internal widget nesting.
  static const Key surfaceKey = Key('fc_button_surface');

  static const BorderRadius borderRadius = BorderRadius.all(
    Radius.circular(6),
  );

  final String label;
  final VoidCallback? onPressed;
  final FcButtonVariant variant;
  final FcButtonSize size;
  final IconData? icon;

  /// Stretches the button to the width of its parent.
  final bool expand;

  bool get enabled => onPressed != null;

  Color get _foreground => switch (variant) {
    FcButtonVariant.primary => FcColors.ink,
    FcButtonVariant.secondary => FcColors.green,
    FcButtonVariant.danger => FcColors.ink,
    FcButtonVariant.ghost => FcColors.gray,
  };

  BoxDecoration get _decoration => switch (variant) {
    FcButtonVariant.primary => const BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: <Color>[FcColors.green, FcColors.greenDark],
      ),
      borderRadius: borderRadius,
      boxShadow: FcShadows.sm,
    ),
    FcButtonVariant.danger => const BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: <Color>[FcColors.red, Color(0xFFC5303C)],
      ),
      borderRadius: borderRadius,
      boxShadow: FcShadows.sm,
    ),
    FcButtonVariant.secondary => const BoxDecoration(
      color: Colors.transparent,
      border: Border.fromBorderSide(
        BorderSide(color: FcColors.green, width: 2),
      ),
      borderRadius: borderRadius,
    ),
    FcButtonVariant.ghost => BoxDecoration(
      color: Colors.transparent,
      border: Border.fromBorderSide(
        BorderSide(color: FcColors.gray.withValues(alpha: 0.3)),
      ),
      borderRadius: borderRadius,
    ),
  };

  @override
  Widget build(BuildContext context) {
    final _FcButtonSizeSpec spec = _sizeSpecs[size]!;
    final TextStyle textStyle = TextStyle(
      fontFamily: FcFonts.body,
      fontWeight: FontWeight.w600,
      fontSize: spec.fontSize,
      color: _foreground,
    );

    return Semantics(
      button: true,
      enabled: enabled,
      label: label,
      child: Opacity(
        opacity: enabled ? 1 : 0.5,
        child: DecoratedBox(
          key: surfaceKey,
          decoration: _decoration,
          child: Material(
            type: MaterialType.transparency,
            child: InkWell(
              onTap: onPressed,
              borderRadius: borderRadius,
              child: Padding(
                padding: spec.padding,
                child: Row(
                  mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    if (icon != null) ...<Widget>[
                      Icon(icon, size: spec.fontSize + 4, color: _foreground),
                      const SizedBox(width: 8),
                    ],
                    Text(label, style: textStyle),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
