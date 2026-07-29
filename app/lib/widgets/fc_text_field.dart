import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/theme/colors.dart';
import '../core/theme/radii.dart';
import '../core/theme/spacing.dart';
import '../core/theme/typography.dart';

/// Themed text input. The label sits above the field, as it does in the React
/// forms, rather than floating inside it.
class FcTextField extends StatelessWidget {
  const FcTextField({
    super.key,
    required this.label,
    this.fieldKey,
    this.controller,
    this.initialValue,
    this.hintText,
    this.errorText,
    this.prefixText,
    this.keyboardType,
    this.inputFormatters,
    this.onChanged,
    this.onSubmitted,
    this.enabled = true,
  });

  final String label;

  /// Key on the inner [TextField], for callers that need to address the input
  /// itself rather than this wrapper.
  final Key? fieldKey;
  final TextEditingController? controller;
  final String? initialValue;
  final String? hintText;
  final String? errorText;
  final String? prefixText;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final bool enabled;

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
        Text(
          label,
          style: Theme.of(context).textTheme.labelMedium,
        ),
        const SizedBox(height: FcSpacing.xxs),
        TextField(
          key: fieldKey,
          controller: controller ??
              (initialValue == null
                  ? null
                  : TextEditingController(text: initialValue)),
          enabled: enabled,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          onChanged: onChanged,
          onSubmitted: onSubmitted,
          style: const TextStyle(
            fontFamily: FcFonts.mono,
            fontSize: 16,
            color: FcColors.ink,
          ),
          decoration: InputDecoration(
            hintText: hintText,
            errorText: errorText,
            // A prefix icon rather than `prefixText`, which Flutter hides
            // until the field is focused.
            prefixIcon: prefixText == null
                ? null
                : Padding(
                    padding: const EdgeInsets.only(
                      left: FcSpacing.s,
                      right: FcSpacing.xs,
                    ),
                    child: Text(
                      prefixText!,
                      style: const TextStyle(
                        fontFamily: FcFonts.mono,
                        fontSize: 16,
                        color: FcColors.gray,
                      ),
                    ),
                  ),
            prefixIconConstraints: const BoxConstraints(),
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
        ),
      ],
    );
  }
}
