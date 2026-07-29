import 'package:flutter/material.dart';

import '../core/theme/colors.dart';
import '../core/theme/radii.dart';
import '../core/theme/spacing.dart';

/// One selectable option.
@immutable
class FcDropdownItem<T> {
  const FcDropdownItem({required this.value, required this.label});

  final T value;
  final String label;
}

/// Themed select. Used for salary type, currency, industry and category.
class FcDropdown<T> extends StatelessWidget {
  const FcDropdown({
    super.key,
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  final String label;
  final T? value;
  final List<FcDropdownItem<T>> items;
  final ValueChanged<T?>? onChanged;

  @override
  Widget build(BuildContext context) {
    final OutlineInputBorder border = OutlineInputBorder(
      borderRadius: FcRadii.sm,
      borderSide: BorderSide(color: FcColors.gray.withValues(alpha: 0.3)),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(label, style: Theme.of(context).textTheme.labelMedium),
        const SizedBox(height: FcSpacing.xxs),
        DropdownButtonFormField<T>(
          initialValue: value,
          onChanged: onChanged,
          dropdownColor: FcColors.slate,
          borderRadius: FcRadii.sm,
          style: Theme.of(context).textTheme.bodyLarge,
          decoration: InputDecoration(
            filled: true,
            fillColor: FcColors.navy,
            border: border,
            enabledBorder: border,
            focusedBorder: border.copyWith(
              borderSide: const BorderSide(color: FcColors.green, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: FcSpacing.s,
              vertical: FcSpacing.xs + 4,
            ),
          ),
          items: <DropdownMenuItem<T>>[
            for (final FcDropdownItem<T> item in items)
              DropdownMenuItem<T>(
                value: item.value,
                child: Text(item.label),
              ),
          ],
        ),
      ],
    );
  }
}
