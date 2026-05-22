// Tests for `PlayableItem` — interface abstracta. Testeo el getter
// `displayDuration` con un mock concreto.

import 'package:flutter_test/flutter_test.dart';
import 'package:neom_core/domain/model/playable_item.dart';
import 'package:neom_core/utils/enums/media_item_type.dart';

class _MockPlayable extends PlayableItem {
  @override
  final String id;
  @override
  final String name;
  @override
  final String? description;
  @override
  final String slug;
  @override
  final String streamUrl;
  @override
  final String imgUrl;
  @override
  final String previewUrl;
  @override
  final MediaItemType? mediaType;
  @override
  final int duration;
  @override
  final bool isAudioContent;
  @override
  final bool isBookContent;
  @override
  final String ownerName;
  @override
  final String? ownerId;
  @override
  final List<String>? categories;
  @override
  final List<String>? galleryUrls;
  @override
  final String? language;
  @override
  final int? publishedYear;
  @override
  final int state;
  @override
  final bool isInternal;

  _MockPlayable({
    this.duration = 0,
    this.isBookContent = false,
    this.isAudioContent = true,
    this.id = '',
    this.name = '',
    this.description,
    this.slug = '',
    this.streamUrl = '',
    this.imgUrl = '',
    this.previewUrl = '',
    this.mediaType,
    this.ownerName = '',
    this.ownerId,
    this.categories,
    this.galleryUrls,
    this.language,
    this.publishedYear,
    this.state = 0,
    this.isInternal = true,
  });
}

void main() {
  group('PlayableItem.displayDuration', () {
    test('isBookContent → "{n} pág."', () {
      final p = _MockPlayable(duration: 250, isBookContent: true);
      expect(p.displayDuration, '250 pág.');
    });

    test('audio: 0 segundos → "0s"', () {
      final p = _MockPlayable(duration: 0);
      expect(p.displayDuration, '0s');
    });

    test('audio: < 1 minuto → "{n}s"', () {
      expect(_MockPlayable(duration: 30).displayDuration, '30s');
      expect(_MockPlayable(duration: 59).displayDuration, '59s');
    });

    test('audio: minuto exacto → "{n}m"', () {
      expect(_MockPlayable(duration: 60).displayDuration, '1m');
      expect(_MockPlayable(duration: 120).displayDuration, '2m');
    });

    test('audio: minutos + segundos → "{m}:{ss}"', () {
      expect(_MockPlayable(duration: 90).displayDuration, '1:30');
      expect(_MockPlayable(duration: 75).displayDuration, '1:15');
    });

    test('audio: padding de segundos a 2 dígitos', () {
      // 1m 5s = 65 → "1:05"
      expect(_MockPlayable(duration: 65).displayDuration, '1:05');
      // 5m 9s = 309 → "5:09"
      expect(_MockPlayable(duration: 309).displayDuration, '5:09');
    });

    test('audio: > 1 hora se expresa en minutos totales (no h:mm)', () {
      // 1h 30m = 5400s → "90m" (no se formatea como "1h 30m")
      expect(_MockPlayable(duration: 5400).displayDuration, '90m');
    });
  });
}
