// Tests for `NeomFrequency`.
//
// NC-40 esperado: toJSON `'id': frequency` cruza campos (otro caso del
// patrón ya conocido). fromJSON .toString() en null da "null" (no crashea).

import 'package:flutter_test/flutter_test.dart';
import 'package:neom_core/domain/model/neom/neom_frequency.dart';
import 'package:neom_core/utils/enums/scale_degree.dart';

void main() {
  group('NeomFrequency — defaults', () {
    test('constructor sin params', () {
      final f = NeomFrequency();
      expect(f.id, '');
      expect(f.name, '');
      expect(f.description, '');
      expect(f.frequency, 345);
      expect(f.scaleDegree, ScaleDegree.tonic);
      expect(f.isRoot, isFalse);
      expect(f.isMain, isFalse);
      expect(f.isFav, isFalse);
    });
  });

  group('NeomFrequency — toJSON (puede revelar NC-40)', () {
    test('NC-40 FIXED: toJSON serializa el campo `id` correctamente', () {
      // Pre-fix: línea 36 ponía `frequency` en la llave `id`. Ahora corregido.
      final f = NeomFrequency(id: 'real_id', frequency: 432);
      final json = f.toJSON();
      expect(json['id'], 'real_id');
      // frequency también está en su propia llave
      expect(json['frequency'], 432);
    });

    test('scaleDegree serializa con EnumToString.convertToString', () {
      final f = NeomFrequency(scaleDegree: ScaleDegree.tonic);
      expect(f.toJSON()['scaleDegree'], 'tonic');
    });
  });

  group('NeomFrequency.fromJSON', () {
    test('round-trip de campos básicos', () {
      final original = NeomFrequency(
        id: '432',
        name: 'A4',
        description: 'Tuning estándar',
        frequency: 432,
        scaleDegree: ScaleDegree.tonic,
        isRoot: true,
        isMain: true,
        isFav: true,
      );
      // El id post-round-trip será frequency.toString() por NC-40.
      final restored = NeomFrequency.fromJSON(original.toJSON());
      expect(restored.frequency, original.frequency);
      expect(restored.name, original.name);
      expect(restored.scaleDegree, original.scaleDegree);
      expect(restored.isRoot, original.isRoot);
      expect(restored.isMain, original.isMain);
      expect(restored.isFav, original.isFav);
    });

    test('frequency como string numérico se parsea', () {
      final f = NeomFrequency.fromJSON({
        'id': '1',
        'frequency': '440',
      });
      expect(f.frequency, 440.0);
    });

    test('scaleDegree desconocido cae a tonic', () {
      final f = NeomFrequency.fromJSON({
        'id': '1',
        'frequency': '1',
        'scaleDegree': 'unknown',
      });
      expect(f.scaleDegree, ScaleDegree.tonic);
    });
  });

  group('NeomFrequency.copyWith', () {
    test('sin overrides devuelve copia idéntica en valores', () {
      final original = NeomFrequency(
        id: 'f1', name: 'A', frequency: 432, isFav: true,
      );
      final copy = original.copyWith();
      expect(copy.id, original.id);
      expect(copy.name, original.name);
      expect(copy.frequency, original.frequency);
      expect(copy.isFav, original.isFav);
    });

    test('overrides cambian solo los campos especificados', () {
      final original = NeomFrequency(name: 'A', frequency: 432);
      final copy = original.copyWith(frequency: 528, isFav: true);
      expect(copy.name, 'A');
      expect(copy.frequency, 528);
      expect(copy.isFav, isTrue);
    });
  });
}
