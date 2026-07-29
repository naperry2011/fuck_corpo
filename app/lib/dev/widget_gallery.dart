import 'package:flutter/material.dart';

import '../core/theme/spacing.dart';
import '../widgets/animated_currency.dart';
import '../widgets/fc_button.dart';
import '../widgets/fc_card.dart';
import '../widgets/fc_dropdown.dart';
import '../widgets/fc_switch.dart';
import '../widgets/fc_text_field.dart';
import '../widgets/fc_toast.dart';
import '../widgets/fc_toast_host.dart';

/// Developer-only gallery of the P2 design system widgets. Not routed and not
/// reachable from the app; mount it from a scratch entry point when checking a
/// visual change by hand.
class WidgetGallery extends StatefulWidget {
  const WidgetGallery({super.key});

  @override
  State<WidgetGallery> createState() => _WidgetGalleryState();
}

class _WidgetGalleryState extends State<WidgetGallery> {
  bool _soundEnabled = true;
  String _currency = 'USD';
  final List<FcToastData> _toasts = <FcToastData>[];

  void _push(FcToastType type) {
    setState(() {
      _toasts.add(
        FcToastData(
          id: '${_toasts.length}',
          message: '${type.name} toast',
          type: type,
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return FcToastHost(
      toasts: _toasts,
      onDismiss: (String id) => setState(
        () => _toasts.removeWhere((FcToastData t) => t.id == id),
      ),
      child: Scaffold(
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(FcSpacing.m),
            children: <Widget>[
              const _Section('Buttons'),
              Wrap(
                spacing: FcSpacing.xs,
                runSpacing: FcSpacing.xs,
                children: <Widget>[
                  for (final FcButtonVariant variant in FcButtonVariant.values)
                    FcButton(
                      label: variant.name.toUpperCase(),
                      variant: variant,
                      onPressed: () => _push(FcToastType.info),
                    ),
                  const FcButton(label: 'DISABLED'),
                  FcButton(
                    label: 'SMALL',
                    size: FcButtonSize.sm,
                    onPressed: () {},
                  ),
                  FcButton(
                    label: 'LARGE',
                    size: FcButtonSize.lg,
                    onPressed: () {},
                  ),
                ],
              ),
              const _Section('Cards'),
              const FcCard(child: Text('Standard card')),
              const SizedBox(height: FcSpacing.xs),
              const FcCard(elevated: true, child: Text('Elevated card')),
              const _Section('Animated currency'),
              AnimatedCurrency(
                value: 1234.56,
                currency: _currency,
                style: Theme.of(context).textTheme.displaySmall,
              ),
              const _Section('Inputs'),
              const FcTextField(label: 'ANNUAL SALARY', prefixText: r'$'),
              const SizedBox(height: FcSpacing.s),
              FcDropdown<String>(
                label: 'CURRENCY',
                value: _currency,
                items: const <FcDropdownItem<String>>[
                  FcDropdownItem<String>(value: 'USD', label: 'USD'),
                  FcDropdownItem<String>(value: 'EUR', label: 'EUR'),
                  FcDropdownItem<String>(value: 'JPY', label: 'JPY'),
                ],
                onChanged: (String? v) =>
                    setState(() => _currency = v ?? 'USD'),
              ),
              const SizedBox(height: FcSpacing.s),
              FcSwitch(
                label: 'Sound Effects',
                value: _soundEnabled,
                onChanged: (bool v) => setState(() => _soundEnabled = v),
              ),
              const _Section('Toasts'),
              Wrap(
                spacing: FcSpacing.xs,
                children: <Widget>[
                  for (final FcToastType type in FcToastType.values)
                    FcButton(
                      label: type.name.toUpperCase(),
                      size: FcButtonSize.sm,
                      variant: FcButtonVariant.ghost,
                      onPressed: () => _push(type),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
        top: FcSpacing.l,
        bottom: FcSpacing.s,
      ),
      child: Text(title, style: Theme.of(context).textTheme.headlineSmall),
    );
  }
}
