import 'package:flutter/material.dart';

import '../core/theme/colors.dart';
import '../core/theme/spacing.dart';
import '../core/theme/typography.dart';

/// One navbar entry. [route] matches the React router path.
@immutable
class FcNavDestination {
  const FcNavDestination({
    required this.label,
    required this.icon,
    required this.route,
  });

  final String label;
  final IconData icon;
  final String route;
}

/// The four destinations, in the order `Navbar.jsx` renders them.
const List<FcNavDestination> fcNavDestinations = <FcNavDestination>[
  FcNavDestination(label: 'Timer', icon: Icons.timer_outlined, route: '/'),
  FcNavDestination(
    label: 'Dashboard',
    icon: Icons.bar_chart,
    route: '/dashboard',
  ),
  FcNavDestination(
    label: 'Achievements',
    icon: Icons.emoji_events_outlined,
    route: '/achievements',
  ),
  FcNavDestination(
    label: 'Settings',
    icon: Icons.settings_outlined,
    route: '/settings',
  ),
];

/// Port of `src/components/layout/Navbar.jsx`. Desktop shows the brand on the
/// left and the links on the right; at or below the tablet breakpoint the
/// brand is dropped and the links spread out, matching the CSS media query
/// that turns the bar into a fixed bottom nav.
class FcNavbar extends StatelessWidget {
  const FcNavbar({
    super.key,
    required this.currentIndex,
    required this.onSelect,
  });

  final int currentIndex;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final bool compact =
        MediaQuery.sizeOf(context).width < FcBreakpoints.tablet;

    final List<Widget> links = <Widget>[
      for (int i = 0; i < fcNavDestinations.length; i++)
        if (compact)
          Expanded(
            child: _FcNavLink(
              destination: fcNavDestinations[i],
              active: i == currentIndex,
              onTap: () => onSelect(i),
            ),
          )
        else
          _FcNavLink(
            destination: fcNavDestinations[i],
            active: i == currentIndex,
            onTap: () => onSelect(i),
          ),
    ];

    return Container(
      decoration: const BoxDecoration(
        color: FcColors.navy,
        border: Border(
          bottom: BorderSide(color: FcColors.slate),
        ),
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: FcSpacing.s,
        vertical: FcSpacing.xs,
      ),
      child: SafeArea(
        top: !compact,
        bottom: compact,
        child: Row(
          mainAxisAlignment: compact
              ? MainAxisAlignment.spaceAround
              : MainAxisAlignment.spaceBetween,
          children: <Widget>[
            if (!compact) const _FcBrand(),
            if (compact) ...links else Row(children: links),
          ],
        ),
      ),
    );
  }
}

class _FcBrand extends StatelessWidget {
  const _FcBrand();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        const Text(
          r'$',
          style: TextStyle(
            fontFamily: FcFonts.mono,
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: FcColors.green,
          ),
        ),
        const SizedBox(width: FcSpacing.xs),
        Text(
          'FUCKCORPO',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontFamily: FcFonts.display,
            fontWeight: FontWeight.w900,
            letterSpacing: 1,
          ),
        ),
      ],
    );
  }
}

class _FcNavLink extends StatelessWidget {
  const _FcNavLink({
    required this.destination,
    required this.active,
    required this.onTap,
  });

  final FcNavDestination destination;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Color color = active ? FcColors.green : FcColors.gray;
    return Semantics(
      selected: active,
      button: true,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: FcSpacing.xs,
            vertical: FcSpacing.xs,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(destination.icon, size: 20, color: color),
              const SizedBox(height: 2),
              // Scales down rather than truncating on the narrowest phones.
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  destination.label,
                  maxLines: 1,
                  style: TextStyle(
                    fontFamily: FcFonts.body,
                    fontSize: 12,
                    fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
