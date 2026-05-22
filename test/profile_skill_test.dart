// Tests for `ProfileSkill`.
//
// Posibles bugs:
// - NC-27: toJSON `'id': name` y fromJSON `id = data['name']` — mismo patrón
//   NC-04/NC-18/NC-20: id contaminado por name tras round-trip.

import 'package:flutter_test/flutter_test.dart';
import 'package:neom_core/domain/model/profile_skill.dart';
import 'package:neom_core/utils/enums/experience_level.dart';

void main() {
  group('ProfileSkill — defaults', () {
    test('constructor sin params', () {
      final s = ProfileSkill();
      expect(s.id, '');
      expect(s.name, '');
      expect(s.description, '');
      expect(s.experienceLevel, ExperienceLevel.beginner);
      expect(s.price, 0);
    });
  });

  group('ProfileSkill.addBasic', () {
    test('factory mínimo asigna id = name', () {
      final s = ProfileSkill.addBasic('Mixing');
      expect(s.id, 'Mixing');
      expect(s.name, 'Mixing');
      expect(s.experienceLevel, ExperienceLevel.beginner);
      expect(s.price, 0);
    });
  });

  group('ProfileSkill.fromJsonDefault', () {
    test('hidrata desde {name, description}', () {
      final s = ProfileSkill.fromJsonDefault({
        'name': 'Mixing',
        'description': 'Audio mixing',
      });
      expect(s.id, 'Mixing');
      expect(s.name, 'Mixing');
      expect(s.description, 'Audio mixing');
    });

    test('campos null usan defaults', () {
      final s = ProfileSkill.fromJsonDefault({});
      expect(s.id, '');
      expect(s.name, '');
      expect(s.description, '');
    });
  });

  group('ProfileSkill — fromJSON / toJSON (puede revelar NC-27)', () {
    test('NC-27: id distinto de name debería preservarse tras round-trip', () {
      // Bug: toJSON `'id': name` y fromJSON `id = data['name']` ⇒ id se
      // contamina con name. Mismo patrón NC-04/NC-18/NC-20.
      final original = ProfileSkill(id: 'real_id', name: 'Mixing');
      final restored = ProfileSkill.fromJSON(original.toJSON());
      expect(
        restored.id,
        original.id,
        reason: 'NC-27: ProfileSkill cruza id con name (toJSON línea 46, '
            'fromJSON línea 38). Mismo patrón ya conocido.',
      );
    });

    test('round-trip preserva campos no afectados por NC-27', () {
      final original = ProfileSkill(
        id: 'Mixing',
        name: 'Mixing',
        description: 'Audio mixing',
        experienceLevel: ExperienceLevel.beginner,
        price: 99.5,
      );
      final restored = ProfileSkill.fromJSON(original.toJSON());
      expect(restored.name, original.name);
      expect(restored.description, original.description);
      expect(restored.experienceLevel, original.experienceLevel);
      expect(restored.price, original.price);
    });

    test('price como int se convierte a double', () {
      final s = ProfileSkill.fromJSON({'name': 'X', 'price': 100});
      expect(s.price, 100.0);
    });

    test('mapa vacío usa defaults', () {
      final s = ProfileSkill.fromJSON(<String, dynamic>{});
      expect(s.name, '');
      expect(s.experienceLevel, ExperienceLevel.beginner);
      expect(s.price, 0.0);
    });
  });

  group('ProfileSkill.priceDisplay', () {
    test('price 0 produce cadena vacía', () {
      expect(ProfileSkill().priceDisplay, '');
    });

    test('price > 0 produce con \$ y sin decimales', () {
      expect(ProfileSkill(price: 100).priceDisplay, '\$100');
      expect(ProfileSkill(price: 99.5).priceDisplay, '\$100',
          reason: 'price.toStringAsFixed(0) redondea');
    });
  });
}
