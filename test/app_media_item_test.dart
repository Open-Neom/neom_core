// Tests for `AppMediaItem` — modelo de items reproducibles externos
// (Spotify, YT Music, Jamendo, etc). Cubre defaults, computed
// properties (isAudioContent, isBookContent, displayDuration), parsing
// de duración HH:MM:SS, y round-trip.

import 'package:flutter_test/flutter_test.dart';
import 'package:neom_core/domain/model/app_media_item.dart';
import 'package:neom_core/utils/enums/app_media_source.dart';
import 'package:neom_core/utils/enums/media_item_type.dart';

void main() {
  group('AppMediaItem — defaults', () {
    test('constructor sin params', () {
      final m = AppMediaItem();
      expect(m.id, '');
      expect(m.name, '');
      expect(m.album, '');
      expect(m.duration, 0);
      expect(m.url, '');
      expect(m.permaUrl, '');
      expect(m.lyrics, '');
      expect(m.is320Kbps, isFalse);
      expect(m.likes, 0);
      expect(m.state, 0);
      expect(m.type, isNull);
      expect(m.mediaSource, AppMediaSource.internal);
      expect(m.isSuspended, isFalse);
    });
  });

  group('AppMediaItem.isInternal', () {
    test('siempre false (AppMediaItem es external)', () {
      expect(AppMediaItem().isInternal, isFalse);
    });
  });

  group('AppMediaItem.streamUrl', () {
    test('devuelve url crudo', () {
      expect(AppMediaItem(url: 'https://stream').streamUrl, 'https://stream');
    });
  });

  group('AppMediaItem.previewUrl getter', () {
    test('devuelve permaUrl', () {
      expect(AppMediaItem(permaUrl: 'https://preview').previewUrl, 'https://preview');
    });
  });

  group('AppMediaItem.displayDuration', () {
    test('vacío cuando duration <= 0', () {
      expect(AppMediaItem(duration: 0).displayDuration, '');
    });

    test('formato MM:SS', () {
      expect(AppMediaItem(duration: 125).displayDuration, '2:05');
    });

    test('formato Hh MMm', () {
      expect(AppMediaItem(duration: 7200).displayDuration, '2h 00m');
    });
  });

  group('AppMediaItem.isAudioContent', () {
    test('true cuando type es audio', () {
      expect(AppMediaItem(type: MediaItemType.song).isAudioContent, isTrue);
      expect(AppMediaItem(type: MediaItemType.podcast).isAudioContent, isTrue);
    });

    test('false cuando type es book o pdf', () {
      expect(AppMediaItem(type: MediaItemType.book).isAudioContent, isFalse);
      expect(AppMediaItem(type: MediaItemType.pdf).isAudioContent, isFalse);
    });

    test('fallback por extensión cuando type es null', () {
      // No es .pdf/.epub/.mobi → cuenta como audio (por defecto)
      expect(AppMediaItem(url: 'https://x/song.mp3').isAudioContent, isTrue);
      expect(AppMediaItem(url: 'https://x/file.pdf').isAudioContent, isFalse);
      expect(AppMediaItem(url: 'https://x/file.epub').isAudioContent, isFalse);
    });
  });

  group('AppMediaItem.isBookContent (PlayableItem getter)', () {
    test('true cuando type == pdf', () {
      expect(AppMediaItem(type: MediaItemType.pdf).isBookContent, isTrue);
    });

    test('false cuando type es song', () {
      expect(AppMediaItem(type: MediaItemType.song).isBookContent, isFalse);
    });

    test('fallback por extensión .pdf', () {
      expect(AppMediaItem(url: 'x.pdf').isBookContent, isTrue);
      expect(AppMediaItem(url: 'x.epub').isBookContent, isTrue);
      expect(AppMediaItem(url: 'x.mp3').isBookContent, isFalse);
    });
  });

  group('AppMediaItem — fromJSON parsing de duration', () {
    test('duration como int se respeta', () {
      final m = AppMediaItem.fromJSON({'duration': 180, 'type': 'song'});
      expect(m.duration, 180);
    });

    test('duration como String "HH:MM:SS" se convierte a segundos', () {
      // 1:30:45 = 1*3600 + 30*60 + 45 = 5445
      final m = AppMediaItem.fromJSON({'duration': '1:30:45', 'type': 'song'});
      expect(m.duration, 5445);
    });

    test('duration como String "MM:SS" se convierte a segundos', () {
      // 3:45 = 3*60 + 45 = 225
      final m = AppMediaItem.fromJSON({'duration': '3:45', 'type': 'song'});
      expect(m.duration, 225);
    });

    test('duration como String "300" sin colon → int parse', () {
      final m = AppMediaItem.fromJSON({'duration': '300', 'type': 'song'});
      expect(m.duration, 300);
    });

    test('duration ausente usa default 30', () {
      final m = AppMediaItem.fromJSON({'type': 'song'});
      expect(m.duration, 30);
    });
  });

  group('AppMediaItem — round-trip básico', () {
    test('preserva campos básicos', () {
      final original = AppMediaItem(
        id: 'm1',
        name: 'Track 1',
        album: 'Album X',
        albumId: 'alb1',
        ownerName: 'Artist',
        url: 'https://stream',
        permaUrl: 'https://perma',
        duration: 240,
        type: MediaItemType.song,
        mediaSource: AppMediaSource.internal,
        is320Kbps: true,
        likes: 99,
      );
      final restored = AppMediaItem.fromJSON(original.toJSON());
      expect(restored.id, original.id);
      expect(restored.name, original.name);
      expect(restored.album, original.album);
      expect(restored.albumId, original.albumId);
      expect(restored.ownerName, original.ownerName);
      expect(restored.url, original.url);
      expect(restored.permaUrl, original.permaUrl);
      expect(restored.duration, original.duration);
      expect(restored.type, original.type);
      expect(restored.mediaSource, original.mediaSource);
      expect(restored.is320Kbps, original.is320Kbps);
      expect(restored.likes, original.likes);
    });

    test('toJSON serializa type como .value', () {
      final m = AppMediaItem(type: MediaItemType.song);
      // .name == 'song' y .value == 'song' coinciden — round-trip OK
      expect(m.toJSON()['type'], 'song');
    });

    test('mediaSource serializa como .name', () {
      expect(
        AppMediaItem(mediaSource: AppMediaSource.internal).toJSON()['mediaSource'],
        'internal',
      );
    });
  });
}
