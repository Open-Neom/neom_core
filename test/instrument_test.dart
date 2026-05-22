// Tests for `Instrument`.
//
// Posible bug NC-18: toJSON serializa `'id': name` y fromJSON asigna
// `id = data["name"]` — mismo patrón que NC-04 (EventActivity). Round-trip
// del id contamina con name.

import 'package:flutter_test/flutter_test.dart';
import 'package:neom_core/domain/model/instrument.dart';
import 'package:neom_core/utils/enums/instrument_level.dart';

void main() {
  group('Instrument — defaults', () {
    test('constructor sin params', () {
      final i = Instrument();
      expect(i.id, '');
      expect(i.name, '');
      expect(i.description, '');
      expect(i.instrumentLevel, InstrumentLevel.notDetermined);
      expect(i.model, '');
      expect(i.isMain, isFalse);
      expect(i.isFavorite, isFalse);
    });

    test('parámetros nombrados', () {
      final i = Instrument(
        id: 'i1',
        name: 'Guitarra',
        description: 'Acústica',
        instrumentLevel: InstrumentLevel.notDetermined,
        model: 'Yamaha',
        isMain: true,
        isFavorite: true,
      );
      expect(i.id, 'i1');
      expect(i.name, 'Guitarra');
      expect(i.description, 'Acústica');
      expect(i.model, 'Yamaha');
      expect(i.isMain, isTrue);
      expect(i.isFavorite, isTrue);
    });
  });

  group('Instrument.addBasic', () {
    test('factory mínimo solo con name', () {
      final i = Instrument.addBasic('Piano');
      expect(i.id, 'Piano',
          reason: 'addBasic usa name como id (por diseño)');
      expect(i.name, 'Piano');
      expect(i.isFavorite, isTrue);
      expect(i.isMain, isFalse);
    });
  });

  group('Instrument.fromJsonDefault (static)', () {
    test('hidrata desde {name, description}', () {
      final i = Instrument.fromJsonDefault({
        'name': 'Bajo',
        'description': 'Eléctrico',
      });
      expect(i.id, 'Bajo');
      expect(i.name, 'Bajo');
      expect(i.description, 'Eléctrico');
      expect(i.instrumentLevel, InstrumentLevel.notDetermined);
    });

    test('description ausente cae a ""', () {
      final i = Instrument.fromJsonDefault({'name': 'Voz'});
      expect(i.description, '');
    });
  });

  group('Instrument — toJSON', () {
    test('contiene 7 llaves', () {
      final json = Instrument().toJSON();
      expect(
        json.keys,
        containsAll([
          'id', 'name', 'description', 'instrumentLevel',
          'isMain', 'isFavorite', 'model',
        ]),
      );
    });

    test('instrumentLevel se serializa como string (.name)', () {
      final json = Instrument(
        instrumentLevel: InstrumentLevel.notDetermined,
      ).toJSON();
      expect(json['instrumentLevel'], 'notDetermined');
    });
  });

  group('Instrument — round-trip (puede revelar NC-18)', () {
    test('round-trip preserva campos', () {
      final original = Instrument(
        id: 'Piano',
        name: 'Piano',
        description: 'Vertical',
        instrumentLevel: InstrumentLevel.notDetermined,
        model: 'Steinway',
        isMain: true,
        isFavorite: true,
      );
      final restored = Instrument.fromJSON(original.toJSON());
      expect(restored.name, original.name);
      expect(restored.description, original.description);
      expect(restored.instrumentLevel, original.instrumentLevel);
      expect(restored.model, original.model);
      expect(restored.isMain, original.isMain);
      expect(restored.isFavorite, original.isFavorite);
    });

    test('NC-18: id distinto de name debería preservarse tras round-trip', () {
      // Bug: toJSON línea 46 escribe `'id': name` (no id). fromJSON línea 67
      // hace `id = data["name"]`. El campo `id` se sobrescribe con name.
      final original = Instrument(id: 'real_id', name: 'visible_name');
      final restored = Instrument.fromJSON(original.toJSON());
      expect(
        restored.id,
        original.id,
        reason: 'NC-18: toJSON serializa id desde name (mismo patrón NC-04).',
      );
    });

    test('mapa vacío usa defaults', () {
      final i = Instrument.fromJSON(<String, dynamic>{});
      expect(i.name, '');
      expect(i.instrumentLevel, InstrumentLevel.notDetermined);
    });
  });
}
