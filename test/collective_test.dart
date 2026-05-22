// Tests for `Collective` — modelo de colectivo (banda, grupo).
//
// Cubre defaults, generateSlug, toJSON básico y revela varios bugs en
// fromJSON: photoUrl null crash (NC-14), pricePerHour null crash (NC-15),
// reviewStars null crash (NC-16).

import 'package:flutter_test/flutter_test.dart';
import 'package:neom_core/domain/model/collective.dart';
import 'package:neom_core/domain/model/price.dart';
import 'package:neom_core/utils/enums/usage_reason.dart';

void main() {
  group('Collective — defaults', () {
    test('constructor sin params', () {
      final c = Collective();
      expect(c.id, '');
      expect(c.email, '');
      expect(c.name, '');
      expect(c.description, '');
      expect(c.photoUrl, '');
      expect(c.coverImgUrl, '');
      expect(c.reason, UsageReason.any);
      expect(c.pricePerHour, isNull);
      expect(c.reviewStars, 10.0);
      expect(c.lastReview, isNull);
      expect(c.isActive, isFalse);
      expect(c.createdTime, 0);
      expect(c.lastSession, 0);
      expect(c.position, isNull);
      expect(c.isFulfilled, isFalse);
      expect(c.boardId, '');
      expect(c.slug, '');
    });
  });

  group('Collective.generateSlug', () {
    test('título simple', () {
      expect(Collective.generateSlug('The Beatles'), 'the-beatles');
    });

    test('acentos preservados', () {
      expect(Collective.generateSlug('Niño Cósmico'), 'niño-cósmico');
    });

    test('símbolos eliminados', () {
      expect(Collective.generateSlug('Bond & Co.!'), 'bond--co');
    });
  });

  group('Collective — toJSON', () {
    test('serializa reason como string (.name)', () {
      final json = Collective(reason: UsageReason.any).toJSON();
      expect(json['reason'], 'any');
    });

    test('pricePerHour null se serializa como Price() default', () {
      final json = Collective().toJSON();
      expect(json['pricePerHour'], isA<Map>());
      expect((json['pricePerHour'] as Map)['amount'], 0.0);
    });

    test('pricePerHour con valor se serializa como JSON', () {
      final p = Price(amount: 100.0);
      final json = Collective(pricePerHour: p).toJSON();
      expect((json['pricePerHour'] as Map)['amount'], 100.0);
    });
  });

  group('Collective — fromJSON (puede revelar NC-14, NC-15, NC-16)', () {
    test('round-trip con datos completos', () {
      final original = Collective(
        id: 'c1',
        email: 'c@x.com',
        name: 'Banda',
        description: 'desc',
        photoUrl: 'https://photo',
        coverImgUrl: 'https://cover',
        reason: UsageReason.any,
        pricePerHour: Price(amount: 100.0),
        reviewStars: 4.5,
        isActive: true,
        createdTime: 1700000000000,
        lastSession: 1700000001000,
        boardId: 'board1',
        slug: 'banda',
      );
      final restored = Collective.fromJSON(original.toJSON());

      expect(restored.id, original.id);
      expect(restored.email, original.email);
      expect(restored.name, original.name);
      expect(restored.description, original.description);
      expect(restored.photoUrl, original.photoUrl);
      expect(restored.coverImgUrl, original.coverImgUrl);
      expect(restored.reason, original.reason);
      expect(restored.reviewStars, original.reviewStars);
      expect(restored.isActive, original.isActive);
      expect(restored.boardId, original.boardId);
      expect(restored.slug, original.slug);
    });

    test('NC-14: fromJSON con photoUrl null no debería crashear', () {
      // Bug: `photoUrl = data["photoUrl"]` sin `?? ""` → TypeError si null.
      try {
        final c = Collective.fromJSON({
          'id': 'c1',
          'name': 'Banda',
          'photoUrl': null,
          'pricePerHour': <String, dynamic>{},
          'reviewStars': 5.0,
        });
        expect(c.photoUrl, '',
            reason: 'photoUrl null debería defaultear a ""');
      } on TypeError catch (e) {
        fail('NC-14: photoUrl null lanza TypeError. $e');
      }
    });

    test('NC-15: fromJSON con pricePerHour null no debería crashear', () {
      // Bug: `Price.fromJSON(data["pricePerHour"])` sin `?? {}` → crash si null.
      try {
        final c = Collective.fromJSON({
          'id': 'c1',
          'name': 'Banda',
          'photoUrl': 'p',
          'pricePerHour': null,
          'reviewStars': 5.0,
        });
        expect(c.pricePerHour, isNotNull);
        expect(c.pricePerHour!.amount, 0.0);
      } on Object catch (e) {
        fail('NC-15: pricePerHour null hace crash. $e');
      }
    });

    test('NC-16: fromJSON con reviewStars null no debería crashear', () {
      // Bug: `reviewStars = data["reviewStars"]` sin null check.
      try {
        final c = Collective.fromJSON({
          'id': 'c1',
          'name': 'Banda',
          'photoUrl': 'p',
          'pricePerHour': <String, dynamic>{},
          'reviewStars': null,
        });
        expect(c.reviewStars, 10.0,
            reason: 'reviewStars null debería defaultear al constructor default 10.0');
      } on TypeError catch (e) {
        fail('NC-16: reviewStars null lanza TypeError. $e');
      }
    });

    test('mapa vacío no debería crashear (combina NC-14, NC-15, NC-16)', () {
      try {
        final c = Collective.fromJSON(<String, dynamic>{});
        expect(c.id, '');
      } on Object catch (e) {
        fail('Collective.fromJSON({}) crashea: $e');
      }
    });

    test('listas null se hidratan como vacías', () {
      // Esto sí está bien (con `?.cast<String>() ?? []`)
      final c = Collective.fromJSON({
        'id': 'c1',
        'name': 'Banda',
        'photoUrl': 'p',
        'pricePerHour': <String, dynamic>{},
        'reviewStars': 5.0,
        'followers': null,
        'events': null,
      });
      expect(c.followers, isEmpty);
      expect(c.events, isEmpty);
    });
  });
}
