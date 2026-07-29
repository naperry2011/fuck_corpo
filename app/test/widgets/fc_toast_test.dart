import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fuckcorpo/core/theme/colors.dart';
import 'package:fuckcorpo/widgets/fc_toast.dart';
import 'package:fuckcorpo/widgets/fc_toast_host.dart';

import '../helpers/pump_app.dart';

void main() {
  group('FcToast', () {
    testWidgets('renders one icon and accent per type', (tester) async {
      for (final (FcToastType type, IconData icon, Color accent) in <
          (FcToastType, IconData, Color)
      >[
        (FcToastType.success, Icons.check_circle_outline, FcColors.green),
        (FcToastType.info, Icons.info_outline, FcColors.gray),
        (FcToastType.achievement, Icons.emoji_events_outlined, FcColors.gold),
        (FcToastType.warning, Icons.warning_amber_outlined, FcColors.red),
      ]) {
        await pumpFcApp(
          tester,
          FcToast(
            data: FcToastData(id: '1', message: 'Break logged', type: type),
            onDismiss: () {},
          ),
        );

        expect(find.text('Break logged'), findsOneWidget);
        expect(find.byIcon(icon), findsOneWidget);
        expect(type.accent, accent);
      }
    });

    testWidgets('dismiss button fires the callback', (tester) async {
      int dismissed = 0;
      await pumpFcApp(
        tester,
        FcToast(
          data: const FcToastData(id: '1', message: 'Hi'),
          onDismiss: () => dismissed++,
        ),
      );

      await tester.tap(find.byIcon(Icons.close));
      await tester.pump();
      expect(dismissed, 1);
    });
  });

  group('FcToastHost', () {
    testWidgets('renders nothing when the queue is empty', (tester) async {
      await pumpFcApp(
        tester,
        const FcToastHost(toasts: <FcToastData>[], child: Text('BODY')),
      );

      expect(find.byType(FcToast), findsNothing);
      expect(find.text('BODY'), findsOneWidget);
    });

    testWidgets('stacks every queued toast over the child', (tester) async {
      await pumpFcApp(
        tester,
        FcToastHost(
          toasts: const <FcToastData>[
            FcToastData(id: '1', message: 'One'),
            FcToastData(
              id: '2',
              message: 'Two',
              type: FcToastType.achievement,
            ),
          ],
          onDismiss: (_) {},
          child: const Text('BODY'),
        ),
      );

      expect(find.byType(FcToast), findsNWidgets(2));
      expect(find.text('One'), findsOneWidget);
      expect(find.text('Two'), findsOneWidget);
    });

    testWidgets('dismiss passes the toast id back', (tester) async {
      String? dismissedId;
      await pumpFcApp(
        tester,
        FcToastHost(
          toasts: const <FcToastData>[FcToastData(id: 'abc', message: 'One')],
          onDismiss: (String id) => dismissedId = id,
          child: const Text('BODY'),
        ),
      );

      await tester.tap(find.byIcon(Icons.close));
      await tester.pump();
      expect(dismissedId, 'abc');
    });
  });
}
