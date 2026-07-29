import 'package:flutter/material.dart';

import '../../core/theme/colors.dart';
import '../../core/theme/spacing.dart';
import '../../core/theme/typography.dart';
import '../../widgets/fc_card.dart';
import 'application_wizard.dart';

/// Port of `src/pages/Landing.jsx`: hero, the application wizard, then the
/// three feature cards. Rendered instead of the app shell while
/// `state.onboarded` is false.
class LandingScreen extends StatelessWidget {
  const LandingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: FcSpacing.s,
            vertical: FcSpacing.xl,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: FcLayout.narrowWidth),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Text(
                    r'$POOP +420.69%',
                    textAlign: TextAlign.center,
                    style: FcText.mono.copyWith(
                      fontSize: 14,
                      color: FcColors.green,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: FcSpacing.s),
                  Text.rich(
                    TextSpan(
                      children: const <TextSpan>[
                        TextSpan(text: 'QUARTERLY '),
                        TextSpan(
                          text: 'EARNINGS REPORT',
                          style: TextStyle(color: FcColors.green),
                        ),
                      ],
                      style: Theme.of(context).textTheme.displayMedium,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: FcSpacing.s),
                  Text(
                    'Your time is valuable, even in the bathroom.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: FcSpacing.xs),
                  Text(
                    'Track exactly how much your employer pays you to handle '
                    'personal business. Because every minute on the clock '
                    'counts toward your bottom line.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: FcColors.gray,
                    ),
                  ),
                  const SizedBox(height: FcSpacing.xl),
                  const ApplicationWizard(),
                  const SizedBox(height: FcSpacing.xl),
                  Text(
                    'What Your Portfolio Includes',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: FcColors.gray,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: FcSpacing.m),
                  const _FeatureCard(
                    emoji: '💰',
                    title: 'Track Earnings',
                    body:
                        'Log every bathroom break and watch your '
                        'off-the-books compensation grow in real time.',
                    ticker: r'$FLUSH +12.4%',
                  ),
                  const SizedBox(height: FcSpacing.s),
                  const _FeatureCard(
                    emoji: '📊',
                    title: 'View Stats',
                    body:
                        'Detailed analytics on your ROI. Daily, weekly, and '
                        'monthly breakdowns of time reclaimed.',
                    ticker: r'$STATS +8.7%',
                  ),
                  const SizedBox(height: FcSpacing.s),
                  const _FeatureCard(
                    emoji: '🏆',
                    title: 'Earn Achievements',
                    body:
                        'Unlock badges for milestones like "First \$100 '
                        'Earned" and "Marathon Session."',
                    ticker: r'$BADGE +31.2%',
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  const _FeatureCard({
    required this.emoji,
    required this.title,
    required this.body,
    required this.ticker,
  });

  final String emoji;
  final String title;
  final String body;
  final String ticker;

  @override
  Widget build(BuildContext context) {
    return FcCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(emoji, style: const TextStyle(fontSize: 32)),
          const SizedBox(height: FcSpacing.xs),
          Text(title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: FcSpacing.xxs),
          Text(body, style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: FcSpacing.xs),
          Text(
            ticker,
            style: FcText.mono.copyWith(fontSize: 12, color: FcColors.green),
          ),
        ],
      ),
    );
  }
}
