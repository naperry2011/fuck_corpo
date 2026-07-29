import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fuckcorpo/core/theme/fc_theme.dart';
import 'package:fuckcorpo/state/providers.dart';
import 'package:fuckcorpo/widgets/fc_toast_scope.dart';

import 'fake_clock.dart';
import 'memory_store.dart';


/// Mounts [child] inside the real app theme so widget tests exercise the same
/// text and color tokens the app uses.
Future<void> pumpFcApp(
  WidgetTester tester,
  Widget child, {
  Size? surfaceSize,
}) async {
  if (surfaceSize != null) {
    tester.view.physicalSize = surfaceSize * tester.view.devicePixelRatio;
    addTearDown(tester.view.resetPhysicalSize);
  }
  await tester.pumpWidget(
    MaterialApp(
      theme: buildDarkTheme(),
      home: Scaffold(body: Center(child: child)),
    ),
  );
}

/// Mounts a full screen with the state layer wired to an in-memory store and a
/// hand-advanced clock, plus the toast overlay the screens dispatch into.
///
/// The scroll view stands in for the one `FcAppShell` provides, so the screen
/// under test can stay a plain column.
Future<void> pumpFcScreen(
  WidgetTester tester,
  Widget child, {
  required MemoryStore store,
  required FakeClock clock,
  Size surfaceSize = const Size(900, 2200),
}) async {
  tester.view.physicalSize = surfaceSize * tester.view.devicePixelRatio;
  addTearDown(tester.view.resetPhysicalSize);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        keyValueStoreProvider.overrideWithValue(store),
        clockProvider.overrideWithValue(clock.call),
      ],
      child: MaterialApp(
        theme: buildDarkTheme(),
        home: FcToastScope(
          child: Scaffold(
            body: SingleChildScrollView(child: child),
          ),
        ),
      ),
    ),
  );
}
