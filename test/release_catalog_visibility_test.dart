import 'package:flutter_test/flutter_test.dart';
import 'package:neom_core/domain/model/app_media_item.dart';
import 'package:neom_core/domain/model/app_release_item.dart';
import 'package:neom_core/domain/model/external_item.dart';
import 'package:neom_core/domain/model/post.dart';
import 'package:neom_core/utils/enums/app_in_use.dart';
import 'package:neom_core/utils/enums/post_type.dart';
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

  group('Gigmeout unavailable legacy host (gigmeout.io)', () {
    const firebaseAudio =
        'https://firebasestorage.googleapis.com/v0/b/gig-me-out.appspot.com/o/track.mp3?alt=media';
    const modernCover = 'https://gigmeout.com/assets/assets/appIcon.png';
    const legacyGigUrl = 'https://gigmeout.io/wp-content/uploads/track.mp3';

    for (final asset in assetFactories.entries) {
      test('hides a legacy gigmeout.io ${asset.key}', () {
        expect(
          ReleaseCatalogVisibility.isVisible(
            asset.value(legacyGigUrl),
            app: AppInUse.g,
          ),
          isFalse,
        );
      });
    }

    test('hides a legacy gigmeout.io galleryUrl', () {
      expect(
        ReleaseCatalogVisibility.isVisible(
          AppReleaseItem(
            previewUrl: firebaseAudio,
            galleryUrls: const ['https://gigmeout.io/cover.jpg'],
          ),
          app: AppInUse.g,
        ),
        isFalse,
      );
    });

    for (final url in <String>[
      'https://gigmeout.io//',
      'http://gigmeout.io/song.mp3',
      'https://www.gigmeout.io/cover.jpg',
      'https://cdn.gigmeout.io/media/audio.mp3',
      'HTTPS://GIGMEOUT.IO/song.mp3',
      '//gigmeout.io/cover.jpg',
      'gigmeout.io/song.mp3',
      'www.gigmeout.io/song.mp3',
      'https://gigmeout.io.:443/song.mp3',
      '  https://gigmeout.io/song.mp3  ',
    ]) {
      test('recognizes legacy gigmeout.io hostname in $url', () {
        expect(
          ReleaseCatalogVisibility.usesUnavailableHost(url, app: AppInUse.g),
          isTrue,
        );
        expect(
          ReleaseCatalogVisibility.isVisible(
            AppReleaseItem(imgUrl: url),
            app: AppInUse.g,
          ),
          isFalse,
        );
      });
    }

    for (final url in <String>[
      firebaseAudio,
      modernCover,
      'https://www.gigmeout.com/song.mp3',
      'https://storage.googleapis.com/example.invalid/gigmeout.io/song.mp3',
      'https://example.invalid/song.mp3?source=https://gigmeout.io/song.mp3',
      'https://gigmeout.io.example.invalid/song.mp3',
      'https://not-gigmeout.io/song.mp3',
      'https://gigmeout.io@example.invalid/song.mp3',
      '',
    ]) {
      test('retains non-legacy Gigmeout asset $url', () {
        expect(
          ReleaseCatalogVisibility.usesUnavailableHost(url, app: AppInUse.g),
          isFalse,
        );
        expect(
          ReleaseCatalogVisibility.isVisible(
            AppReleaseItem(previewUrl: url),
            app: AppInUse.g,
          ),
          isTrue,
        );
      });
    }

    test('keeps migrated Firebase release despite legacy externalUrl', () {
      final item = AppReleaseItem(
        previewUrl: firebaseAudio,
        imgUrl: modernCover,
        externalUrl: legacyGigUrl,
      );
      expect(
        ReleaseCatalogVisibility.isVisible(item, app: AppInUse.g),
        isTrue,
      );
    });

    test('hides legacy gigmeout.io AppMediaItem and ExternalItem', () {
      expect(
        ReleaseCatalogVisibility.isMediaItemVisible(
          AppMediaItem(url: legacyGigUrl),
          app: AppInUse.g,
        ),
        isFalse,
      );
      expect(
        ReleaseCatalogVisibility.isMediaItemVisible(
          AppMediaItem(url: firebaseAudio, imgUrl: 'https://gigmeout.io//'),
          app: AppInUse.g,
        ),
        isFalse,
      );
      expect(
        ReleaseCatalogVisibility.isMediaItemVisible(
          AppMediaItem(url: firebaseAudio, imgUrl: modernCover),
          app: AppInUse.g,
        ),
        isTrue,
      );
      expect(
        ReleaseCatalogVisibility.isExternalItemVisible(
          ExternalItem(imgUrl: 'https://gigmeout.io/cover.jpg'),
          app: AppInUse.g,
        ),
        isFalse,
      );
      expect(
        ReleaseCatalogVisibility.isExternalItemVisible(
          ExternalItem(
            url: 'https://music.youtube.com/watch?v=abc',
            imgUrl: 'https://i.ytimg.com/vi/abc/hqdefault.jpg',
          ),
          app: AppInUse.g,
        ),
        isTrue,
      );
    });

    test('hides legacy gigmeout.io Posts while keeping modern/text posts', () {
      expect(
        ReleaseCatalogVisibility.isPostVisible(
          Post(
            type: PostType.releaseItem,
            mediaUrl: 'https://gigmeout.io//',
          ),
          app: AppInUse.g,
        ),
        isFalse,
      );
      expect(
        ReleaseCatalogVisibility.isPostVisible(
          Post(
            type: PostType.image,
            thumbnailUrl: 'https://cdn.gigmeout.io/thumb.jpg',
          ),
          app: AppInUse.g,
        ),
        isFalse,
      );
      expect(
        ReleaseCatalogVisibility.isPostVisible(
          Post(
            type: PostType.releaseItem,
            externalUrl: 'https://gigmeout.io/product/old-song',
          ),
          app: AppInUse.g,
        ),
        isFalse,
      );
      expect(
        ReleaseCatalogVisibility.isPostVisible(
          Post(
            type: PostType.caption,
            caption: 'Nueva canción en Gigmeout',
            profileImgUrl: 'https://gigmeout.io/old-avatar.jpg',
          ),
          app: AppInUse.g,
        ),
        isTrue,
      );
    });

    test('gigmeout.io restriction does not affect other apps', () {
      final item = AppReleaseItem(
        previewUrl: legacyGigUrl,
        imgUrl: legacyGigUrl,
        externalUrl: legacyGigUrl,
      );
      for (final app in AppInUse.values.where((app) => app != AppInUse.g)) {
        expect(
          ReleaseCatalogVisibility.isVisible(item, app: app),
          isTrue,
          reason: 'Legacy Gigmeout host restriction must not affect $app',
        );
      }
    });
  });
}
