import 'dart:math';

/// Verbatim port of `FUN_FACTS` in `src/utils/funFacts.js`. Copy is
/// parity-critical: do not edit, reorder, or add to this list.
const List<String> funFacts = <String>[
  'The average American spends 30 minutes per day on the toilet. '
      "That's 182 hours per year of tax-free income potential.",
  'If every worker took one extra 5-minute bathroom break daily, corporations '
      "would lose \$35 billion annually. You're doing your part.",
  "Studies show bathroom breaks increase productivity by 12%. You're basically "
      'a hero.',
  'A Fortune 500 CEO makes more during one bathroom break than most workers '
      'make in a week.',
  'The first flushing toilet was invented in 1596. Workers have been getting '
      'paid on the throne ever since.',
  'The average worker checks their phone 96 times per day. At least '
      "you're getting paid for some of them.",
  'Your bathroom break costs your employer about \$0.50. Your mental health? '
      'Priceless.',
  "If bathroom breaks were a stock, they'd have a 100% return rate. You "
      'literally cannot lose.',
  'The Department of Labor confirms: your employer cannot restrict reasonable '
      'bathroom access. Know your rights.',
  "Japanese companies have 'nap rooms.' American workers have bathroom "
      'breaks. Adapt and overcome.',
  'The most popular bathroom break time is 10:30 AM. Peak market hours.',
  'Remote workers take 23% more bathroom breaks. Working from home is '
      'literally more profitable.',
  'The longest recorded bathroom break in corporate history was 47 minutes. '
      'Challenge accepted?',
  'Toilet paper was first commercially available in 1857. The bathroom break '
      'economy has been growing ever since.',
  "Your bathroom break earns you money AND reduces your employer's "
      "productivity metrics. That's what we call a win-win.",
  'Ancient Romans had public toilets where they discussed politics. Your '
      'bathroom break is a democratic tradition.',
  "The average office toilet is flushed 20 times per day. That's 20 "
      'micro-transactions of freedom.',
  "Companies spend \$150 billion on employee wellness programs. You've found "
      'a free one.',
  "A 10-minute bathroom break at \$75K salary earns you \$6.01. That's a free "
      'coffee.',
  "Bathroom breaks are protected under OSHA regulation 29 CFR 1910.141. You're "
      'exercising your rights.',
  "In the time it takes to read this fact, you've earned approximately \$0.43.",
  'The average bathroom break lasts 8.5 minutes. Rookies.',
  'Your bathroom break is technically a form of passive income. Warren Buffett '
      'would be proud.',
  "If you invested your bathroom earnings in an index fund, you'd have... "
      'well, still bathroom earnings.',
  "The word 'salary' comes from 'sal' (salt). Your bathroom earnings come from "
      'pure audacity.',
  "According to our data, Mondays have the most bathroom breaks. We don't "
      'blame you.',
  "Your bathroom break costs less than a CEO's morning coffee. Think about "
      'that.',
  "Employee bathroom breaks have existed since the Industrial Revolution. "
      "You're part of a proud tradition.",
  'The average American will spend 3 years of their life on the toilet. Make '
      'them count.',
  '70% of people use their phone on the toilet. 100% of FuckCorpo users are '
      'getting paid while doing it.',
  'The S&P 500 returns about 10% per year. Your bathroom ROI? Infinite. You '
      'invested nothing.',
  'Corporate profits hit record highs in 2024. Your bathroom earnings are '
      'just wealth redistribution.',
];

/// Port of `getRandomFact`. [random] is injectable for tests.
String randomFact([Random? random]) =>
    funFacts[(random ?? Random()).nextInt(funFacts.length)];

/// Verbatim port of `TIMER_MOTIVATIONS` in `src/utils/funFacts.js`. Copy is
/// parity-critical: do not edit, reorder, or add to this list.
const List<String> timerMotivations = <String>[
  'Every second counts... toward your paycheck.',
  "Your CEO wouldn't hesitate. Neither should you.",
  "This is what they mean by 'passive income.'",
  "You're not wasting time, you're investing it.",
  'The market is open. Your portfolio is growing.',
  'This break is an act of economic revolution.',
  'Shareholders would approve of this transaction.',
  'Your ROI is looking excellent right now.',
  'Keep calm and keep earning.',
  "This is the most productive thing you'll do today.",
  'Your bathroom break, your rules.',
  'Making money moves. Literally.',
  'The Board of Directors approves this break.',
  'Somewhere, a CEO is jealous of your efficiency.',
  'This is what financial freedom looks like.',
  "You're basically a day trader. Of time.",
  'Another day, another bathroom dollar.',
  "Corporate can't stop the signal.",
  'Your comfort is non-negotiable. Your earnings are non-refundable.',
  'This transaction has been approved by the Department of Not Caring.',
  'You are currently outperforming most hedge funds.',
  'Compounding returns start with a single flush.',
];

/// Port of `getRandomMotivation`. [random] is injectable for tests.
String randomMotivation([Random? random]) =>
    timerMotivations[(random ?? Random()).nextInt(timerMotivations.length)];
