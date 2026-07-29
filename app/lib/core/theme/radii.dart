import 'package:flutter/widgets.dart';

/// Corner radius tokens: 4 / 8 / 12.
class FcRadii {
  const FcRadii._();

  static const Radius smRadius = Radius.circular(4);
  static const Radius mdRadius = Radius.circular(8);
  static const Radius lgRadius = Radius.circular(12);

  static const BorderRadius sm = BorderRadius.all(smRadius);
  static const BorderRadius md = BorderRadius.all(mdRadius);
  static const BorderRadius lg = BorderRadius.all(lgRadius);
}
