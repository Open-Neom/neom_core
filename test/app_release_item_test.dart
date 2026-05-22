// Tests for `AppReleaseItem` — modelo central de catalog (libros, canciones,
// podcasts, etc). Cubre defaults, computed properties (isAudioContent,
// isBookContent, displayDuration, streamUrl), generateSlug, y round-trip
// básico de campos top-level.

import 'package:flutter_test/flutter_test.dart';
import 'package:neom_core/domain/model/app_release_item.dart';
import 'package:neom_core/utils/enums/media_item_type.dart';
import 'package:neom_core/utils/enums/owner_type.dart';
import 'package:neom_core/utils/enums/release_status.dart';
import 'package:neom_core/utils/enums/release_type.dart';

void main() {
  group('AppReleaseItem — defaults', () {
    test('constructor sin params', () {
      final r = AppReleaseItem();
      expect(r.id, '');
      expect(r.name, '');
      expect(r.description, '');
      expect(r.imgUrl, '');
      expect(r.previewUrl, '');
      expect(r.duration, 0);
      expect(r.type, ReleaseType.single);
      expect(r.status, ReleaseStatus.draft);
      expect(r.mediaType, isNull);
      expect(r.ownerEmail, '');
      expect(r.ownerType, OwnerType.notDefined);
      expect(r.categories, isEmpty);
      expect(r.isRental, isTrue,
          reason: 'isRental default true por diseño (membresía da acceso)');
      expect(r.state, 0);
      expect(r.slug, '');
      expect(r.isSuspended, isFalse);
      expect(r.totalPageViews, 0);
    });
  });

  group('AppReleaseItem.streamUrl (PlayableItem)', () {
    test('usa streamingUrl cuando está presente', () {
      final r = AppReleaseItem(streamingUrl: 'https://stream', previewUrl: 'https://preview');
      expect(r.streamUrl, 'https://stream');
    });

    test('cae a previewUrl cuando streamingUrl es null', () {
      final r = AppReleaseItem(previewUrl: 'https://preview');
      expect(r.streamUrl, 'https://preview');
    });
  });

  group('AppReleaseItem.ownerId (PlayableItem)', () {
    test('usa ownerProfileId cuando está presente', () {
      final r = AppReleaseItem(ownerProfileId: 'p1', ownerEmail: 'e@x.com');
      expect(r.ownerId, 'p1');
    });

    test('cae a ownerEmail cuando ownerProfileId es null', () {
      final r = AppReleaseItem(ownerEmail: 'e@x.com');
      expect(r.ownerId, 'e@x.com');
    });
  });

  group('AppReleaseItem.isInternal', () {
    test('siempre true (AppReleaseItem es contenido interno)', () {
      expect(AppReleaseItem().isInternal, isTrue);
    });
  });

  group('AppReleaseItem.displayDuration', () {
    test('vacío cuando duration <= 0', () {
      expect(AppReleaseItem(duration: 0).displayDuration, '');
      expect(AppReleaseItem(duration: -5).displayDuration, '');
    });

    test('formato MM:SS cuando < 1 hora', () {
      // 3 minutos 45 segundos = 225 segundos
      final r = AppReleaseItem(duration: 225);
      expect(r.displayDuration, '3:45');
    });

    test('formato Hh MMm cuando >= 1 hora', () {
      // 1h 30m = 5400 segundos
      final r = AppReleaseItem(duration: 5400);
      expect(r.displayDuration, '1h 30m');
    });

    test('formato pad de minutos (00 leading)', () {
      // 1h 5m = 3900 segundos
      final r = AppReleaseItem(duration: 3900);
      expect(r.displayDuration, '1h 05m');
    });
  });

  group('AppReleaseItem.isAudioContent', () {
    test('true para mediaType audio (song, podcast, audiobook, etc.)', () {
      for (final t in [
        MediaItemType.song, MediaItemType.podcast, MediaItemType.audiobook,
        MediaItemType.binaural, MediaItemType.frequency, MediaItemType.nature,
        MediaItemType.neomPreset,
      ]) {
        expect(AppReleaseItem(mediaType: t).isAudioContent, isTrue,
            reason: '$t debe contar como audio');
      }
    });

    test('false para mediaType book/pdf', () {
      expect(AppReleaseItem(mediaType: MediaItemType.book).isAudioContent, isFalse);
      expect(AppReleaseItem(mediaType: MediaItemType.pdf).isAudioContent, isFalse);
    });

    test('fallback a previewUrl cuando mediaType es null', () {
      expect(
        AppReleaseItem(previewUrl: 'https://x/song.mp3').isAudioContent,
        isTrue,
      );
      expect(
        AppReleaseItem(previewUrl: 'https://x/cool.wav').isAudioContent,
        isTrue,
      );
      expect(
        AppReleaseItem(previewUrl: 'https://x/track.flac').isAudioContent,
        isTrue,
      );
      expect(
        AppReleaseItem(previewUrl: 'https://x/book.pdf').isAudioContent,
        isFalse,
      );
    });

    test('strip query params para Firebase Storage URLs', () {
      final r = AppReleaseItem(
        previewUrl: 'https://firebasestorage.app/song.mp3?token=xyz',
      );
      expect(r.isAudioContent, isTrue);
    });
  });

  group('AppReleaseItem.isBookContent', () {
    test('true para mediaType book/pdf', () {
      expect(AppReleaseItem(mediaType: MediaItemType.book).isBookContent, isTrue);
      expect(AppReleaseItem(mediaType: MediaItemType.pdf).isBookContent, isTrue);
    });

    test('false para mediaType audio', () {
      expect(AppReleaseItem(mediaType: MediaItemType.song).isBookContent, isFalse);
    });

    test('fallback a previewUrl con .pdf/.epub/.mobi', () {
      expect(AppReleaseItem(previewUrl: 'x.pdf').isBookContent, isTrue);
      expect(AppReleaseItem(previewUrl: 'x.epub').isBookContent, isTrue);
      expect(AppReleaseItem(previewUrl: 'x.mobi').isBookContent, isTrue);
      expect(AppReleaseItem(previewUrl: 'x.mp3').isBookContent, isFalse);
    });
  });

  group('AppReleaseItem.generateSlug', () {
    test('título simple → kebab-case', () {
      expect(
        AppReleaseItem.generateSlug('Quemando mis razones'),
        'quemando-mis-razones',
      );
    });

    test('preserva acentos y ñ', () {
      expect(
        AppReleaseItem.generateSlug('Año del niño'),
        'año-del-niño',
      );
    });

    test('elimina caracteres especiales', () {
      expect(
        AppReleaseItem.generateSlug('Hola! ¿Mundo?'),
        'hola-mundo',
      );
    });
  });

  group('AppReleaseItem — round-trip básico', () {
    test('campos string básicos se preservan', () {
      final original = AppReleaseItem(
        id: 'r1',
        name: 'My Album',
        description: 'desc',
        imgUrl: 'https://img',
        previewUrl: 'https://preview',
        duration: 3000,
        type: ReleaseType.single,
        status: ReleaseStatus.draft,
        ownerEmail: 'a@x.com',
        ownerName: 'Ana',
        ownerType: OwnerType.notDefined,
        slug: 'my-album',
        state: 3,
        totalPageViews: 100,
      );
      final restored = AppReleaseItem.fromJSON(original.toJSON());

      expect(restored.id, original.id);
      expect(restored.name, original.name);
      expect(restored.description, original.description);
      expect(restored.imgUrl, original.imgUrl);
      expect(restored.previewUrl, original.previewUrl);
      expect(restored.duration, original.duration);
      expect(restored.type, original.type);
      expect(restored.status, original.status);
      expect(restored.ownerEmail, original.ownerEmail);
      expect(restored.ownerName, original.ownerName);
      expect(restored.ownerType, original.ownerType);
      expect(restored.slug, original.slug);
      expect(restored.state, original.state);
    });

    test('mapa vacío usa defaults', () {
      final r = AppReleaseItem.fromJSON(<String, dynamic>{});
      expect(r.type, ReleaseType.single);
      expect(r.status, ReleaseStatus.draft);
      expect(r.isRental, isTrue);
      expect(r.isSuspended, isFalse);
    });

    test('toJSON serializa mediaType como .name (string) si presente', () {
      final r = AppReleaseItem(mediaType: MediaItemType.song);
      expect(r.toJSON()['mediaType'], 'song');
    });

    test('toJSON serializa mediaType null como null', () {
      expect(AppReleaseItem().toJSON()['mediaType'], isNull);
    });
  });
}
