// Tests for `CaseteSession` — telemetría de escucha.
//
// Posible bug NC-28: línea 66 `json["subscriptionLevel"].toString()` puede
// crashear si el campo es null directo (tho `.toString()` sobre null devuelve
// "null" en Dart) — investigamos comportamiento.

import 'package:flutter_test/flutter_test.dart';
import 'package:neom_core/domain/model/casete/casete_session.dart';
import 'package:neom_core/utils/enums/subscription_level.dart';

void main() {
  group('CaseteSession — defaults', () {
    test('constructor sin params', () {
      final s = CaseteSession();
      expect(s.id, '');
      expect(s.itemId, '');
      expect(s.itemName, '');
      expect(s.ownerEmail, '');
      expect(s.listenerEmail, '');
      expect(s.casete, 0);
      expect(s.totalDuration, 0);
      expect(s.createdTime, 0);
      expect(s.subscriptionLevel, isNull);
      expect(s.isTest, isFalse);
    });
  });

  group('CaseteSession — toJSON', () {
    test('contiene 10 llaves', () {
      final json = CaseteSession().toJSON();
      expect(
        json.keys,
        containsAll([
          'id', 'itemId', 'itemName', 'ownerEmail', 'listenerEmail',
          'casete', 'totalDuration', 'createdTime', 'subscriptionLevel', 'isTest',
        ]),
      );
    });

    test('subscriptionLevel null serializa como null', () {
      expect(CaseteSession().toJSON()['subscriptionLevel'], isNull);
    });

    test('subscriptionLevel se serializa como string (.name)', () {
      final s = CaseteSession(subscriptionLevel: SubscriptionLevel.basic);
      expect(s.toJSON()['subscriptionLevel'], 'basic');
    });
  });

  group('CaseteSession — round-trip', () {
    test('preserva todos los campos', () {
      final original = CaseteSession(
        id: 'cs1',
        itemId: 'item1',
        itemName: 'Mi canción',
        ownerEmail: 'o@x.com',
        listenerEmail: 'l@x.com',
        casete: 180,
        totalDuration: 240,
        createdTime: 1700000000000,
        subscriptionLevel: SubscriptionLevel.basic,
        isTest: true,
      );
      final restored = CaseteSession.fromJSON(original.toJSON());
      expect(restored.id, original.id);
      expect(restored.itemId, original.itemId);
      expect(restored.itemName, original.itemName);
      expect(restored.ownerEmail, original.ownerEmail);
      expect(restored.listenerEmail, original.listenerEmail);
      expect(restored.casete, original.casete);
      expect(restored.totalDuration, original.totalDuration);
      expect(restored.createdTime, original.createdTime);
      expect(restored.subscriptionLevel, original.subscriptionLevel);
      expect(restored.isTest, original.isTest);
    });

    test('legacy ownerId se mapea a ownerEmail', () {
      final s = CaseteSession.fromJSON({
        'ownerId': 'legacy@x.com',
      });
      expect(s.ownerEmail, 'legacy@x.com');
    });

    test('legacy readerId se mapea a listenerEmail', () {
      final s = CaseteSession.fromJSON({
        'readerId': 'legacy_reader@x.com',
      });
      expect(s.listenerEmail, 'legacy_reader@x.com');
    });

    test('mapa vacío usa defaults', () {
      final s = CaseteSession.fromJSON(<String, dynamic>{});
      expect(s.id, '');
      expect(s.casete, 0);
      expect(s.isTest, isFalse);
      expect(s.subscriptionLevel, isNull,
          reason: 'sin subscriptionLevel devuelve null');
    });
  });
}
