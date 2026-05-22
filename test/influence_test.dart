// Tests for `Influence` — modelo trivial.

import 'package:flutter_test/flutter_test.dart';
import 'package:neom_core/domain/model/influence.dart';

void main() {
  group('Influence — defaults', () {
    test('constructor sin params', () {
      final i = Influence();
      expect(i.id, '');
      expect(i.name, '');
      expect(i.thumbnailUrl, '');
    });

    test('parámetros nombrados', () {
      final i = Influence(id: 'i1', name: 'Bach', thumbnailUrl: 'https://x');
      expect(i.id, 'i1');
      expect(i.name, 'Bach');
      expect(i.thumbnailUrl, 'https://x');
    });
  });

  group('Influence — round-trip', () {
    test('preserva todos los campos', () {
      final original = Influence(id: 'i1', name: 'Bach', thumbnailUrl: 'https://x');
      final restored = Influence.fromJSON(original.toJSON());
      expect(restored.id, original.id);
      expect(restored.name, original.name);
      expect(restored.thumbnailUrl, original.thumbnailUrl);
    });

    test('mapa vacío produce defaults', () {
      final i = Influence.fromJSON(<String, dynamic>{});
      expect(i.id, '');
      expect(i.name, '');
      expect(i.thumbnailUrl, '');
    });

    test('toJSON contiene 3 llaves', () {
      expect(Influence().toJSON().length, 3);
    });
  });

  group('Influence.toString', () {
    test('contiene id y name', () {
      final i = Influence(id: 'i1', name: 'X');
      expect(i.toString(), contains('i1'));
      expect(i.toString(), contains('X'));
    });
  });
}
