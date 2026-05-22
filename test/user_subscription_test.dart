// Tests for `UserSubscription`.

import 'package:flutter_test/flutter_test.dart';
import 'package:neom_core/domain/model/user_subscription.dart';
import 'package:neom_core/domain/model/price.dart';
import 'package:neom_core/utils/enums/cancellation_reason.dart';
import 'package:neom_core/utils/enums/subscription_level.dart';
import 'package:neom_core/utils/enums/subscription_status.dart';

void main() {
  group('UserSubscription — defaults', () {
    test('constructor sin params', () {
      final s = UserSubscription();
      expect(s.subscriptionId, '');
      expect(s.userId, '');
      expect(s.level, isNull);
      expect(s.price, isNull);
      expect(s.status, isNull);
      expect(s.startDate, 0);
      expect(s.endDate, 0);
      expect(s.endReason, isNull);
    });

    test('parámetros nombrados', () {
      final s = UserSubscription(
        subscriptionId: 'sub1',
        userId: 'u1',
        level: SubscriptionLevel.basic,
        price: Price(amount: 99),
        status: SubscriptionStatus.values.first,
        startDate: 1700000000000,
        endDate: 1700100000000,
        endReason: CancellationReason.values.first,
      );
      expect(s.subscriptionId, 'sub1');
      expect(s.userId, 'u1');
      expect(s.level, SubscriptionLevel.basic);
      expect(s.price?.amount, 99);
      expect(s.status, SubscriptionStatus.values.first);
      expect(s.startDate, 1700000000000);
      expect(s.endReason, CancellationReason.values.first);
    });
  });

  group('UserSubscription — toJSON', () {
    test('contiene 8 llaves', () {
      final json = UserSubscription().toJSON();
      expect(
        json.keys,
        containsAll([
          'subscriptionId', 'userId', 'level', 'price',
          'status', 'startDate', 'endDate', 'endReason',
        ]),
      );
    });

    test('campos opcionales null serializan como null', () {
      final json = UserSubscription().toJSON();
      expect(json['level'], isNull);
      expect(json['price'], isNull);
      expect(json['status'], isNull);
    });

    test('enums se serializan como string (.name)', () {
      final json = UserSubscription(
        level: SubscriptionLevel.basic,
      ).toJSON();
      expect(json['level'], 'basic');
    });
  });

  group('UserSubscription — round-trip', () {
    test('preserva campos básicos', () {
      final original = UserSubscription(
        subscriptionId: 'sub1',
        userId: 'u1',
        level: SubscriptionLevel.basic,
        price: Price(amount: 99),
        status: SubscriptionStatus.values.first,
        startDate: 1700000000000,
        endDate: 1700100000000,
      );
      final restored = UserSubscription.fromJSON(original.toJSON());
      expect(restored.subscriptionId, original.subscriptionId);
      expect(restored.userId, original.userId);
      expect(restored.level, original.level);
      expect(restored.price?.amount, original.price?.amount);
      expect(restored.status, original.status);
      expect(restored.startDate, original.startDate);
      expect(restored.endDate, original.endDate);
    });

    test('mapa vacío usa defaults', () {
      final s = UserSubscription.fromJSON(<String, dynamic>{});
      expect(s.subscriptionId, '');
      expect(s.userId, '');
      expect(s.level, isNull);
      expect(s.price, isNull);
      expect(s.status, isNull);
    });

    test('level desconocido devuelve null (no crashea)', () {
      final s = UserSubscription.fromJSON({'level': 'unknown_level'});
      expect(s.level, isNull);
    });
  });
}
