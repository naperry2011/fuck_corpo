import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'features/achievements/achievements_screen.dart';
import 'features/dashboard/dashboard_screen.dart';
import 'features/onboarding/landing_screen.dart';
import 'features/settings/settings_screen.dart';
import 'features/timer/timer_screen.dart';
import 'state/providers.dart';
import 'widgets/fc_app_shell.dart';
import 'widgets/fc_navbar.dart';
import 'widgets/fc_ticker.dart';

/// The onboarding gate lives at its own path. React rendered `Landing` in place
/// of the router outlet, which left the URL pointing at a route the user could
/// not actually see (deviation D-107).
const String fcLandingRoute = '/welcome';

/// Port of `src/App.jsx`: four routes plus the `state.onboarded` gate.
final Provider<GoRouter> routerProvider = Provider<GoRouter>((Ref ref) {
  final ValueNotifier<bool> onboarded = ValueNotifier<bool>(
    ref.read(appControllerProvider).onboarded,
  );
  ref.onDispose(onboarded.dispose);
  ref.listen<bool>(
    appControllerProvider.select((s) => s.onboarded),
    (bool? _, bool next) => onboarded.value = next,
  );

  return GoRouter(
    initialLocation: fcNavDestinations.first.route,
    refreshListenable: onboarded,
    redirect: (BuildContext context, GoRouterState state) {
      final bool atGate = state.matchedLocation == fcLandingRoute;
      if (!onboarded.value) return atGate ? null : fcLandingRoute;
      return atGate ? fcNavDestinations.first.route : null;
    },
    routes: <RouteBase>[
      GoRoute(
        path: fcLandingRoute,
        builder: (BuildContext context, GoRouterState state) =>
            const LandingScreen(),
      ),
      ShellRoute(
        builder: (BuildContext context, GoRouterState state, Widget child) =>
            _ShellScaffold(location: state.matchedLocation, child: child),
        routes: <RouteBase>[
          GoRoute(
            path: '/',
            builder: (BuildContext context, GoRouterState state) =>
                const TimerScreen(),
          ),
          GoRoute(
            path: '/dashboard',
            builder: (BuildContext context, GoRouterState state) =>
                const DashboardScreen(),
          ),
          GoRoute(
            path: '/achievements',
            builder: (BuildContext context, GoRouterState state) =>
                const AchievementsScreen(),
          ),
          GoRoute(
            path: '/settings',
            builder: (BuildContext context, GoRouterState state) =>
                const SettingsScreen(),
          ),
        ],
      ),
    ],
  );
});

/// The shell, with the ticker fed from live state.
class _ShellScaffold extends ConsumerWidget {
  const _ShellScaffold({required this.child, required this.location});

  final Widget child;
  final String location;

  int get _index {
    for (int i = 0; i < fcNavDestinations.length; i++) {
      if (fcNavDestinations[i].route == location) return i;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(appControllerProvider);
    return FcAppShell(
      currentIndex: _index,
      tickerItems: FcTicker.buildItems(
        breaks: state.breaks,
        perMinuteRate: ref.watch(perMinuteRateProvider),
        currency: ref.watch(currencyProvider),
        now: ref.watch(clockProvider)(),
      ),
      onSelect: (int index) =>
          context.go(fcNavDestinations[index].route),
      child: child,
    );
  }
}
