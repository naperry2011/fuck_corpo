import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/format/currency_formatter.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/spacing.dart';
import '../../core/theme/typography.dart';
import '../../domain/calculations.dart';
import '../../domain/models/app_settings.dart';
import '../../domain/models/app_state.dart';
import '../../domain/models/salary.dart';
import '../../state/migration_notice_controller.dart';
import '../../state/providers.dart';
import '../../state/toast_controller.dart';
import '../../widgets/fc_button.dart';
import '../../widgets/fc_card.dart';
import '../../widgets/fc_dropdown.dart';
import '../../widgets/fc_switch.dart';
import '../../widgets/fc_text_field.dart';
import '../../widgets/fc_toast.dart';

/// The currency codes `Settings.jsx` offers. Onboarding offers the first five.
const List<String> fcCurrencies = <String>[
  'USD',
  'EUR',
  'GBP',
  'CAD',
  'AUD',
  'JPY',
];

/// The industries `Settings.jsx` and `Application.jsx` share.
const List<String> fcIndustries = <String>[
  'Technology',
  'Healthcare',
  'Retail',
  'Finance',
  'Education',
  'Manufacturing',
  'Food Service',
  'Government',
  'Other',
];

/// Display label for a salary type, matching the React `SALARY_TYPES` strings.
String salaryTypeLabel(SalaryType type) => switch (type) {
  SalaryType.annual => 'Annual',
  SalaryType.hourly => 'Hourly',
  SalaryType.monthly => 'Monthly',
  SalaryType.weekly => 'Weekly',
};

/// Port of `src/pages/Settings.jsx`: compensation, profile, display
/// preferences, data management, about, know your rights.
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  /// React silently ignored a zero or empty salary. Here the rejection is
  /// surfaced (deviation D-106).
  static const String invalidSalaryMessage =
      'Enter a salary greater than zero.';

  /// React's copy for a file that could not be parsed.
  static const String importErrorMessage = 'Invalid file format.';
  static const String importConfirmLabel = 'Import';

  static const Key salaryAmountKey = Key('settings_salary_amount');
  static const Key salaryTypeKey = Key('settings_salary_type');
  static const Key ratePreviewKey = Key('settings_rate_preview');
  static const Key currencyKey = Key('settings_currency');
  static const Key industryKey = Key('settings_industry');
  static const Key regionKey = Key('settings_region');
  static const Key themeToggleKey = Key('settings_theme_toggle');
  static const Key soundToggleKey = Key('settings_sound_toggle');
  static const Key importFieldKey = Key('settings_import_field');
  static const Key importErrorKey = Key('settings_import_error');
  static const Key syncNoticeKey = Key('settings_sync_notice');
  static const Key migrationNoticeKey = Key('settings_migration_notice');
  static const Key migrationDismissKey = Key('settings_migration_dismiss');

  /// D-104: the web build and the installed app keep separate stores, and
  /// nothing reconciles them. Stated plainly rather than left to be discovered.
  static const String syncNoticeText =
      'Your data is stored on this device only. The website and the app each '
      'keep their own copy, and browsers keep a separate copy per profile. '
      'Nothing syncs between them, and clearing your browser data erases the '
      'web copy. To move your numbers, use Export Data here and Import Data '
      'there.';

  /// N3: a failed one-time React import would otherwise present as an empty
  /// app with no explanation.
  static const String migrationNoticeText =
      'We found data from the earlier version of FuckCorpo but could not read '
      'it, so this app started fresh. Nothing was deleted: the original is '
      'still in this browser under the key "fuckcorpo_data_backup". Recover it '
      'from your browser devtools before clearing site data.';

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  late final TextEditingController _salaryAmount;
  late final TextEditingController _region;

  late SalaryType _salaryType;
  late String _currency;
  late String _industry;
  bool _confirmClear = false;

  @override
  void initState() {
    super.initState();
    final AppState state = ref.read(appControllerProvider);
    _salaryAmount = TextEditingController(
      text: state.salary.amount > 0 ? _plain(state.salary.amount) : '',
    );
    _salaryType = state.salary.type;
    _region = TextEditingController(text: state.settings.region);
    _currency = state.settings.currency;
    _industry = state.settings.industry;
  }

  @override
  void dispose() {
    _salaryAmount.dispose();
    _region.dispose();
    super.dispose();
  }

  /// Whole amounts render without a trailing `.0` in the input, as they did in
  /// the React number field.
  static String _plain(double amount) =>
      amount == amount.roundToDouble() ? amount.toStringAsFixed(0) : '$amount';

  void _toast(String message, FcToastType type) =>
      ref.read(toastControllerProvider.notifier).show(message, type: type);

  double get _previewRate {
    final double? amount = double.tryParse(_salaryAmount.text.trim());
    if (amount == null || amount <= 0) return 0;
    return salaryToPerMinute(amount, _salaryType);
  }

  void _handleSalaryUpdate() {
    final double? amount = double.tryParse(_salaryAmount.text.trim());
    if (amount == null || amount <= 0) {
      _toast(SettingsScreen.invalidSalaryMessage, FcToastType.warning);
      return;
    }
    final AppState state = ref.read(appControllerProvider);
    ref
        .read(appControllerProvider.notifier)
        .setSalary(
          state.salary.copyWith(amount: amount, type: _salaryType),
        );
    _toast('Salary updated', FcToastType.success);
  }

  void _handleProfileSave() {
    final AppSettings settings = ref.read(appControllerProvider).settings;
    ref
        .read(appControllerProvider.notifier)
        .updateSettings(
          settings.copyWith(
            currency: _currency,
            industry: _industry,
            region: _region.text.trim(),
          ),
        );
    _toast('Profile saved', FcToastType.success);
  }

  void _handleThemeToggle(bool light) {
    final AppSettings settings = ref.read(appControllerProvider).settings;
    ref
        .read(appControllerProvider.notifier)
        .updateSettings(settings.copyWith(theme: light ? 'light' : 'dark'));
  }

  void _handleSoundToggle(bool enabled) {
    final AppSettings settings = ref.read(appControllerProvider).settings;
    ref
        .read(appControllerProvider.notifier)
        .updateSettings(settings.copyWith(soundEnabled: enabled));
  }

  Future<void> _handleExport() async {
    final AppState state = ref.read(appControllerProvider);
    final String payload = ref.read(appRepositoryProvider).exportJson(state);
    await Clipboard.setData(ClipboardData(text: payload));
    if (!mounted) return;
    _toast('Data exported', FcToastType.success);
  }

  Future<void> _handleImport() async {
    final TextEditingController payload = TextEditingController();
    final AppState? imported = await showDialog<AppState>(
      context: context,
      builder: (BuildContext context) {
        String? error;
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setDialogState) {
            return AlertDialog(
              backgroundColor: FcColors.slate,
              title: const Text('Import Data'),
              content: SizedBox(
                width: 420,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    Text(
                      'Paste the contents of an exported file.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: FcSpacing.xs),
                    TextField(
                      key: SettingsScreen.importFieldKey,
                      controller: payload,
                      maxLines: 4,
                      style: FcText.mono.copyWith(fontSize: 13),
                    ),
                    if (error != null) ...<Widget>[
                      const SizedBox(height: FcSpacing.xs),
                      Text(
                        error!,
                        key: SettingsScreen.importErrorKey,
                        style: const TextStyle(color: FcColors.red),
                      ),
                    ],
                  ],
                ),
              ),
              actions: <Widget>[
                FcButton(
                  label: 'Cancel',
                  variant: FcButtonVariant.ghost,
                  size: FcButtonSize.sm,
                  onPressed: () => Navigator.of(context).pop(),
                ),
                FcButton(
                  label: SettingsScreen.importConfirmLabel,
                  size: FcButtonSize.sm,
                  onPressed: () {
                    try {
                      final AppState next = ref
                          .read(appRepositoryProvider)
                          .importJson(payload.text);
                      Navigator.of(context).pop(next);
                    } on FormatException {
                      // The existing state is left untouched (BUG-004).
                      setDialogState(
                        () => error = SettingsScreen.importErrorMessage,
                      );
                    }
                  },
                ),
              ],
            );
          },
        );
      },
    );
    // Do not dispose synchronously here: the dialog route can still rebuild
    // during its pop animation and TextField may briefly read the controller.

    if (imported == null || !mounted) return;
    ref.read(appControllerProvider.notifier).replaceState(imported);
    setState(() {
      _salaryAmount.text = imported.salary.amount > 0
          ? _plain(imported.salary.amount)
          : '';
      _salaryType = imported.salary.type;
      _currency = imported.settings.currency;
      _industry = imported.settings.industry;
      _region.text = imported.settings.region;
    });
    _toast('Data imported successfully', FcToastType.success);
  }

  void _handleClear() {
    if (!_confirmClear) {
      setState(() => _confirmClear = true);
      return;
    }
    // No page reload, unlike React (BUG-006).
    ref.read(appControllerProvider.notifier).reset();
    setState(() {
      _confirmClear = false;
      _salaryAmount.clear();
      _salaryType = SalaryType.annual;
      _currency = AppSettings.initial.currency;
      _industry = AppSettings.initial.industry;
      _region.clear();
    });
    _toast('All data cleared', FcToastType.info);
  }

  @override
  Widget build(BuildContext context) {
    final AppSettings settings = ref.watch(
      appControllerProvider.select((AppState s) => s.settings),
    );
    final double rate = _previewRate;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(
          'ACCOUNT SETTINGS',
          style: Theme.of(context).textTheme.displaySmall,
        ),
        const SizedBox(height: FcSpacing.xxs),
        Text(
          'Manage your portfolio',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: FcColors.gray,
          ),
        ),
        const SizedBox(height: FcSpacing.l),

        if (ref.watch(migrationNoticeProvider))
          _SettingsCard(
            key: SettingsScreen.migrationNoticeKey,
            header: 'Import Notice',
            headerColor: FcColors.red,
            children: <Widget>[
              const Text(SettingsScreen.migrationNoticeText),
              const SizedBox(height: FcSpacing.s),
              Align(
                alignment: Alignment.centerLeft,
                child: FcButton(
                  key: SettingsScreen.migrationDismissKey,
                  label: 'Dismiss',
                  variant: FcButtonVariant.ghost,
                  size: FcButtonSize.sm,
                  onPressed: () =>
                      ref.read(migrationNoticeProvider.notifier).dismiss(),
                ),
              ),
            ],
          ),

        _SettingsCard(
          header: 'Compensation Package',
          children: <Widget>[
            FcTextField(
              label: 'Salary / Wage',
              fieldKey: SettingsScreen.salaryAmountKey,
              controller: _salaryAmount,
              hintText: 'e.g. 75000',
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              onChanged: (_) => setState(() {}),
              onSubmitted: (_) => _handleSalaryUpdate(),
            ),
            const SizedBox(height: FcSpacing.s),
            FcDropdown<SalaryType>(
              key: SettingsScreen.salaryTypeKey,
              label: 'Salary type',
              value: _salaryType,
              items: <FcDropdownItem<SalaryType>>[
                for (final SalaryType type in SalaryType.values)
                  FcDropdownItem<SalaryType>(
                    value: type,
                    label: salaryTypeLabel(type),
                  ),
              ],
              onChanged: (SalaryType? type) {
                if (type != null) setState(() => _salaryType = type);
              },
            ),
            if (rate > 0) ...<Widget>[
              const SizedBox(height: FcSpacing.s),
              Text(
                'Per-minute rate: '
                '${formatCurrency(rate, currency: settings.currency)}/min',
                key: SettingsScreen.ratePreviewKey,
                style: FcText.mono.copyWith(
                  fontSize: 14,
                  color: FcColors.green,
                ),
              ),
            ],
            const SizedBox(height: FcSpacing.s),
            Align(
              alignment: Alignment.centerLeft,
              child: FcButton(
                label: 'Update Salary',
                onPressed: _handleSalaryUpdate,
              ),
            ),
          ],
        ),

        _SettingsCard(
          header: 'Employee Profile',
          children: <Widget>[
            FcDropdown<String>(
              key: SettingsScreen.currencyKey,
              label: 'Currency',
              value: _currency,
              items: <FcDropdownItem<String>>[
                for (final String code in fcCurrencies)
                  FcDropdownItem<String>(value: code, label: code),
              ],
              onChanged: (String? code) {
                if (code != null) setState(() => _currency = code);
              },
            ),
            const SizedBox(height: FcSpacing.s),
            FcDropdown<String>(
              key: SettingsScreen.industryKey,
              label: 'Industry',
              value: _industry,
              items: <FcDropdownItem<String>>[
                const FcDropdownItem<String>(
                  value: '',
                  label: 'Select Industry',
                ),
                for (final String industry in fcIndustries)
                  FcDropdownItem<String>(value: industry, label: industry),
              ],
              onChanged: (String? industry) {
                if (industry != null) setState(() => _industry = industry);
              },
            ),
            const SizedBox(height: FcSpacing.s),
            FcTextField(
              label: 'State / Region',
              fieldKey: SettingsScreen.regionKey,
              controller: _region,
              hintText: 'e.g. California',
            ),
            const SizedBox(height: FcSpacing.s),
            Align(
              alignment: Alignment.centerLeft,
              child: FcButton(
                label: 'Save Profile',
                onPressed: _handleProfileSave,
              ),
            ),
          ],
        ),

        _SettingsCard(
          header: 'Display Preferences',
          children: <Widget>[
            FcSwitch(
              key: SettingsScreen.themeToggleKey,
              label: 'Theme',
              description: settings.theme == 'light'
                  ? 'Light Mode'
                  : 'Dark Mode',
              value: settings.theme == 'light',
              onChanged: _handleThemeToggle,
            ),
            const SizedBox(height: FcSpacing.s),
            FcSwitch(
              key: SettingsScreen.soundToggleKey,
              label: 'Sound Effects',
              description: settings.soundEnabled ? 'On' : 'Off',
              value: settings.soundEnabled,
              onChanged: _handleSoundToggle,
            ),
          ],
        ),

        _SettingsCard(
          header: 'Data Management',
          children: <Widget>[
            Text(
              SettingsScreen.syncNoticeText,
              key: SettingsScreen.syncNoticeKey,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: FcColors.gold,
              ),
            ),
            const SizedBox(height: FcSpacing.s),
            _DataActionRow(
              title: 'Export Data',
              description: 'Download your portfolio as a JSON file',
              // Until the platform file pickers land in P6, export and import
              // move the same payload through the clipboard (D-105).
              note: 'For now the JSON is copied to your clipboard.',
              action: FcButton(
                label: 'Export Data',
                variant: FcButtonVariant.secondary,
                size: FcButtonSize.sm,
                onPressed: _handleExport,
              ),
            ),
            const SizedBox(height: FcSpacing.s),
            _DataActionRow(
              title: 'Import Data',
              description: 'Restore from a previously exported file',
              note: 'Paste the contents of an exported file.',
              action: FcButton(
                label: 'Import Data',
                variant: FcButtonVariant.secondary,
                size: FcButtonSize.sm,
                onPressed: _handleImport,
              ),
            ),
            const SizedBox(height: FcSpacing.s),
            _DataActionRow(
              title: 'Clear All Data',
              description:
                  'Permanently delete all breaks, settings, and achievements',
              action: _confirmClear
                  ? Wrap(
                      spacing: FcSpacing.xs,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: <Widget>[
                        const Text(
                          'Are you sure?',
                          style: TextStyle(color: FcColors.red),
                        ),
                        FcButton(
                          label: 'Confirm',
                          variant: FcButtonVariant.danger,
                          size: FcButtonSize.sm,
                          onPressed: _handleClear,
                        ),
                        FcButton(
                          label: 'Cancel',
                          variant: FcButtonVariant.ghost,
                          size: FcButtonSize.sm,
                          onPressed: () =>
                              setState(() => _confirmClear = false),
                        ),
                      ],
                    )
                  : FcButton(
                      label: 'Clear All Data',
                      variant: FcButtonVariant.danger,
                      size: FcButtonSize.sm,
                      onPressed: _handleClear,
                    ),
            ),
          ],
        ),

        _SettingsCard(
          header: 'Corporate Information',
          children: <Widget>[
            Text.rich(
              TextSpan(
                children: <TextSpan>[
                  const TextSpan(text: 'Fuck'),
                  const TextSpan(
                    text: 'Corpo',
                    style: TextStyle(color: FcColors.green),
                  ),
                ],
                style: Theme.of(context).textTheme.headlineSmall,
              ),
            ),
            const SizedBox(height: FcSpacing.xxs),
            Text(
              'v1.0.0',
              style: FcText.mono.copyWith(fontSize: 13, color: FcColors.gray),
            ),
            const SizedBox(height: FcSpacing.xs),
            const Text('Your time is valuable, even in the bathroom.'),
            const SizedBox(height: FcSpacing.s),
            const _AboutRow(label: 'Board of Directors:', value: 'You'),
            const _AboutRow(label: 'Chief Bathroom Officer:', value: 'You'),
            const _AboutRow(
              label: 'Shareholder Value:',
              value: 'Maximized',
              highlight: true,
            ),
          ],
        ),

        _SettingsCard(
          header: 'Know Your Rights',
          headerColor: FcColors.gold,
          children: <Widget>[
            const Text(
              'Under OSHA regulations, employers must provide workers with '
              'toilet facilities and allow them to use them. Restricting '
              "bathroom access is a violation of workers' rights.",
            ),
            const SizedBox(height: FcSpacing.xs),
            Text(
              'This is not legal advice. Know your local labor laws.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ],
    );
  }
}

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({
    required this.header,
    required this.children,
    this.headerColor,
    super.key,
  });

  final String header;
  final List<Widget> children;
  final Color? headerColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: FcSpacing.m),
      child: FcCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(
              header,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: headerColor ?? FcColors.gray,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: FcSpacing.s),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _DataActionRow extends StatelessWidget {
  const _DataActionRow({
    required this.title,
    required this.description,
    required this.action,
    this.note,
  });

  final String title;
  final String description;
  final Widget action;
  final String? note;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(title, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 2),
              Text(
                description,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              if (note != null)
                Text(note!, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
        const SizedBox(width: FcSpacing.s),
        action,
      ],
    );
  }
}

class _AboutRow extends StatelessWidget {
  const _AboutRow({
    required this.label,
    required this.value,
    this.highlight = false,
  });

  final String label;
  final String value;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Text.rich(
        TextSpan(
          children: <TextSpan>[
            TextSpan(
              text: '$label ',
              style: const TextStyle(color: FcColors.gray),
            ),
            TextSpan(
              text: value,
              style: highlight
                  ? const TextStyle(color: FcColors.green)
                  : null,
            ),
          ],
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ),
    );
  }
}
