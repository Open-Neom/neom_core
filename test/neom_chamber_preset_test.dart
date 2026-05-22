// Tests for `NeomChamberPreset`.

import 'package:flutter_test/flutter_test.dart';
import 'package:neom_core/domain/model/neom/neom_chamber_preset.dart';
import 'package:neom_core/domain/model/neom/neom_frequency.dart';
import 'package:neom_core/domain/model/neom/neom_parameter.dart';

void main() {
  group('NeomChamberPreset — defaults', () {
    test('constructor sin params', () {
      final p = NeomChamberPreset();
      expect(p.id, '432.0_0.5_0.0_0.0_0.0');
      expect(p.name, '');
      expect(p.description, '');
      expect(p.imgUrl, '');
      expect(p.ownerId, '');
      expect(p.state, 0);
      expect(p.neomParameter, isNull);
      expect(p.mainFrequency, isNull);
      expect(p.binauralFrequency, isNull);
      expect(p.extraFrequencies, isEmpty);
    });
  });

  group('NeomChamberPreset.custom factory', () {
    test('genera id con prefijo customPreset + frequency', () {
      final p = NeomChamberPreset.custom(
        frequency: NeomFrequency(frequency: 528),
      );
      expect(p.id, contains('528'));
      expect(p.state, 5);
    });

    test('imgUrl default si imgUrl vacío', () {
      final p = NeomChamberPreset.custom(imgUrl: '');
      expect(p.imgUrl, contains('Cyberneom'));
    });

    test('imgUrl custom se respeta', () {
      final p = NeomChamberPreset.custom(imgUrl: 'https://x.com/custom.png');
      expect(p.imgUrl, 'https://x.com/custom.png');
    });
  });

  group('NeomChamberPreset — toJSON', () {
    test('toJSON contiene 10 llaves', () {
      final json = NeomChamberPreset().toJSON();
      expect(
        json.keys,
        containsAll([
          'id', 'name', 'description', 'ownerId', 'imgUrl',
          'state', 'neomParameter', 'mainFrequency',
          'binauralFrequency', 'extraFrequencies',
        ]),
      );
    });

    test('toJsonNoId NO incluye id', () {
      final json = NeomChamberPreset().toJsonNoId();
      expect(json.containsKey('id'), isFalse);
      expect(json.length, 9);
    });

    test('mainFrequency null serializa como null', () {
      expect(NeomChamberPreset().toJSON()['mainFrequency'], isNull);
    });

    test('extraFrequencies vacío serializa como []', () {
      expect(NeomChamberPreset().toJSON()['extraFrequencies'], <dynamic>[]);
    });
  });

  group('NeomChamberPreset — round-trip', () {
    test('campos básicos se preservan', () {
      final original = NeomChamberPreset(
        id: 'p1',
        name: 'Mi preset',
        description: 'desc',
        imgUrl: 'https://x',
        ownerId: 'u1',
        state: 3,
        neomParameter: NeomParameter(x: 1, y: 2, z: 3, volume: 0.7),
        mainFrequency: NeomFrequency(frequency: 432),
        binauralFrequency: NeomFrequency(frequency: 528),
        extraFrequencies: [
          NeomFrequency(frequency: 396),
          NeomFrequency(frequency: 639),
        ],
      );
      final restored = NeomChamberPreset.fromJSON(original.toJSON());
      expect(restored.id, original.id);
      expect(restored.name, original.name);
      expect(restored.description, original.description);
      expect(restored.imgUrl, original.imgUrl);
      expect(restored.ownerId, original.ownerId);
      expect(restored.state, original.state);
      expect(restored.neomParameter?.x, original.neomParameter?.x);
      expect(restored.mainFrequency?.frequency, original.mainFrequency?.frequency);
      expect(restored.binauralFrequency?.frequency, original.binauralFrequency?.frequency);
      expect(restored.extraFrequencies.length, original.extraFrequencies.length);
    });

    test('mapa vacío produce defaults sin crashear', () {
      // Hace falta que NeomFrequency.fromJSON con map vacío también funcione,
      // pero NeomChamberPreset usa NeomParameter().toJSON() como fallback,
      // así que neomParameter siempre se hidrata.
      final p = NeomChamberPreset.fromJSON(<String, dynamic>{});
      expect(p.id, '');
      expect(p.state, 0);
      expect(p.mainFrequency, isNull);
      expect(p.binauralFrequency, isNull);
      expect(p.extraFrequencies, isEmpty);
      expect(p.neomParameter, isNotNull);
    });

    test('extraFrequencies null se hidrata como vacío', () {
      final p = NeomChamberPreset.fromJSON({'extraFrequencies': null});
      expect(p.extraFrequencies, isEmpty);
    });
  });

  group('NeomChamberPreset.clone', () {
    test('clona via toJSON+fromJSON', () {
      final original = NeomChamberPreset(
        name: 'X', state: 4,
        mainFrequency: NeomFrequency(frequency: 432),
      );
      final cloned = original.clone();
      expect(cloned.name, original.name);
      expect(cloned.state, original.state);
      expect(cloned.mainFrequency?.frequency, original.mainFrequency?.frequency);
      expect(identical(cloned, original), isFalse);
    });
  });
}
