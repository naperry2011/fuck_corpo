import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/theme/spacing.dart';
import 'fc_navbar.dart';
import 'fc_ticker.dart';

/// Port of `src/components/layout/Layout.jsx`: navbar, ticker, then the page
/// body inside the 1200pt container. On mobile the navbar moves to the bottom,
/// which is what the CSS media query does with `position: fixed; bottom: 0`.
class FcAppShell extends StatelessWidget {
  const FcAppShell({
    super.key,
    required this.child,
    required this.currentIndex,
    required this.onSelect,
    this.tickerItems = const <FcTickerItem>[],
    this.animateTicker = true,
  });

  static const Key contentKey = Key('fc_app_shell_content');

  final Widget child;
  final int currentIndex;
  final ValueChanged<int> onSelect;
  final List<FcTickerItem> tickerItems;
  final bool animateTicker;

  @override
  Widget build(BuildContext context) {
    final bool compact =
        MediaQuery.sizeOf(context).width < FcBreakpoints.tablet;

    final Widget navbar = FcNavbar(
      currentIndex: currentIndex,
      onSelect: onSelect,
    );
    final Widget ticker = FcTicker(
      items: tickerItems,
      animate: animateTicker,
    );

    final Widget body = Expanded(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: FcSpacing.xl),
        child: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            final double width = math.min(
              constraints.maxWidth,
              FcLayout.contentWidth,
            );
            return Center(
              child: SizedBox(
                key: contentKey,
                width: width,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: FcSpacing.s,
                  ),
                  child: child,
                ),
              ),
            );
          },
        ),
      ),
    );

    return Scaffold(
      body: Column(
        children: compact
            ? <Widget>[ticker, body, navbar]
            : <Widget>[navbar, ticker, body],
      ),
    );
  }
}
