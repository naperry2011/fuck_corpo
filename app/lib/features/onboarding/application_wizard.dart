import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/colors.dart';
import '../../core/theme/spacing.dart';
import '../../core/theme/typography.dart';
import '../../domain/models/app_state.dart';
import '../../domain/models/salary.dart';
import '../../state/app_controller.dart';
import '../../state/providers.dart';
import '../../state/toast_controller.dart';
import '../../widgets/fc_button.dart';
import '../../widgets/fc_card.dart';
import '../../widgets/fc_dropdown.dart';
import '../../widgets/fc_text_field.dart';
import '../../widgets/fc_toast.dart';
import '../settings/settings_screen.dart';

/// Onboarding offers five currencies; Settings adds JPY.
const List<String> fcOnboardingCurrencies = <String>[
  'USD',
  'EUR',
  'GBP',
  'CAD',
  'AUD',
];

const List<({String value, String label})> fcExperienceOptions =
    <({String value, String label})>[
      (value: '0-1', label: '0-1 (Novice)'),
      (value: '1-3', label: '1-3 (Intermediate)'),
      (value: '3-5', label: '3-5 (Seasoned)'),
      (value: '5-10', label: '5-10 (Expert)'),
      (value: '10+', label: '10+ (Veteran)'),
      (value: 'born-ready', label: 'I was born ready'),
    ];

const List<String> fcMotivations = <String>[
  'Financial gain',
  'Existential dread',
  'Coffee processing',
  'Doom scrolling',
  'Sticking it to the man',
  'All of the above',
];

const List<String> fcComposureOptions = <String>[
  'Yes',
  'Absolutely',
  'Without question',
  'I was born for this',
];

const List<String> fcStatusMessages = <String>[
  'Verifying bathroom credentials...',
  'Cross-referencing break history with HR...',
  'Calculating your earning potential...',
  'Checking references with your toilet...',
  'Reviewing your commitment to doing nothing...',
  'Assessing corporate time theft aptitude...',
  'Consulting the Board of Bowel Directors...',
  'Finalizing your compensation package...',
];

/// Port of `src/components/Application.jsx`: the five-step satirical job
/// application that ends by writing the salary, the profile and the onboarding
/// flag.
class ApplicationWizard extends ConsumerStatefulWidget {
  const ApplicationWizard({super.key});

  static const int stepCount = 5;

  /// React marked the salary field `required`, so the browser blocked the
  /// submit with no in-app copy. The rejection is surfaced here (D-106).
  static const String invalidSalaryMessage =
      'Enter a salary greater than zero to accept the offer.';

  /// Step 4 timings, matching the React intervals exactly.
  static const Duration backgroundCheckDuration = Duration(seconds: 4);
  static const Duration statusInterval = Duration(milliseconds: 700);
  static const Duration approvalPause = Duration(milliseconds: 1200);

  static const Key progressKey = Key('application_progress');
  static const Key oathKey = Key('application_oath');
  static const Key salaryKey = Key('application_salary');
  static const Key salaryTypeKey = Key('application_salary_type');
  static const Key currencyKey = Key('application_currency');
  static const Key industryKey = Key('application_industry');
  static const Key regionKey = Key('application_region');
  static const Key experienceKey = Key('application_experience');

  static Key starKey(int index) => ValueKey<String>('application_star_$index');
  static Key starIconKey(int index) =>
      ValueKey<String>('application_star_icon_$index');

  @override
  ConsumerState<ApplicationWizard> createState() => _ApplicationWizardState();
}

class _ApplicationWizardState extends ConsumerState<ApplicationWizard> {
  final TextEditingController _fullName = TextEditingController();
  final TextEditingController _pseudonym = TextEditingController();
  final TextEditingController _salary = TextEditingController();
  final TextEditingController _region = TextEditingController();

  int _step = 1;

  // Step 2
  int _starRating = 0;
  String _experience = '';

  // Step 3
  String _motivation = '';
  String _composure = '';
  bool _swearOath = false;

  // Step 4
  Timer? _progressTimer;
  Timer? _statusTimer;
  Timer? _advanceTimer;
  double _progress = 0;
  int _statusIndex = 0;
  bool _approved = false;

  // Step 5
  SalaryType _salaryType = SalaryType.annual;
  String _currency = 'USD';
  String _industry = 'Technology';

  @override
  void dispose() {
    _cancelBackgroundCheck();
    _fullName.dispose();
    _pseudonym.dispose();
    _salary.dispose();
    _region.dispose();
    super.dispose();
  }

  void _cancelBackgroundCheck() {
    _progressTimer?.cancel();
    _statusTimer?.cancel();
    _advanceTimer?.cancel();
    _progressTimer = null;
    _statusTimer = null;
    _advanceTimer = null;
  }

  void _goTo(int step) {
    _cancelBackgroundCheck();
    setState(() => _step = step);
    if (step == 4) _startBackgroundCheck();
  }

  void _startBackgroundCheck() {
    setState(() {
      _progress = 0;
      _statusIndex = 0;
      _approved = false;
    });

    const Duration tick = Duration(milliseconds: 50);
    final int total = ApplicationWizard.backgroundCheckDuration.inMilliseconds;
    int elapsed = 0;

    _progressTimer = Timer.periodic(tick, (Timer timer) {
      elapsed += tick.inMilliseconds;
      final double pct = (elapsed / total).clamp(0, 1).toDouble();
      if (!mounted) return;
      setState(() => _progress = pct);
      if (pct >= 1) {
        timer.cancel();
        _statusTimer?.cancel();
        setState(() => _approved = true);
        _advanceTimer = Timer(
          ApplicationWizard.approvalPause,
          () => _goTo(5),
        );
      }
    });

    _statusTimer = Timer.periodic(ApplicationWizard.statusInterval, (_) {
      if (!mounted) return;
      setState(
        () => _statusIndex = (_statusIndex + 1) % fcStatusMessages.length,
      );
    });
  }

  String get _experienceLabel {
    for (final ({String value, String label}) option in fcExperienceOptions) {
      if (option.value == _experience) return option.label;
    }
    return _experience;
  }

  void _handleAccept() {
    final double? amount = double.tryParse(_salary.text.trim());
    if (amount == null || amount <= 0) {
      ref
          .read(toastControllerProvider.notifier)
          .show(
            ApplicationWizard.invalidSalaryMessage,
            type: FcToastType.warning,
          );
      return;
    }

    final AppController controller = ref.read(appControllerProvider.notifier);
    final AppState state = ref.read(appControllerProvider);
    controller.setSalary(
      Salary(amount: amount, type: _salaryType, currency: _currency),
    );
    controller.updateSettings(
      state.settings.copyWith(
        currency: _currency,
        industry: _industry,
        region: _region.text.trim(),
      ),
    );
    controller.setOnboarded(onboarded: true);
  }

  @override
  Widget build(BuildContext context) {
    return FcCard(
      elevated: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(
            'STEP $_step OF ${ApplicationWizard.stepCount}',
            style: FcText.mono.copyWith(
              fontSize: 12,
              color: FcColors.gray,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: FcSpacing.xs),
          LinearProgressIndicator(
            key: ApplicationWizard.progressKey,
            value: _step / ApplicationWizard.stepCount,
            minHeight: 4,
            backgroundColor: FcColors.navy,
            valueColor: const AlwaysStoppedAnimation<Color>(FcColors.green),
          ),
          const SizedBox(height: FcSpacing.l),
          switch (_step) {
            1 => _buildCover(context),
            2 => _buildApplicantInfo(context),
            3 => _buildSkillsAssessment(context),
            4 => _buildBackgroundCheck(context),
            _ => _buildOffer(context),
          },
        ],
      ),
    );
  }

  Widget _buildBack(int target) => Align(
    alignment: Alignment.centerLeft,
    child: TextButton.icon(
      onPressed: () => _goTo(target),
      icon: const Icon(Icons.arrow_back, size: 16, color: FcColors.gray),
      label: const Text('Back', style: TextStyle(color: FcColors.gray)),
    ),
  );

  Widget _buildCover(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Center(
          child: Column(
            children: <Widget>[
              Text(
                'FUCKCORPO INC.',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontFamily: FcFonts.display,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: FcSpacing.xs),
              const SizedBox(
                width: 120,
                child: Divider(color: FcColors.gold, thickness: 1),
              ),
              Text(
                'EST. 2024 • BATHROOM REVENUE DIVISION',
                style: FcText.mono.copyWith(
                  fontSize: 11,
                  color: FcColors.gray,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: FcSpacing.l),
        Text(
          'APPLICATION FOR EMPLOYMENT',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: FcSpacing.m),
        const _DetailRow(
          label: 'Position:',
          value: 'Chief Bathroom Revenue Officer (CBRO)',
        ),
        const _DetailRow(
          label: 'Department:',
          value: 'Asset Liberation Division',
        ),
        const _DetailRow(
          label: 'Status:',
          value: 'Full-Time (Bathroom Hours)',
        ),
        const SizedBox(height: FcSpacing.l),
        Center(
          child: FcButton(
            label: 'BEGIN APPLICATION',
            size: FcButtonSize.lg,
            onPressed: () => _goTo(2),
          ),
        ),
        const SizedBox(height: FcSpacing.s),
        Text(
          'FuckCorpo Inc. is an equal opportunity employer of bathroom '
          'breaks. All toilet types welcome.',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }

  Widget _buildApplicantInfo(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        _buildBack(1),
        Text(
          'APPLICANT INFORMATION',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: FcSpacing.m),
        FcTextField(
          label: 'Full Name',
          controller: _fullName,
          hintText: 'e.g. John Q. Taxpayer',
        ),
        const SizedBox(height: FcSpacing.s),
        FcTextField(
          label: 'Preferred Bathroom Pseudonym',
          controller: _pseudonym,
          hintText: 'e.g. The Phantom Flusher',
        ),
        const SizedBox(height: FcSpacing.s),
        Text(
          'How would you rate your current bathroom break performance?',
          style: Theme.of(context).textTheme.labelMedium,
        ),
        const SizedBox(height: FcSpacing.xxs),
        Row(
          children: <Widget>[
            for (int i = 1; i <= 5; i++)
              IconButton(
                key: ApplicationWizard.starKey(i),
                onPressed: () => setState(() => _starRating = i),
                tooltip: '$i star${i > 1 ? 's' : ''}',
                icon: Icon(
                  _starRating >= i ? Icons.star : Icons.star_border,
                  key: ApplicationWizard.starIconKey(i),
                  size: 32,
                  color: _starRating >= i ? FcColors.gold : FcColors.gray,
                ),
              ),
          ],
        ),
        const SizedBox(height: FcSpacing.s),
        FcDropdown<String>(
          key: ApplicationWizard.experienceKey,
          label: 'Years of Professional Bathroom Experience',
          value: _experience,
          items: <FcDropdownItem<String>>[
            const FcDropdownItem<String>(
              value: '',
              label: 'Select your experience level',
            ),
            for (final ({String value, String label}) option
                in fcExperienceOptions)
              FcDropdownItem<String>(
                value: option.value,
                label: option.label,
              ),
          ],
          onChanged: (String? value) {
            if (value != null) setState(() => _experience = value);
          },
        ),
        const SizedBox(height: FcSpacing.l),
        Center(
          child: FcButton(
            label: 'CONTINUE',
            size: FcButtonSize.lg,
            onPressed: () => _goTo(3),
          ),
        ),
      ],
    );
  }

  Widget _buildSkillsAssessment(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        _buildBack(2),
        Text(
          'SKILLS ASSESSMENT',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: FcSpacing.m),
        Text(
          'What is your primary motivation for bathroom breaks?',
          style: Theme.of(context).textTheme.labelMedium,
        ),
        const SizedBox(height: FcSpacing.xxs),
        for (final String motivation in fcMotivations)
          _RadioOption(
            label: motivation,
            selected: _motivation == motivation,
            onTap: () => setState(() => _motivation = motivation),
          ),
        const SizedBox(height: FcSpacing.s),
        Text(
          'Can you maintain composure while earning money on the toilet?',
          style: Theme.of(context).textTheme.labelMedium,
        ),
        const SizedBox(height: FcSpacing.xxs),
        for (final String option in fcComposureOptions)
          _RadioOption(
            label: option,
            selected: _composure == option,
            onTap: () => setState(() => _composure = option),
          ),
        const SizedBox(height: FcSpacing.s),
        Text(
          'Do you solemnly swear to maximize your bathroom ROI?',
          style: Theme.of(context).textTheme.labelMedium,
        ),
        const SizedBox(height: FcSpacing.xxs),
        Row(
          children: <Widget>[
            Switch(
              key: ApplicationWizard.oathKey,
              value: _swearOath,
              onChanged: (bool value) => setState(() => _swearOath = value),
              activeThumbColor: FcColors.green,
              activeTrackColor: FcColors.green.withValues(alpha: 0.4),
            ),
            const SizedBox(width: FcSpacing.xs),
            Text(_swearOath ? 'I solemnly swear' : 'I do not yet swear'),
          ],
        ),
        const SizedBox(height: FcSpacing.l),
        Center(
          child: FcButton(
            label: 'SUBMIT FOR REVIEW',
            size: FcButtonSize.lg,
            onPressed: () => _goTo(4),
          ),
        ),
      ],
    );
  }

  Widget _buildBackgroundCheck(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(
          'BACKGROUND CHECK',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: FcSpacing.xs),
        Text(
          'Please wait while we process your application...',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: FcSpacing.m),
        LinearProgressIndicator(
          value: _progress,
          minHeight: 6,
          backgroundColor: FcColors.navy,
          valueColor: const AlwaysStoppedAnimation<Color>(FcColors.green),
        ),
        const SizedBox(height: FcSpacing.m),
        if (!_approved)
          Text(
            fcStatusMessages[_statusIndex],
            textAlign: TextAlign.center,
            style: FcText.mono.copyWith(fontSize: 13, color: FcColors.gray),
          )
        else
          Center(
            child: Column(
              children: <Widget>[
                const Icon(
                  Icons.check_circle_outline,
                  size: 40,
                  color: FcColors.green,
                ),
                const SizedBox(height: FcSpacing.xxs),
                Text(
                  'APPROVED',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: FcColors.green,
                    letterSpacing: 2,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildOffer(BuildContext context) {
    final String name = _fullName.text.trim().isEmpty
        ? 'Valued Applicant'
        : _fullName.text.trim();
    final String experience = _experienceLabel.isEmpty
        ? 'impressive'
        : _experienceLabel;
    final String motivation = _motivation.isEmpty
        ? 'unwavering'
        : _motivation;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        _buildBack(3),
        Text(
          'OFFER LETTER',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: FcSpacing.m),
        FcCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Text(
                'FUCKCORPO INC.',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontFamily: FcFonts.display,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                'Asset Liberation Division',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: FcSpacing.s),
              Text('Dear $name,'),
              const SizedBox(height: FcSpacing.xs),
              const Text(
                'We are pleased to extend this offer of employment for the '
                'position of Chief Bathroom Revenue Officer.',
              ),
              const SizedBox(height: FcSpacing.xs),
              Text(
                'Based on your $experience years of bathroom experience and '
                '$motivation assessment, we believe you will be an '
                'exceptional asset to our organization.',
              ),
              const SizedBox(height: FcSpacing.xs),
              const Text(
                'Please confirm your compensation details below to finalize '
                'your offer:',
              ),
            ],
          ),
        ),
        const SizedBox(height: FcSpacing.m),
        FcTextField(
          label: 'Salary / Wage',
          fieldKey: ApplicationWizard.salaryKey,
          controller: _salary,
          hintText: 'e.g. 75000',
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
        ),
        const SizedBox(height: FcSpacing.s),
        FcDropdown<SalaryType>(
          key: ApplicationWizard.salaryTypeKey,
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
        const SizedBox(height: FcSpacing.s),
        FcDropdown<String>(
          key: ApplicationWizard.currencyKey,
          label: 'Currency',
          value: _currency,
          items: <FcDropdownItem<String>>[
            for (final String code in fcOnboardingCurrencies)
              FcDropdownItem<String>(value: code, label: code),
          ],
          onChanged: (String? code) {
            if (code != null) setState(() => _currency = code);
          },
        ),
        const SizedBox(height: FcSpacing.s),
        FcDropdown<String>(
          key: ApplicationWizard.industryKey,
          label: 'Industry',
          value: _industry,
          items: <FcDropdownItem<String>>[
            for (final String industry in fcIndustries)
              FcDropdownItem<String>(value: industry, label: industry),
          ],
          onChanged: (String? industry) {
            if (industry != null) setState(() => _industry = industry);
          },
        ),
        const SizedBox(height: FcSpacing.s),
        FcTextField(
          label: 'State / Region (optional)',
          fieldKey: ApplicationWizard.regionKey,
          controller: _region,
          hintText: 'e.g. California',
        ),
        const SizedBox(height: FcSpacing.l),
        Center(
          child: FcButton(
            label: 'ACCEPT OFFER & BEGIN',
            size: FcButtonSize.lg,
            onPressed: _handleAccept,
          ),
        ),
        const SizedBox(height: FcSpacing.xs),
        Text(
          'By accepting, you agree to earn money while using the restroom.',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: FcSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}

class _RadioOption extends StatelessWidget {
  const _RadioOption({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: FcSpacing.xxs),
      child: Semantics(
        inMutuallyExclusiveGroup: true,
        selected: selected,
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            onTap: onTap,
            child: Container(
              constraints: const BoxConstraints(minHeight: 44),
              padding: const EdgeInsets.symmetric(
                horizontal: FcSpacing.s,
                vertical: FcSpacing.xs,
              ),
              decoration: BoxDecoration(
                color: FcColors.navy,
                border: Border.all(
                  color: selected
                      ? FcColors.green
                      : FcColors.gray.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: <Widget>[
                  Icon(
                    selected
                        ? Icons.radio_button_checked
                        : Icons.radio_button_unchecked,
                    size: 18,
                    color: selected ? FcColors.green : FcColors.gray,
                  ),
                  const SizedBox(width: FcSpacing.xs),
                  Expanded(child: Text(label)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
