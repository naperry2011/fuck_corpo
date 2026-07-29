import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/theme/fc_theme.dart';
import 'router.dart';
import 'state/providers.dart';
import 'widgets/fc_toast_scope.dart';

/// Root widget for the Flutter parity app.
class FuckCorpoApp extends ConsumerWidget {
  const FuckCorpoApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // The stored preference is applied at boot, which React never did
    // (BUG-003).
    final String theme = ref.watch(
      appControllerProvider.select((s) => s.settings.theme),
    );

    return MaterialApp.router(
      title: 'FuckCorpo',
      debugShowCheckedModeBanner: false,
      theme: buildLightTheme(),
      darkTheme: buildDarkTheme(),
      themeMode: theme == 'light' ? ThemeMode.light : ThemeMode.dark,
      routerConfig: ref.watch(routerProvider),
      builder: (BuildContext context, Widget? child) =>
          FcToastScope(child: child ?? const SizedBox.shrink()),
    );
  }
}
