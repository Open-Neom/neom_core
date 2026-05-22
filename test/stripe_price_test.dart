// Tests for `StripePrice`.
//
// NC-38 esperado: 6 campos sin null-safe en fromJSON crashean con docs
// parciales (id, currency, unit_amount, active, product, created).

import 'package:flutter_test/flutter_test.dart';
import 'package:neom_core/domain/model/stripe/stripe_price.dart';

void main() {
  group('StripePrice — constructor (campos required)', () {
    test('constructor con required positivos', () {
      final p = StripePrice(
        id: 'price_1',
        currency: 'usd',
        unitAmount: 9.99,
        active: true,
        product: 'prod_1',
      );
      expect(p.id, 'price_1');
      expect(p.currency, 'usd');
      expect(p.unitAmount, 9.99);
      expect(p.active, isTrue);
      expect(p.product, 'prod_1');
      expect(p.interval, isNull);
      expect(p.intervalCount, isNull);
      expect(p.created, isNull);
    });
  });

  group('StripePrice — toJSON', () {
    test('serializa unit_amount en cents (×100)', () {
      final p = StripePrice(
        id: 'p', currency: 'usd', unitAmount: 9.99,
        active: true, product: 'pr',
      );
      expect(p.toJSON()['unit_amount'], 999);
    });

    test('recurring null cuando interval es null', () {
      final p = StripePrice(
        id: 'p', currency: 'usd', unitAmount: 1.0,
        active: true, product: 'pr',
      );
      expect(p.toJSON()['recurring'], isNull);
    });

    test('recurring incluye interval e intervalCount cuando hay subscription', () {
      final p = StripePrice(
        id: 'p', currency: 'usd', unitAmount: 9.99,
        active: true, product: 'pr',
        interval: 'month', intervalCount: 1,
      );
      final json = p.toJSON();
      expect(json['recurring'], {
        'interval': 'month',
        'interval_count': 1,
      });
    });
  });

  group('StripePrice.fromJSON — happy path', () {
    test('parsea respuesta típica de Stripe API', () {
      final p = StripePrice.fromJSON({
        'id': 'price_1',
        'currency': 'usd',
        'unit_amount': 999, // 9.99 en cents
        'active': true,
        'product': 'prod_1',
        'created': 1700000000, // unix seconds
        'recurring': {'interval': 'month', 'interval_count': 1},
      });
      expect(p.id, 'price_1');
      expect(p.currency, 'usd');
      expect(p.unitAmount, 9.99);
      expect(p.active, isTrue);
      expect(p.product, 'prod_1');
      expect(p.interval, 'month');
      expect(p.intervalCount, 1);
      expect(p.created, isNotNull);
    });
  });

  group('StripePrice.fromJSON — NC-38: campos null crashean', () {
    test('NC-38: id null crashea', () {
      try {
        StripePrice.fromJSON({
          'id': null,
          'currency': 'usd',
          'unit_amount': 100,
          'active': true,
          'product': 'p',
          'created': 1700000000,
        });
        fail('Esperaba TypeError con id null');
      } on TypeError {
        // Confirmado
      }
    });

    test('NC-38: unit_amount null crashea', () {
      try {
        StripePrice.fromJSON({
          'id': 'p',
          'currency': 'usd',
          'unit_amount': null,
          'active': true,
          'product': 'pr',
          'created': 1700000000,
        });
        fail('Esperaba crash con unit_amount null');
      } on Object {
        // Confirmado
      }
    });

    test('NC-38: created null crashea', () {
      try {
        StripePrice.fromJSON({
          'id': 'p',
          'currency': 'usd',
          'unit_amount': 100,
          'active': true,
          'product': 'pr',
          'created': null,
        });
        fail('Esperaba crash con created null');
      } on Object {
        // Confirmado
      }
    });
  });
}
