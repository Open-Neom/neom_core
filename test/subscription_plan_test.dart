// Tests for `SubscriptionPlan`.

import 'package:flutter_test/flutter_test.dart';
import 'package:neom_core/domain/model/subscription_plan.dart';
import 'package:neom_core/utils/enums/subscription_level.dart';

void main() {
  group('SubscriptionPlan — defaults', () {
    test('constructor sin params', () {
      final p = SubscriptionPlan();
      expect(p.id, '');
      expect(p.name, '');
      expect(p.imgUrl, '');
      expect(p.href, '');
      expect(p.productId, '');
      expect(p.priceId, '');
      expect(p.priceIdYearly, '');
      expect(p.level, isNull);
      expect(p.isActive, isTrue);
      expect(p.isLive, isTrue);
      expect(p.price, isNull);
      expect(p.priceYearly, isNull);
      expect(p.discount, 0.0);
      expect(p.lastUpdated, isNull);
      expect(p.founderTier, '');
      expect(p.founderSeatsTotal, 0);
      expect(p.founderSeatsRemaining, 0);
    });
  });

  group('SubscriptionPlan.isFounderPlan', () {
    test('true cuando founderTier no está vacío', () {
      expect(SubscriptionPlan(founderTier: 'obsidiana').isFounderPlan, isTrue);
      expect(SubscriptionPlan(founderTier: 'cuarzo').isFounderPlan, isTrue);
    });

    test('false cuando founderTier es vacío', () {
      expect(SubscriptionPlan().isFounderPlan, isFalse);
    });
  });

  group('SubscriptionPlan — toJSON', () {
    test('contiene 17 llaves esperadas', () {
      final json = SubscriptionPlan().toJSON();
      expect(
        json.keys,
        containsAll([
          'id', 'name', 'imgUrl', 'href',
          'productId', 'priceId', 'priceIdYearly',
          'level', 'price', 'priceYearly',
          'isActive', 'isLive', 'discount', 'lastUpdated',
          'founderTier', 'founderSeatsTotal', 'founderSeatsRemaining',
        ]),
      );
    });

    test('level null serializa como null', () {
      expect(SubscriptionPlan().toJSON()['level'], isNull);
    });

    test('level no-null serializa como string', () {
      final json = SubscriptionPlan(level: SubscriptionLevel.basic).toJSON();
      expect(json['level'], 'basic');
    });

    test('lastUpdated DateTime se serializa como ISO 8601', () {
      final dt = DateTime.utc(2024, 1, 15, 12, 0, 0);
      final json = SubscriptionPlan(lastUpdated: dt).toJSON();
      expect(json['lastUpdated'], '2024-01-15T12:00:00.000Z');
    });

    test('lastUpdated null serializa como null', () {
      expect(SubscriptionPlan().toJSON()['lastUpdated'], isNull);
    });
  });

  group('SubscriptionPlan — round-trip', () {
    test('campos básicos se preservan', () {
      final original = SubscriptionPlan(
        id: 'plan1',
        name: 'Pro',
        imgUrl: 'https://x',
        href: '/pro',
        productId: 'prod_123',
        priceId: 'price_monthly',
        priceIdYearly: 'price_yearly',
        level: SubscriptionLevel.basic,
        isActive: true,
        isLive: true,
        discount: 0.15,
        founderTier: 'obsidiana',
        founderSeatsTotal: 100,
        founderSeatsRemaining: 42,
      );
      final restored = SubscriptionPlan.fromJSON(original.toJSON());
      expect(restored.id, original.id);
      expect(restored.name, original.name);
      expect(restored.imgUrl, original.imgUrl);
      expect(restored.href, original.href);
      expect(restored.productId, original.productId);
      expect(restored.priceId, original.priceId);
      expect(restored.priceIdYearly, original.priceIdYearly);
      expect(restored.level, original.level);
      expect(restored.isActive, original.isActive);
      expect(restored.isLive, original.isLive);
      expect(restored.discount, original.discount);
      expect(restored.founderTier, original.founderTier);
      expect(restored.founderSeatsTotal, original.founderSeatsTotal);
      expect(restored.founderSeatsRemaining, original.founderSeatsRemaining);
    });

    test('discount como string se parsea a double', () {
      final p = SubscriptionPlan.fromJSON({'discount': '0.25'});
      expect(p.discount, 0.25);
    });

    test('discount null usa 0.0', () {
      final p = SubscriptionPlan.fromJSON({'discount': null});
      expect(p.discount, 0.0);
    });

    test('founderSeatsTotal como string se parsea a int', () {
      final p = SubscriptionPlan.fromJSON({'founderSeatsTotal': '50'});
      expect(p.founderSeatsTotal, 50);
    });

    test('founderSeatsTotal con valor inválido cae a 0', () {
      final p = SubscriptionPlan.fromJSON({'founderSeatsTotal': 'not_a_number'});
      expect(p.founderSeatsTotal, 0);
    });

    test('lastUpdated ISO 8601 se parsea a DateTime', () {
      final p = SubscriptionPlan.fromJSON({
        'lastUpdated': '2024-01-15T12:00:00.000Z',
      });
      expect(p.lastUpdated, isNotNull);
      expect(p.lastUpdated!.year, 2024);
      expect(p.lastUpdated!.month, 1);
    });

    test('lastUpdated null produce null', () {
      final p = SubscriptionPlan.fromJSON({'lastUpdated': null});
      expect(p.lastUpdated, isNull);
    });

    test('mapa vacío usa defaults', () {
      final p = SubscriptionPlan.fromJSON(<String, dynamic>{});
      expect(p.id, '');
      expect(p.isActive, isTrue);
      expect(p.level, SubscriptionLevel.basic);
      expect(p.discount, 0.0);
    });

    test('level desconocido cae a basic', () {
      final p = SubscriptionPlan.fromJSON({'level': 'unknown_tier'});
      expect(p.level, SubscriptionLevel.basic);
    });
  });

  group('SubscriptionPlan — Founder programs', () {
    test('plan founder con valores válidos', () {
      final p = SubscriptionPlan(
        founderTier: 'amatista',
        founderSeatsTotal: 50,
        founderSeatsRemaining: 12,
      );
      expect(p.isFounderPlan, isTrue);
      expect(p.founderSeatsTotal - p.founderSeatsRemaining, 38,
          reason: 'asientos vendidos = total - remaining');
    });
  });
}
