import 'package:flutter/material.dart';

import '../../../core/theme/colors.dart';
import '../../../core/theme/radii.dart';
import '../../../core/theme/spacing.dart';
import '../../../core/theme/typography.dart';
import '../../../domain/models/break_category.dart';

/// Port of `.timer-category-selector` in `src/pages/Timer.css`. The whole row
/// goes inert while a break is running, exactly as the React `disabled`
/// attribute did.
class CategoryChipRow extends StatelessWidget {
  const CategoryChipRow({
    super.key,
    required this.selected,
    required this.onSelect,
    required this.enabled,
    required this.chipKeyFor,
  });

  final BreakCategory selected;
  final ValueChanged<BreakCategory> onSelect;
  final bool enabled;
  final Key Function(BreakCategory) chipKeyFor;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: FcSpacing.xs,
      runSpacing: FcSpacing.xs,
      children: <Widget>[
        for (final BreakCategory category in BreakCategory.values)
          _CategoryChip(
            key: chipKeyFor(category),
            category: category,
            active: category == selected,
            enabled: enabled,
            onTap: () => onSelect(category),
          ),
      ],
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    super.key,
    required this.category,
    required this.active,
    required this.enabled,
    required this.onTap,
  });

  final BreakCategory category;
  final bool active;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Color border = active
        ? FcColors.green
        : FcColors.gray.withValues(alpha: 0.3);

    return Semantics(
      button: true,
      enabled: enabled,
      selected: active,
      label: category.label,
      child: Opacity(
        opacity: enabled ? 1 : 0.5,
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            onTap: enabled ? onTap : null,
            borderRadius: FcRadii.md,
            child: Container(
              constraints: const BoxConstraints(minHeight: 44),
              padding: const EdgeInsets.symmetric(
                horizontal: FcSpacing.s,
                vertical: FcSpacing.xs,
              ),
              decoration: BoxDecoration(
                color: active
                    ? FcColors.green.withValues(alpha: 0.12)
                    : FcColors.slate,
                border: Border.all(color: border),
                borderRadius: FcRadii.md,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(category.emoji, style: const TextStyle(fontSize: 16)),
                  const SizedBox(width: FcSpacing.xxs),
                  Text(
                    category.label,
                    style: TextStyle(
                      fontFamily: FcFonts.body,
                      fontSize: 13,
                      fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                      color: active ? FcColors.green : FcColors.gray,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
