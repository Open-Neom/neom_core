// Tests for `InstrumentFulfillment`.
//
// NC-34: id default es int 0 (campo es String).
// NC-35: Instrument.fromJSON nested sin `?? {}`.
// NC-36: isFulfilled default es String "" (campo es bool) — mismo NC-03.

import 'package:flutter_test/flutter_test.dart';
import 'package:neom_core/domain/model/instrument.dart';
import 'package:neom_core/domain/model/instrument_fulfillment.dart';
import 'package:neom_core/utils/enums/vocal_type.dart';

void main() {
  group('InstrumentFulfillment — defaults', () {
    test('constructor con required id + instrument', () {
      final f = InstrumentFulfillment(
        id: 'f1',
        instrument: Instrument(name: 'Guitar'),
      );
      expect(f.id, 'f1');
      expect(f.instrument.name, 'Guitar');
      expect(f.isFulfilled, isFalse);
      expect(f.profileId, '');
      expect(f.profileImgUrl, '');
      expect(f.profileName, '');
      expect(f.vocalType, VocalType.none);
    });
  });

  group('InstrumentFulfillment — toJSON', () {
    test('contiene 7 llaves', () {
      final json = InstrumentFulfillment(
        id: 'f1',
        instrument: Instrument(),
      ).toJSON();
      expect(
        json.keys,
        containsAll([
          'id', 'instrument', 'isFulfilled',
          'profileId', 'profileImgUrl', 'profileName', 'vocalType',
        ]),
      );
    });

    test('vocalType serializa como string', () {
      final f = InstrumentFulfillment(
        id: 'f1',
        instrument: Instrument(),
        vocalType: VocalType.none,
      );
      expect(f.toJSON()['vocalType'], 'none');
    });
  });

  group('InstrumentFulfillment — round-trip (puede revelar NC-34/35/36)', () {
    test('round-trip con datos completos', () {
      final original = InstrumentFulfillment(
        id: 'f1',
        instrument: Instrument(name: 'Bass', model: 'Fender'),
        isFulfilled: true,
        profileId: 'u1',
        profileImgUrl: 'https://x',
        profileName: 'Ana',
        vocalType: VocalType.none,
      );
      final restored = InstrumentFulfillment.fromJSON(original.toJSON());
      expect(restored.id, original.id);
      expect(restored.instrument.name, original.instrument.name);
      expect(restored.isFulfilled, original.isFulfilled);
      expect(restored.profileId, original.profileId);
      expect(restored.profileName, original.profileName);
      expect(restored.vocalType, original.vocalType);
    });

    test('NC-34: id null debería defaultear a "" (String, no 0)', () {
      // Bug: línea 40 `id = data["id"] ?? 0` → asigna int 0 a campo String.
      try {
        final f = InstrumentFulfillment.fromJSON({
          'id': null,
          'instrument': <String, dynamic>{},
          'isFulfilled': false,
        });
        expect(f.id, '');
      } on TypeError catch (e) {
        fail('NC-34: id null asigna 0 (int) a campo String. $e');
      }
    });

    test('NC-35: instrument null no debería crashear', () {
      // Bug: línea 41 `Instrument.fromJSON(data["instrument"])` — null crashea.
      try {
        final f = InstrumentFulfillment.fromJSON({
          'id': 'f1',
          'instrument': null,
          'isFulfilled': false,
        });
        expect(f.instrument, isA<Instrument>());
      } on Object catch (e) {
        fail('NC-35: instrument null crashea fromJSON: $e');
      }
    });

    test('NC-36: isFulfilled null debería defaultear a false (bool, no "")', () {
      // Bug: línea 42 `isFulfilled = data["isFulfilled"] ?? ""` → String→bool.
      // Mismo patrón que NC-03 (CollectiveFulfillment), NC-08 (AppRequest).
      try {
        final f = InstrumentFulfillment.fromJSON({
          'id': 'f1',
          'instrument': <String, dynamic>{},
          'isFulfilled': null,
        });
        expect(f.isFulfilled, isFalse);
      } on TypeError catch (e) {
        fail('NC-36: isFulfilled default "" lanza TypeError. $e');
      }
    });

    test('mapa vacío no debería crashear (combina NC-34/35/36)', () {
      try {
        final f = InstrumentFulfillment.fromJSON(<String, dynamic>{});
        expect(f, isA<InstrumentFulfillment>());
      } on Object catch (e) {
        fail('InstrumentFulfillment.fromJSON({}) crashea: $e');
      }
    });
  });
}
