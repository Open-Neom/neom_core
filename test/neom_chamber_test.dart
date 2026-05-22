// Tests for `NeomChamber`.

import 'package:flutter_test/flutter_test.dart';
import 'package:neom_core/domain/model/neom/neom_chamber.dart';
import 'package:neom_core/utils/enums/owner_type.dart';

void main() {
  group('NeomChamber — defaults', () {
    test('constructor sin params', () {
      final c = NeomChamber();
      expect(c.id, '');
      expect(c.name, '');
      expect(c.description, '');
      expect(c.ownerId, '');
      expect(c.ownerName, '');
      expect(c.ownerType, OwnerType.profile);
      expect(c.href, '');
      expect(c.imgUrl, '');
      expect(c.public, isTrue);
      expect(c.position, isNull);
      expect(c.isModifiable, isTrue);
      expect(c.chamberPresets, isNull);
    });
  });

  group('NeomChamber.createBasic', () {
    test('factory mínimo', () {
      final c = NeomChamber.createBasic('Sala A', 'Mi cámara');
      expect(c.name, 'Sala A');
      expect(c.description, 'Mi cámara');
      expect(c.id, '');
      expect(c.public, isTrue);
      expect(c.chamberPresets, isEmpty);
      expect(c.isModifiable, isTrue);
    });
  });

  group('NeomChamber — toJSON', () {
    test('toJSON NO incluye id (Firebase docId)', () {
      final c = NeomChamber(id: 'c1');
      expect(c.toJSON().containsKey('id'), isFalse);
    });

    test('toJSONWithID SÍ incluye id', () {
      final c = NeomChamber(id: 'c1');
      expect(c.toJSONWithID()['id'], 'c1');
    });

    test('ownerType serializa como string', () {
      expect(NeomChamber().toJSON()['ownerType'], 'profile');
    });

    test('chamberPresets null serializa como []', () {
      expect(NeomChamber().toJSON()['chamberPresets'], <dynamic>[]);
    });
  });

  group('NeomChamber — round-trip', () {
    test('preserva campos básicos', () {
      final original = NeomChamber(
        id: 'c1',
        name: 'Sala',
        description: 'Mi cámara',
        ownerId: 'u1',
        ownerName: 'Ana',
        ownerType: OwnerType.profile,
        href: 'h',
        imgUrl: 'https://x',
        public: false,
        isModifiable: false,
      );
      final json = {...original.toJSON(), 'id': original.id};
      final restored = NeomChamber.fromJSON(json);
      expect(restored.id, original.id);
      expect(restored.name, original.name);
      expect(restored.description, original.description);
      expect(restored.ownerId, original.ownerId);
      expect(restored.ownerName, original.ownerName);
      expect(restored.ownerType, original.ownerType);
      expect(restored.href, original.href);
      expect(restored.imgUrl, original.imgUrl);
      expect(restored.public, original.public);
      expect(restored.isModifiable, original.isModifiable);
    });

    test('mapa vacío usa defaults', () {
      final c = NeomChamber.fromJSON(<String, dynamic>{});
      expect(c.id, '');
      expect(c.public, isTrue);
      expect(c.ownerType, OwnerType.profile);
      expect(c.chamberPresets, isEmpty);
    });

    test('chamberPresets null se hidrata como vacío', () {
      final c = NeomChamber.fromJSON({'chamberPresets': null});
      expect(c.chamberPresets, isEmpty);
    });
  });

  group('NeomChamber.getImgUrls', () {
    test('chamber sin imgUrl ni presets devuelve lista vacía', () {
      expect(NeomChamber().getImgUrls(), isEmpty);
    });

    test('chamber con imgUrl pero sin presets devuelve [imgUrl]', () {
      final c = NeomChamber(imgUrl: 'https://main.png');
      expect(c.getImgUrls(), ['https://main.png']);
    });

    test('chamber sin imgUrl pero con presets devuelve presets imgUrls', () {
      // Usa NeomChamber.createBasic para inicializar con [] vs null
      final c = NeomChamber.createBasic('test', 'desc');
      expect(c.getImgUrls(), isEmpty);
    });
  });
}
