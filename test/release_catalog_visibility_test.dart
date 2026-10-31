import 'package:flutter_test/flutter_test.dart';
import 'package:neom_core/domain/model/app_release_item.dart';
import 'package:neom_core/utils/enums/app_in_use.dart';
import 'package:neom_core/utils/release_catalog_visibility.dart';

void main() {
  const firebasePdf =
      'https://firebasestorage.googleapis.com/v0/b/example.invalid/o/book.pdf?alt=media';
  const legacyUrl = 'https://escritoresmxi.org/wp-content/uploads/book.pdf';
  final assetFactories = <String, AppReleaseItem Function(String)>{
    'previewUrl': (url) => AppReleaseItem(previewUrl: url),
    'webPreviewUrl': (url) => AppReleaseItem(webPreviewUrl: url),
    'imgUrl': (url) => AppReleaseItem(imgUrl: url),
    'streamingUrl': (url) => AppReleaseItem(streamingUrl: url),
  };

  group('EMXI unavailable legacy host', () {
    for (final asset in assetFactories.entries) {
      test('hides a legacy ${asset.key}', () {
        expect(
          ReleaseCatalogVisibility.isVisible(
            asset.value(legacyUrl),
            app: AppInUse.e,
          ),
          isFalse,
        );
      });
    }

    for (final url in <String>[
      'http://escritoresmxi.org/book.pdf',
      'https://www.escritoresmxi.org/book.pdf',
      'https://media.storage.escritoresmxi.org/book.pdf',
      'HTTPS://ESCRITORESMXI.ORG/book.pdf',
      '//escritoresmxi.org/book.pdf',
      'escritoresmxi.org/book.pdf',
      'www.escritoresmxi.org/book.pdf',
      'https://escritoresmxi.org.:443/book.pdf',
      '  https://escritoresmxi.org/book.pdf  ',
    ]) {
      test('recognizes legacy hostname in $url', () {
        expect(
          ReleaseCatalogVisibility.isVisible(
            AppReleaseItem(previewUrl: url),
            app: AppInUse.e,
          ),
          isFalse,
        );
      });
    }

    test('hides a legacy cover even when the PDF was migrated', () {
      expect(
        ReleaseCatalogVisibility.isVisible(
          AppReleaseItem(previewUrl: firebasePdf, imgUrl: legacyUrl),
          app: AppInUse.e,
        ),
        isFalse,
      );
    });

    test('hides a WooCommerce-only external landing page', () {
      expect(
        ReleaseCatalogVisibility.isVisible(
          AppReleaseItem(externalUrl: legacyUrl),
          app: AppInUse.e,
        ),
        isFalse,
      );
    });

    for (final asset in assetFactories.entries.where(
      (asset) => asset.key == 'previewUrl' || asset.key == 'streamingUrl',
    )) {
      test('keeps migrated ${asset.key} despite old commercial link', () {
        final item = asset.value(firebasePdf)..externalUrl = legacyUrl;
        expect(
          ReleaseCatalogVisibility.isVisible(item, app: AppInUse.e),
          isTrue,
        );
      });
    }

    test('a migrated cover alone does not make an old landing page usable', () {
      expect(
        ReleaseCatalogVisibility.isVisible(
          AppReleaseItem(imgUrl: firebasePdf, externalUrl: legacyUrl),
          app: AppInUse.e,
        ),
        isFalse,
      );
    });

    test('a web iframe alone does not provide a native-readable file', () {
      expect(
        ReleaseCatalogVisibility.isVisible(
          AppReleaseItem(webPreviewUrl: firebasePdf, externalUrl: legacyUrl),
          app: AppInUse.e,
        ),
        isFalse,
      );
    });

    test('does not change the item while determining visibility', () {
      final item = AppReleaseItem(
        id: 'legacy-record',
        previewUrl: legacyUrl,
        externalUrl: legacyUrl,
      );
      final original = item.toJSON();
      expect(
        ReleaseCatalogVisibility.isVisible(item, app: AppInUse.e),
        isFalse,
      );
      expect(item.toJSON(), original);
    });
  });

  group('host matching without substring false positives', () {
    for (final url in <String>[
      firebasePdf,
      'https://storage.googleapis.com/example.invalid/escritoresmxi.org/book.pdf',
      'https://example.invalid/book.pdf?source=https://escritoresmxi.org/book.pdf',
      'https://example.invalid/book.pdf#escritoresmxi.org',
      'https://escritoresmxi.org.example.invalid/book.pdf',
      'https://not-escritoresmxi.org/book.pdf',
      'https://escritoresmxi.org@example.invalid/book.pdf',
      '/images/escritoresmxi.org/cover.jpg',
      '',
    ]) {
      test('retains asset $url', () {
        expect(
          ReleaseCatalogVisibility.isVisible(
            AppReleaseItem(previewUrl: url),
            app: AppInUse.e,
          ),
          isTrue,
        );
      });
    }

    test(
      'retains Firebase releases with historical WooCommerce identifiers',
      () {
        final item = AppReleaseItem(
          id: '12345',
          metaId: 'woocommerce-67890',
          previewUrl: firebasePdf,
          externalUrl: legacyUrl,
        );
        expect(
          ReleaseCatalogVisibility.isVisible(item, app: AppInUse.e),
          isTrue,
        );
      },
    );

    test('does not change the catalog policy of other apps', () {
      final item = AppReleaseItem(
        previewUrl: legacyUrl,
        imgUrl: legacyUrl,
        externalUrl: legacyUrl,
      );
      for (final app in AppInUse.values.where((app) => app != AppInUse.e)) {
        expect(
          ReleaseCatalogVisibility.isVisible(item, app: app),
          isTrue,
          reason: 'Legacy EMXI host restriction must not affect $app',
        );
      }
    });
  });
}
