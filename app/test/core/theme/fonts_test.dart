import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:fuckcorpo/core/theme/typography.dart';

/// Guards the same class of defect as `pwa_config_test.dart`: a manifest that
/// names a file nobody committed. Here the manifest is `pubspec.yaml` and the
/// files are the brand fonts. If a family is declared in `FcFonts` but not
/// bundled, Flutter silently falls back to the platform default and the app
/// still passes every behavioral test, so nothing else would catch it.
void main() {
  late String pubspec;

  setUpAll(() => pubspec = File('pubspec.yaml').readAsStringSync());

  /// The `asset:` paths declared under the `fonts:` section.
  List<String> declaredAssets() => RegExp(r'-\s+asset:\s+(\S+)')
      .allMatches(pubspec)
      .map((RegExpMatch m) => m.group(1)!)
      .toList();

  test('every font family the theme names is declared in pubspec.yaml', () {
    for (final String family in <String>[
      FcFonts.display,
      FcFonts.body,
      FcFonts.mono,
    ]) {
      expect(
        pubspec,
        contains('family: $family'),
        reason: '$family is used by the theme but not bundled',
      );
    }
  });

  test('every declared font asset exists on disk and is non-empty', () {
    final List<String> assets = declaredAssets();
    expect(assets, isNotEmpty);
    for (final String asset in assets.toSet()) {
      final File file = File(asset);
      expect(
        file.existsSync(),
        isTrue,
        reason: 'pubspec declares $asset but it is not committed',
      );
      expect(file.lengthSync(), greaterThan(0));
    }
  });

  test('every declared font asset is a real TrueType binary', () {
    for (final String asset in declaredAssets().toSet()) {
      final List<int> magic = File(asset).openSync().readSync(4);
      // 0x00010000 for TrueType outlines, 'OTTO' for CFF.
      final bool isTrueType =
          magic[0] == 0x00 && magic[1] == 0x01 && magic[2] == 0x00 &&
          magic[3] == 0x00;
      final bool isOpenType =
          String.fromCharCodes(magic) == 'OTTO';
      expect(
        isTrueType || isOpenType,
        isTrue,
        reason: '$asset is not a font binary (placeholder or truncated?)',
      );
    }
  });

  test('the license for each bundled family ships alongside it', () {
    for (final String license in <String>[
      'assets/fonts/OFL-PlayfairDisplay.txt',
      'assets/fonts/OFL-WorkSans.txt',
      'assets/fonts/OFL-RobotoMono.txt',
    ]) {
      expect(File(license).existsSync(), isTrue, reason: 'missing $license');
    }
  });

  test('each family declares the weights the text theme asks for', () {
    // Display uses w700/w900, body w400..w600, mono w400 with copyWith.
    for (final int weight in <int>[400, 500, 600, 700, 900]) {
      expect(pubspec, contains('weight: $weight'));
    }
  });
}
