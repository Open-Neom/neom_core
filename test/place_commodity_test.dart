// Tests for `PlaceCommodity`.

import 'package:flutter_test/flutter_test.dart';
import 'package:neom_core/domain/model/place_commodity.dart';

void main() {
  group('PlaceCommodity — defaults del constructor', () {
    test('defaults privacidad-conservadores', () {
      final c = PlaceCommodity();
      // Comodidades amigables por default: wifi, parking, audioEquipment,
      // publicBathroom, sharedPlace.
      expect(c.wifi, isTrue);
      expect(c.parking, isTrue);
      expect(c.audioEquipment, isTrue);
      expect(c.publicBathroom, isTrue);
      expect(c.sharedPlace, isTrue);
      // Defaults conservadores: nada de allowance/private si no se pide.
      expect(c.roomService, isFalse);
      expect(c.musicalInstruments, isFalse);
      expect(c.acousticConditioning, isFalse);
      expect(c.childAllowance, isFalse);
      expect(c.smokingAllowance, isFalse);
      expect(c.smokeDetector, isFalse);
      expect(c.privateBathroom, isFalse);
    });
  });

  group('PlaceCommodity — round-trip', () {
    test('preserva todos los flags', () {
      final original = PlaceCommodity(
        wifi: false,
        parking: false,
        roomService: true,
        smokingAllowance: true,
      );
      final restored = PlaceCommodity.fromJSON(original.toJSON());
      expect(restored.wifi, isFalse);
      expect(restored.parking, isFalse);
      expect(restored.roomService, isTrue);
      expect(restored.smokingAllowance, isTrue);
    });

    test('OBS: defaults de fromJSON son TODOS true (asimetría con constructor)', () {
      // Documentación: el constructor tiene 7 defaults true y 5 false.
      // fromJSON con map vacío hidrata TODO como true. Inconsistencia
      // documentada. Especialmente preocupante: smokingAllowance default
      // true en fromJSON significa que un Place legacy sin info se asume
      // "permite fumar".
      final c = PlaceCommodity.fromJSON(<String, dynamic>{});
      expect(c.wifi, isTrue);
      expect(c.parking, isTrue);
      expect(c.roomService, isTrue,
          reason: 'fromJSON default true (constructor false) — inconsistencia');
      expect(c.smokingAllowance, isTrue,
          reason: 'fromJSON default true: fumar permitido si campo ausente');
      expect(c.privateBathroom, isTrue);
    });

    test('toJSON contiene 12 llaves', () {
      expect(PlaceCommodity().toJSON().length, 12);
    });
  });
}
