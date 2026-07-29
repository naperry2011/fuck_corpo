import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fuckcorpo/data/app_repository.dart';
import 'package:fuckcorpo/core/theme/fc_theme.dart';
import 'package:fuckcorpo/domain/models/app_state.dart';
import 'package:fuckcorpo/domain/models/salary.dart';
import 'package:fuckcorpo/features/onboarding/application_wizard.dart';
import 'package:fuckcorpo/features/onboarding/landing_screen.dart';

import '../../helpers/fake_clock.dart';
import '../../helpers/memory_store.dart';
import '../../helpers/pump_app.dart';

final DateTime _now = DateTime(2026, 7, 28, 10);

AppState? _persisted(MemoryStore store) {
  final String? raw = store.data[AppRepository.storageKey];
  return raw == null ? null : AppState.fromJson(jsonDecode(raw));
}

Future<void> _selectOption(
  WidgetTester tester,
  Key dropdownKey,
  String label,
) async {
  await tester.tap(find.byKey(dropdownKey));
  await tester.pumpAndSettle();
  await tester.tap(find.text(label).last);
  await tester.pumpAndSettle();
}

/// Walks steps 1 to 4 and lands on the offer letter.
Future<void> _advanceToOffer(WidgetTester tester) async {
  await tester.tap(find.text('BEGIN APPLICATION'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('CONTINUE'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('SUBMIT FOR REVIEW'));
  await tester.pump();
  // 4s progress, then a 1.2s pause on the APPROVED stamp.
  await tester.pump(const Duration(seconds: 4));
  await tester.pump(const Duration(milliseconds: 1200));
  await tester.pumpAndSettle();
}

void main() {
  late MemoryStore store;
  late FakeClock clock;

  setUp(() {
    store = MemoryStore();
    clock = FakeClock(_now);
  });

  Future<void> pumpWizard(WidgetTester tester) => pumpFcScreen(
    tester,
    const ApplicationWizard(),
    store: store,
    clock: clock,
  );

  group('O1 / O2 landing', () {
    testWidgets('hero and the three feature cards render', (tester) async {
      tester.view.physicalSize = const Size(900, 4000) * tester.view.devicePixelRatio;
      addTearDown(tester.view.resetPhysicalSize);
      await tester.pumpWidget(
        MaterialApp(
          theme: buildDarkTheme(),
          home: const LandingScreen(),
        ),
      );

      expect(find.text(r'$POOP +420.69%'), findsOneWidget);
      expect(find.textContaining('QUARTERLY'), findsWidgets);
      expect(find.textContaining('EARNINGS REPORT'), findsWidgets);
      expect(
        find.text('Your time is valuable, even in the bathroom.'),
        findsOneWidget,
      );
      expect(find.text('What Your Portfolio Includes'), findsOneWidget);
      expect(find.text('Track Earnings'), findsOneWidget);
      expect(find.text('View Stats'), findsOneWidget);
      expect(find.text('Earn Achievements'), findsOneWidget);
      expect(find.text(r'$FLUSH +12.4%'), findsOneWidget);
      expect(find.text(r'$STATS +8.7%'), findsOneWidget);
      expect(find.text(r'$BADGE +31.2%'), findsOneWidget);
    });
  });

  group('O3 / O4 progress and cover', () {
    testWidgets('step 1 shows the cover page and STEP 1 OF 5', (tester) async {
      await pumpWizard(tester);

      expect(find.text('STEP 1 OF 5'), findsOneWidget);
      expect(find.text('FUCKCORPO INC.'), findsOneWidget);
      expect(find.text('APPLICATION FOR EMPLOYMENT'), findsOneWidget);
      expect(
        find.text('Chief Bathroom Revenue Officer (CBRO)'),
        findsOneWidget,
      );
      expect(find.text('Asset Liberation Division'), findsOneWidget);
      expect(find.text('Full-Time (Bathroom Hours)'), findsOneWidget);
      expect(
        tester
            .widget<LinearProgressIndicator>(
              find.byKey(ApplicationWizard.progressKey),
            )
            .value,
        closeTo(0.2, 0.0001),
      );
    });

    testWidgets('BEGIN APPLICATION advances to applicant information', (
      tester,
    ) async {
      await pumpWizard(tester);
      await tester.tap(find.text('BEGIN APPLICATION'));
      await tester.pumpAndSettle();

      expect(find.text('STEP 2 OF 5'), findsOneWidget);
      expect(find.text('APPLICANT INFORMATION'), findsOneWidget);
      expect(
        tester
            .widget<LinearProgressIndicator>(
              find.byKey(ApplicationWizard.progressKey),
            )
            .value,
        closeTo(0.4, 0.0001),
      );
    });
  });

  group('O5 applicant information and skills assessment', () {
    testWidgets('Back returns to the cover page', (tester) async {
      await pumpWizard(tester);
      await tester.tap(find.text('BEGIN APPLICATION'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Back'));
      await tester.pumpAndSettle();

      expect(find.text('STEP 1 OF 5'), findsOneWidget);
    });

    testWidgets('the star rating records a selection', (tester) async {
      await pumpWizard(tester);
      await tester.tap(find.text('BEGIN APPLICATION'));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(ApplicationWizard.starKey(4)));
      await tester.pump();

      expect(
        tester.widget<Icon>(find.byKey(ApplicationWizard.starIconKey(4))).icon,
        Icons.star,
      );
      expect(
        tester.widget<Icon>(find.byKey(ApplicationWizard.starIconKey(5))).icon,
        Icons.star_border,
      );
    });

    testWidgets('step 3 lists the motivations, composure and the oath', (
      tester,
    ) async {
      await pumpWizard(tester);
      await tester.tap(find.text('BEGIN APPLICATION'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('CONTINUE'));
      await tester.pumpAndSettle();

      expect(find.text('SKILLS ASSESSMENT'), findsOneWidget);
      expect(find.text('Existential dread'), findsOneWidget);
      expect(find.text('Sticking it to the man'), findsOneWidget);
      expect(find.text('Without question'), findsOneWidget);
      expect(find.text('I do not yet swear'), findsOneWidget);

      await tester.tap(find.byKey(ApplicationWizard.oathKey));
      await tester.pump();
      expect(find.text('I solemnly swear'), findsOneWidget);
    });
  });

  group('O6 background check', () {
    testWidgets('progress fills, then APPROVED, then step 5', (tester) async {
      await pumpWizard(tester);
      await tester.tap(find.text('BEGIN APPLICATION'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('CONTINUE'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('SUBMIT FOR REVIEW'));
      await tester.pump();

      expect(find.text('BACKGROUND CHECK'), findsOneWidget);
      expect(
        find.text('Please wait while we process your application...'),
        findsOneWidget,
      );

      await tester.pump(const Duration(seconds: 2));
      expect(find.text('APPROVED'), findsNothing);

      await tester.pump(const Duration(seconds: 2));
      expect(find.text('APPROVED'), findsOneWidget);

      await tester.pump(const Duration(milliseconds: 1200));
      await tester.pumpAndSettle();
      expect(find.text('OFFER LETTER'), findsOneWidget);
    });
  });

  group('O7 offer letter', () {
    testWidgets('accepting persists salary, profile and onboarded', (
      tester,
    ) async {
      await pumpWizard(tester);
      await _advanceToOffer(tester);

      await tester.enterText(
        find.byKey(ApplicationWizard.salaryKey),
        '124800',
      );
      await _selectOption(tester, ApplicationWizard.salaryTypeKey, 'Annual');
      await _selectOption(tester, ApplicationWizard.currencyKey, 'EUR');
      await _selectOption(tester, ApplicationWizard.industryKey, 'Healthcare');
      await tester.enterText(
        find.byKey(ApplicationWizard.regionKey),
        'California',
      );
      await tester.tap(find.text('ACCEPT OFFER & BEGIN'));
      await tester.pumpAndSettle();

      final AppState saved = _persisted(store)!;
      expect(saved.salary.amount, 124800);
      expect(saved.salary.type, SalaryType.annual);
      expect(saved.settings.currency, 'EUR');
      expect(saved.settings.industry, 'Healthcare');
      expect(saved.settings.region, 'California');
      expect(saved.onboarded, isTrue);
    });

    testWidgets('an empty salary blocks the offer and shows the error', (
      tester,
    ) async {
      await pumpWizard(tester);
      await _advanceToOffer(tester);

      await tester.tap(find.text('ACCEPT OFFER & BEGIN'));
      await tester.pumpAndSettle();

      expect(find.text(ApplicationWizard.invalidSalaryMessage), findsOneWidget);
      expect(_persisted(store), isNull);
    });
  });
}
