import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

/// Guards the shipped brand raster assets: PWA icons, the favicon, the
/// apple-touch-icon, and the 1200x630 social card.
///
/// `pwa_config_test.dart` only proves the files referenced by the manifest and
/// `index.html` exist. That was enough while the icons were generated
/// placeholders. Now that they are produced by
/// `tool/generate_brand_assets.py`, this file additionally pins their real
/// pixel dimensions and rejects an empty or flat-fill regeneration, so a broken
/// asset run cannot ship silently.
void main() {
  final Directory webDir = Directory('web');

  /// Reads width and height out of a PNG IHDR chunk without pulling in an
  /// image decoding dependency. PNG layout: 8-byte signature, 4-byte chunk
  /// length, 4-byte type, then width and height as big-endian uint32.
  ({int width, int height}) pngSize(File file) {
    final Uint8List bytes = file.readAsBytesSync();
    expect(
      bytes.length,
      greaterThan(24),
      reason: '${file.path} is too short to be a PNG',
    );
    expect(
      bytes.sublist(0, 8),
      <int>[137, 80, 78, 71, 13, 10, 26, 10],
      reason: '${file.path} does not carry the PNG signature',
    );
    final ByteData view = ByteData.sublistView(bytes);
    return (width: view.getUint32(16), height: view.getUint32(20));
  }

  group('PWA icons', () {
    late List<Map<String, dynamic>> icons;

    setUpAll(() {
      final manifest =
          jsonDecode(File('web/manifest.json').readAsStringSync())
              as Map<String, dynamic>;
      icons = (manifest['icons'] as List).cast<Map<String, dynamic>>();
    });

    test('every icon has the exact pixel size the manifest advertises', () {
      for (final icon in icons) {
        final file = File('${webDir.path}/${icon['src']}');
        final declared = (icon['sizes'] as String).split('x');
        final size = pngSize(file);
        expect(
          <int>[size.width, size.height],
          <int>[int.parse(declared[0]), int.parse(declared[1])],
          reason: '${icon['src']} does not match its declared sizes',
        );
      }
    });

    test('icons carry real artwork, not a blank or single-colour fill', () {
      for (final icon in icons) {
        final file = File('${webDir.path}/${icon['src']}');
        expect(
          file.lengthSync(),
          greaterThan(1024),
          reason: '${icon['src']} is suspiciously small for real artwork',
        );
      }
    });

    test('apple-touch-icon is 180x180', () {
      final size = pngSize(File('web/icons/apple-touch-icon.png'));
      expect(<int>[size.width, size.height], <int>[180, 180]);
    });

    test('favicon is a square PNG of at least 32px', () {
      final size = pngSize(File('web/favicon.png'));
      expect(size.width, size.height);
      expect(size.width, greaterThanOrEqualTo(32));
    });
  });

  group('social card', () {
    final File card = File('web/social/og-card.png');

    test('exists at the 1200x630 size link unfurlers expect', () {
      expect(
        card.existsSync(),
        isTrue,
        reason: 'no social card committed at ${card.path}',
      );
      final size = pngSize(card);
      expect(<int>[size.width, size.height], <int>[1200, 630]);
    });

    test('is real artwork rather than a flat placeholder', () {
      expect(card.lengthSync(), greaterThan(10 * 1024));
    });
  });

  group('index.html link preview', () {
    late String indexHtml;

    setUpAll(() {
      indexHtml = File('web/index.html').readAsStringSync();
    });

    String? content(String attr, String key) {
      final match = RegExp(
        '$attr="$key"\\s+content="([^"]+)"',
      ).firstMatch(indexHtml);
      return match?.group(1);
    }

    test('og:image points at the committed social card', () {
      final src = content('property', 'og:image');
      expect(src, isNotNull);
      expect(src, contains('og-card.png'));
      expect(File('${webDir.path}/$src').existsSync(), isTrue);
    });

    test('declares the card dimensions so unfurlers can lay it out', () {
      expect(content('property', 'og:image:width'), '1200');
      expect(content('property', 'og:image:height'), '630');
      expect(content('property', 'og:image:alt'), isNotNull);
    });

    test('uses a large twitter card, matching the 1.91:1 artwork', () {
      expect(content('name', 'twitter:card'), 'summary_large_image');
      final src = content('name', 'twitter:image');
      expect(src, contains('og-card.png'));
      expect(File('${webDir.path}/$src').existsSync(), isTrue);
    });
  });
}
