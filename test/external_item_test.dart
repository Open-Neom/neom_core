// Tests for `ExternalItem` — modelo de items externos (Spotify, YT, etc.).
//
// NC-46 esperado: línea 94 `dur += int.parse(parts[i]) * (60 ^ ...)` — el
// operador `^` es XOR bit a bit, no exponente. Cualquier duración en formato
// HH:MM:SS se calcula incorrectamente.

import 'package:flutter_test/flutter_test.dart';
import 'package:neom_core/domain/model/external_item.dart';
import 'package:neom_core/utils/enums/external_media_source.dart';
import 'package:neom_core/utils/enums/media_item_type.dart';

void main() {
  group('ExternalItem — defaults', () {
    test('constructor sin params', () {
      final e = ExternalItem();
      expect(e.id, '');
      expect(e.album, '');
      expect(e.ownerName, '');
      expect(e.duration, 0);
      expect(e.imgUrl, '');
      expect(e.url, '');
      expect(e.permaUrl, '');
      expect(e.releaseDate, 0);
      expect(e.lyrics, '');
      expect(e.is320Kbps, isFalse);
      expect(e.likes, 0);
      expect(e.state, 0);
      expect(e.source, ExternalSource.unknown);
    });
  });

  group('ExternalItem — fromJSON happy path', () {
    test('parsea campos básicos', () {
      final e = ExternalItem.fromJSON({
        'id': 'sp_1',
        'name': 'Track',
        'album': 'Album',
        'duration': 240,
        'type': 'song',
        'source': 'unknown',
      });
      expect(e.id, 'sp_1');
      expect(e.name, 'Track');
      expect(e.album, 'Album');
      expect(e.duration, 240);
    });

    test('duration como int simple', () {
      final e = ExternalItem.fromJSON({
        'duration': 180,
      });
      expect(e.duration, 180);
    });
  });

  group('ExternalItem — NC-46: parser de duración HH:MM:SS', () {
    test('NC-46: 0:30 (30 seg) → 30 segundos', () {
      // Cálculo correcto: 0*60 + 30*1 = 30
      // Cálculo bug:    0*(60^1) + 30*(60^0) = 0*61 + 30*60 = 1800
      // dur arranca en 30, así que: 30 + bug
      final e = ExternalItem.fromJSON({'duration': '0:30'});
      // Post-fix: 0*60 + 30 = 30 segundos (correcto).
      expect(e.duration, 30);
    });

    test('NC-46 FIXED: 1:00:00 = 3600 segundos (1 hora)', () {
      final e = ExternalItem.fromJSON({'duration': '1:00:00'});
      expect(e.duration, 3600);
    });

    test('NC-46 FIXED: 0:00:30 = 30 segundos', () {
      final e = ExternalItem.fromJSON({'duration': '0:00:30'});
      expect(e.duration, 30);
    });

    test('NC-46 FIXED: 1:30:45 = 5445 segundos', () {
      final e = ExternalItem.fromJSON({'duration': '1:30:45'});
      expect(e.duration, 1 * 3600 + 30 * 60 + 45);
    });

    test('NC-46 FIXED: parts inválidos no rompen', () {
      final e = ExternalItem.fromJSON({'duration': 'X:30'});
      expect(e.duration, 30);
    });
  });

  group('ExternalItem — toJSON / round-trip', () {
    test('toJSON contiene campos esenciales', () {
      final e = ExternalItem(
        id: 'e1', name: 'Song', album: 'Album',
        duration: 240, source: ExternalSource.unknown,
      );
      final json = e.toJSON();
      expect(json['id'], 'e1');
      expect(json['name'], 'Song');
      expect(json['album'], 'Album');
      expect(json['duration'], 240);
      expect(json['source'], 'unknown');
    });

    test('source serializa como string', () {
      final e = ExternalItem(source: ExternalSource.unknown);
      expect(e.toJSON()['source'], 'unknown');
    });

    test('type serializa como .value', () {
      final e = ExternalItem(type: MediaItemType.song);
      expect(e.toJSON()['type'], 'song');
    });

    test('round-trip preserva campos básicos', () {
      final original = ExternalItem(
        id: 'e1',
        name: 'Track',
        album: 'Album X',
        duration: 240,
        source: ExternalSource.unknown,
        type: MediaItemType.song,
        likes: 99,
        state: 3,
      );
      final restored = ExternalItem.fromJSON(original.toJSON());
      expect(restored.id, original.id);
      expect(restored.name, original.name);
      expect(restored.album, original.album);
      expect(restored.duration, original.duration);
      expect(restored.source, original.source);
      expect(restored.type, original.type);
      expect(restored.likes, original.likes);
      expect(restored.state, original.state);
    });
  });
}
