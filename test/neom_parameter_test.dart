// Tests for `NeomParameter`.
//
// NC-41 esperado: fromJSON sin defaults — TODOS los campos crashean si null.

import 'package:flutter_test/flutter_test.dart';
import 'package:neom_core/domain/model/neom/neom_parameter.dart';

void main() {
  group('NeomParameter — defaults', () {
    test('constructor sin params', () {
      final p = NeomParameter();
      expect(p.x, 0);
      expect(p.y, 0);
      expect(p.z, 0);
      expect(p.volume, 0.5);
    });

    test('parámetros nombrados', () {
      final p = NeomParameter(x: 1.5, y: -2.5, z: 0, volume: 0.8);
      expect(p.x, 1.5);
      expect(p.y, -2.5);
      expect(p.z, 0);
      expect(p.volume, 0.8);
    });
  });

  group('NeomParameter — round-trip', () {
    test('preserva todos los campos', () {
      final original = NeomParameter(x: 1.0, y: 2.0, z: 3.0, volume: 0.75);
      final restored = NeomParameter.fromJSON(original.toJSON());
      expect(restored.x, original.x);
      expect(restored.y, original.y);
      expect(restored.z, original.z);
      expect(restored.volume, original.volume);
    });

    test('toJSON contiene 4 llaves', () {
      final json = NeomParameter().toJSON();
      expect(json.keys, containsAll(['x', 'y', 'z', 'volume']));
    });
  });

  group('NeomParameter.fromJSON — NC-41 FIXED: defaults defensivos', () {
    test('x null usa 0', () {
      final p = NeomParameter.fromJSON({'x': null, 'y': 0, 'z': 0, 'volume': 0.5});
      expect(p.x, 0.0);
    });

    test('mapa vacío usa defaults del constructor', () {
      final p = NeomParameter.fromJSON(<String, dynamic>{});
      expect(p.x, 0);
      expect(p.y, 0);
      expect(p.z, 0);
      expect(p.volume, 0.5);
    });

    test('valores int se convierten a double', () {
      final p = NeomParameter.fromJSON({'x': 1, 'y': 2, 'z': 3, 'volume': 1});
      expect(p.x, 1.0);
      expect(p.volume, 1.0);
    });
  });

  group('NeomParameter.forNeomChambersCollection', () {
    test('clona los 4 campos', () {
      final source = NeomParameter(x: 1, y: 2, z: 3, volume: 0.6);
      final cloned = NeomParameter.forNeomChambersCollection(source);
      expect(cloned.x, source.x);
      expect(cloned.y, source.y);
      expect(cloned.z, source.z);
      expect(cloned.volume, source.volume);
    });
  });
}
