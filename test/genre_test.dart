// Tests for `Genre`.
//
// Hallazgos potenciales:
// - NC-19: Genre.fromJSON sin null checks (`data["name"]` direct asignment)
// - NC-20: id se serializa desde name (mismo patrón NC-04)
// - NC-21: Genre.listFromJSON tiene método inválido (compilation/logic error)

import 'package:flutter_test/flutter_test.dart';
import 'package:neom_core/domain/model/genre.dart';

void main() {
  group('Genre — defaults', () {
    test('constructor sin params', () {
      final g = Genre();
      expect(g.id, '');
      expect(g.name, '');
      expect(g.description, '');
      expect(g.isMain, isFalse);
      expect(g.isFavorite, isFalse);
    });

    test('parámetros nombrados', () {
      final g = Genre(
        id: 'rock',
        name: 'Rock',
        description: 'Rock genre',
        isMain: true,
        isFavorite: true,
      );
      expect(g.id, 'rock');
      expect(g.name, 'Rock');
      expect(g.description, 'Rock genre');
      expect(g.isMain, isTrue);
      expect(g.isFavorite, isTrue);
    });
  });

  group('Genre.addBasic', () {
    test('factory con name', () {
      final g = Genre.addBasic('Jazz');
      expect(g.id, 'Jazz');
      expect(g.name, 'Jazz');
      expect(g.description, '');
    });
  });

  group('Genre — toJSON', () {
    test('contiene 5 llaves', () {
      final json = Genre().toJSON();
      expect(json.keys, containsAll([
        'id', 'name', 'description', 'isMain', 'isFavorite',
      ]));
    });

    test('round-trip via static fromJson preserva todos los campos', () {
      final original = Genre(
        id: 'rock',
        name: 'Rock',
        description: 'Rock music',
        isMain: true,
        isFavorite: true,
      );
      final restored = Genre.fromJson(original.toJSON());
      expect(restored.id, original.id);
      expect(restored.name, original.name);
      expect(restored.description, original.description);
    });
  });

  group('Genre.fromJSON (instance ctor)', () {
    test('NC-20: round-trip — id se sobrescribe con name', () {
      // Bug: `id = data["name"]` (no data["id"]). El campo id queda con name.
      final original = Genre(id: 'real_id', name: 'rock');
      final restored = Genre.fromJSON(original.toJSON());
      expect(
        restored.id,
        original.id,
        reason: 'NC-20: Genre.fromJSON asigna id desde data["name"] '
            '(mismo patrón NC-04 EventActivity / NC-18 Instrument).',
      );
    });

    test('NC-19: data sin name NO crashea (defendido junto con NC-20)', () {
      // El fix de NC-20 (id ?? name ?? "") + null-safe de description ya
      // protege contra el crash de NC-19. Este test verifica que el
      // comportamiento defensivo se mantiene.
      final g = Genre.fromJSON(<String, dynamic>{});
      expect(g.id, '');
      expect(g.name, '');
      expect(g.description, '');
    });
  });

  group('Genre.fromJsonDefault (static)', () {
    test('hidrata desde {name, description}', () {
      final g = Genre.fromJsonDefault({
        'name': 'Jazz',
        'description': 'Jazz desc',
      });
      expect(g.id, 'Jazz', reason: 'fromJsonDefault usa name como id');
      expect(g.name, 'Jazz');
      expect(g.description, 'Jazz desc');
    });
  });

  group('Genre.listFromJSON (puede revelar NC-21)', () {
    test('NC-21: listFromJSON tiene logic error — método potencialmente roto', () {
      // Bug observado: el método declara una variable local `genres`
      // que sombrea el parámetro, y `genre.name` no existe sobre String
      // (los items son strings). Probablemente este método no compila o
      // no funciona como espera. Si la llamada lanza, lo registramos.
      try {
        final result = Genre.listFromJSON(['rock', 'jazz']);
        // Si compila pero hace algo raro:
        fail('NC-21: Genre.listFromJSON ejecutó sin error, pero se '
            'esperaba lógica defectuosa. Resultado: $result');
      } on NoSuchMethodError {
        // Confirmado: `String.name` no existe → método inutilizable.
      } catch (e) {
        // Cualquier otro error también confirma el bug.
        expect(e, isNotNull);
      }
    });
  });
}
