// Tests for Price and SubscriptionPlan domain models.
// These map directly to Stripe data — small parsing bugs equal real money lost.
import 'package:flutter_test/flutter_test.dart';
import 'package:neom_core/domain/model/price.dart';
import 'package:neom_core/domain/model/subscription_plan.dart';
import 'package:neom_core/utils/enums/app_currency.dart';
import 'package:neom_core/utils/enums/subscription_level.dart';

void main() {
  group('Price.toJSON / fromJSON', () {
    test('round-trip preserves amount and currency', () {
      final p = Price(amount: 9.99, currency: AppCurrency.usd);
      final json = p.toJSON();
      final r = Price.fromJSON(json);
      expect(r.amount, 9.99);
      expect(r.currency, AppCurrency.usd);
    });

    test('parses integer amount as double', () {
      final r = Price.fromJSON({'amount': 5, 'currency': 'eur'});
      expect(r.amount, 5.0);
      expect(r.currency, AppCurrency.eur);
    });

    test('parses string amount via double.parse', () {
      final r = Price.fromJSON({'amount': '12.50', 'currency': 'gbp'});
      expect(r.amount, 12.5);
      expect(r.currency, AppCurrency.gbp);
    });

    test('null amount falls back to 0', () {
      final r = Price.fromJSON({'amount': null, 'currency': 'usd'});
      expect(r.amount, 0.0);
    });

    test('null currency falls back to appCoin', () {
      final r = Price.fromJSON({'amount': 1.0, 'currency': null});
      expect(r.currency, AppCurrency.appCoin);
    });

    test('zero amount is preserved', () {
      final p = Price(amount: 0.0, currency: AppCurrency.mxn);
      expect(Price.fromJSON(p.toJSON()).amount, 0.0);
    });

    test('large precision is preserved through round-trip', () {
      final p = Price(amount: 1234.567890, currency: AppCurrency.eur);
      final r = Price.fromJSON(p.toJSON());
      // Floating-point: must be near original.
      expect(r.amount, closeTo(1234.567890, 1e-9));
    });
  });

  group('SubscriptionPlan', () {
    test('isFounderPlan true when founderTier non-empty', () {
      final p = SubscriptionPlan(founderTier: 'obsidiana');
      expect(p.isFounderPlan, isTrue);
    });

    test('isFounderPlan false when founderTier empty', () {
      final p = SubscriptionPlan();
      expect(p.isFounderPlan, isFalse);
    });

    test('JSON round-trip preserves level, prices, founder seats', () {
      final original = SubscriptionPlan(
        id: 'plan_x',
        name: 'Pro Plan',
        productId: 'prod_123',
        priceId: 'price_m_123',
        priceIdYearly: 'price_y_123',
        level: SubscriptionLevel.creator,
        price: Price(amount: 9.99, currency: AppCurrency.usd),
        priceYearly: Price(amount: 99.0, currency: AppCurrency.usd),
        discount: 0.15,
        founderTier: 'cuarzo',
        founderSeatsTotal: 100,
        founderSeatsRemaining: 42,
      );
      final json = original.toJSON();
      final r = SubscriptionPlan.fromJSON(json);

      expect(r.id, original.id);
      expect(r.name, original.name);
      expect(r.productId, original.productId);
      expect(r.priceId, original.priceId);
      expect(r.priceIdYearly, original.priceIdYearly);
      expect(r.level, SubscriptionLevel.creator);
      expect(r.price?.amount, 9.99);
      expect(r.price?.currency, AppCurrency.usd);
      expect(r.priceYearly?.amount, 99.0);
      expect(r.discount, 0.15);
      expect(r.founderTier, 'cuarzo');
      expect(r.founderSeatsTotal, 100);
      expect(r.founderSeatsRemaining, 42);
      expect(r.isFounderPlan, isTrue);
    });

    test('fromJSON with missing level falls back to basic', () {
      final r = SubscriptionPlan.fromJSON(<String, dynamic>{
        'id': 'p',
        'name': 'n',
      });
      expect(r.level, SubscriptionLevel.basic);
    });

    test('fromJSON with missing prices keeps them null', () {
      final r = SubscriptionPlan.fromJSON(<String, dynamic>{
        'id': 'p',
        'name': 'n',
      });
      expect(r.price, isNull);
      expect(r.priceYearly, isNull);
    });

    test('fromJSON parses founderSeats as int from string', () {
      final r = SubscriptionPlan.fromJSON({
        'id': 'p',
        'founderSeatsTotal': '50',
        'founderSeatsRemaining': '12',
      });
      expect(r.founderSeatsTotal, 50);
      expect(r.founderSeatsRemaining, 12);
    });

    test('fromJSON discount as int parses to double', () {
      final r = SubscriptionPlan.fromJSON({'id': 'p', 'discount': 25});
      expect(r.discount, 25.0);
    });

    test('fromJSON parses lastUpdated ISO 8601', () {
      final r = SubscriptionPlan.fromJSON({
        'id': 'p',
        'lastUpdated': '2024-01-15T10:30:00.000Z',
      });
      expect(r.lastUpdated, isNotNull);
      expect(r.lastUpdated!.year, 2024);
      expect(r.lastUpdated!.month, 1);
      expect(r.lastUpdated!.day, 15);
    });
  });
}
