// Tests for `Hashtag`.
//
// NC-33 esperado: 3 campos sin null-coalesce en fromJSON crashean con
// docs parciales (id, postIds, createdTime).

import 'package:flutter_test/flutter_test.dart';
import 'package:neom_core/domain/model/hashtag.dart';

void main() {
  group('Hashtag — defaults', () {
    test('constructor sin params', () {
      final h = Hashtag();
      expect(h.id, '');
      expect(h.postIds, isEmpty);
      expect(h.createdTime, 0);
    });

    test('parámetros nombrados', () {
      final h = Hashtag(
        id: 'rock',
        postIds: ['p1', 'p2'],
        createdTime: 1700000000000,
      );
      expect(h.id, 'rock');
      expect(h.postIds, ['p1', 'p2']);
      expect(h.createdTime, 1700000000000);
    });
  });

  group('Hashtag — toJSON', () {
    test('contiene 3 llaves', () {
      final json = Hashtag().toJSON();
      expect(json.length, 3);
      expect(json.keys, containsAll(['id', 'postIds', 'createdTime']));
    });
  });

  group('Hashtag — round-trip (puede revelar NC-33)', () {
    test('round-trip con datos completos', () {
      final original = Hashtag(
        id: 'jazz',
        postIds: ['p1', 'p2', 'p3'],
        createdTime: 1700000000000,
      );
      final restored = Hashtag.fromJSON(original.toJSON());
      expect(restored.id, original.id);
      expect(restored.postIds, original.postIds);
      expect(restored.createdTime, original.createdTime);
    });

    test('NC-33: mapa vacío no debería crashear', () {
      // Bug: 3 campos sin `??` defaults — null crashea.
      try {
        final h = Hashtag.fromJSON(<String, dynamic>{});
        expect(h.id, '');
        expect(h.postIds, isEmpty);
        expect(h.createdTime, 0);
      } on TypeError catch (e) {
        fail('NC-33: Hashtag.fromJSON({}) crashea con TypeError: $e');
      } on NoSuchMethodError catch (e) {
        fail('NC-33: Hashtag.fromJSON({}) crashea con NoSuchMethodError: $e');
      }
    });

    test('NC-33: postIds null no debería crashear', () {
      try {
        final h = Hashtag.fromJSON({
          'id': 'rock',
          'postIds': null,
          'createdTime': 0,
        });
        expect(h.postIds, isEmpty);
      } on Object catch (e) {
        fail('NC-33: postIds null crashea: $e');
      }
    });
  });
}
