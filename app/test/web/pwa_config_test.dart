import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Guards the web shell against the class of defect that broke the React PWA
/// (BUG-001: a manifest declaring icons that were never committed), and against
/// silently shipping Flutter's default scaffold branding.
void main() {
  final Directory webDir = Directory('web');
  final File manifestFile = File('web/manifest.json');
  final File indexFile = File('web/index.html');

  late Map<String, dynamic> manifest;
  late String indexHtml;

  setUpAll(() {
    manifest = jsonDecode(manifestFile.readAsStringSync())
        as Map<String, dynamic>;
    indexHtml = indexFile.readAsStringSync();
  });

  group('manifest.json', () {
    test('carries FuckCorpo branding, not the Flutter scaffold default', () {
      expect(manifest['name'], contains('FuckCorpo'));
      expect(manifest['short_name'], 'FuckCorpo');
      expect(manifest['description'], isNot(contains('A new Flutter project')));
    });

    test('uses the corporate navy for theme and background', () {
      expect(manifest['theme_color'], '#0a1128');
      expect(manifest['background_color'], '#0a1128');
    });

    test('is installable: standalone, portrait, root scope and start_url', () {
      expect(manifest['display'], 'standalone');
      expect(manifest['orientation'], 'portrait');
      expect(manifest['scope'], '/');
      expect(manifest['start_url'], '/');
    });

    test('every declared icon file exists on disk (BUG-001)', () {
      final icons = (manifest['icons'] as List).cast<Map<String, dynamic>>();
      expect(icons, isNotEmpty);
      for (final icon in icons) {
        final file = File('${webDir.path}/${icon['src']}');
        expect(
          file.existsSync(),
          isTrue,
          reason: 'manifest declares ${icon['src']} but it is not committed',
        );
        expect(file.lengthSync(), greaterThan(0));
      }
    });

    test('declares both 192 and 512, any and maskable', () {
      final icons = (manifest['icons'] as List).cast<Map<String, dynamic>>();
      String key(Map<String, dynamic> i) => '${i['sizes']}/${i['purpose']}';
      final keys = icons.map(key).toSet();
      expect(keys, containsAll(<String>['192x192/any', '512x512/any']));
      expect(
        keys,
        containsAll(<String>['192x192/maskable', '512x512/maskable']),
      );
    });
  });

  group('index.html', () {
    test('has a real title and description', () {
      expect(indexHtml, contains('<title>FuckCorpo'));
      expect(indexHtml, isNot(contains('A new Flutter project')));
      expect(indexHtml, isNot(contains('<title>fuckcorpo</title>')));
    });

    test('carries link-preview tags, the only crawlable surface', () {
      expect(indexHtml, contains('property="og:title"'));
      expect(indexHtml, contains('property="og:description"'));
      expect(indexHtml, contains('property="og:image"'));
      expect(indexHtml, contains('name="twitter:card"'));
    });

    test('references an apple-touch-icon that exists', () {
      final match = RegExp(
        r'rel="apple-touch-icon"\s+href="([^"]+)"',
      ).firstMatch(indexHtml);
      expect(match, isNotNull);
      expect(File('${webDir.path}/${match!.group(1)}').existsSync(), isTrue);
    });

    test('references a favicon that exists', () {
      final match = RegExp(
        r'rel="icon"[^>]*href="([^"]+)"',
      ).firstMatch(indexHtml);
      expect(match, isNotNull);
      expect(File('${webDir.path}/${match!.group(1)}').existsSync(), isTrue);
    });

    test('sets the navy theme-color and a viewport', () {
      expect(indexHtml, contains('name="theme-color" content="#0a1128"'));
      expect(indexHtml, contains('name="viewport"'));
    });

    test('shows a branded boot state and tears it down on first frame', () {
      expect(indexHtml, contains('id="fc-boot"'));
      expect(indexHtml, contains('flutter-first-frame'));
    });
  });

  group('vercel.json', () {
    late Map<String, dynamic> vercel;

    setUpAll(() {
      vercel =
          jsonDecode(File('vercel.json').readAsStringSync())
              as Map<String, dynamic>;
    });

    test('serves the Flutter web output', () {
      expect(vercel['outputDirectory'], 'build/web');
    });

    test('rewrites every path to index.html so deep links survive refresh', () {
      final rewrites = (vercel['rewrites'] as List)
          .cast<Map<String, dynamic>>();
      expect(
        rewrites.any((r) => r['destination'] == '/index.html'),
        isTrue,
      );
    });

    test('index.html and the service worker are never cached hard', () {
      final headers = (vercel['headers'] as List).cast<Map<String, dynamic>>();
      String? cacheFor(String source) {
        for (final entry in headers) {
          if (entry['source'] != source) continue;
          for (final h in (entry['headers'] as List)
              .cast<Map<String, dynamic>>()) {
            if (h['key'] == 'Cache-Control') return h['value'] as String;
          }
        }
        return null;
      }

      expect(cacheFor('/index.html'), contains('max-age=0'));
      expect(cacheFor('/flutter_service_worker.js'), contains('max-age=0'));
      expect(cacheFor('/assets/(.*)'), contains('immutable'));
    });
  });
}
