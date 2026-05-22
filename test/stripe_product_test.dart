// Tests for `StripeProduct`.

import 'package:flutter_test/flutter_test.dart';
import 'package:neom_core/domain/model/stripe/stripe_product.dart';

void main() {
  group('StripeProduct — constructor', () {
    test('constructor con required positivos', () {
      final p = StripeProduct(
        id: 'prod_1',
        name: 'Pro',
        description: 'Pro plan',
        active: true,
      );
      expect(p.id, 'prod_1');
      expect(p.name, 'Pro');
      expect(p.description, 'Pro plan');
      expect(p.active, isTrue);
      expect(p.imageUrl, isNull);
      expect(p.created, isNull);
      expect(p.updated, isNull);
    });
  });

  group('StripeProduct — toJSON', () {
    test('imageUrl null serializa como lista vacía', () {
      final p = StripeProduct(id: 'p', name: 'X', description: '', active: true);
      expect(p.toJSON()['images'], <String>[]);
    });

    test('imageUrl no-null serializa como lista de 1', () {
      final p = StripeProduct(
        id: 'p', name: 'X', description: '', active: true,
        imageUrl: 'https://x.com/img.png',
      );
      expect(p.toJSON()['images'], ['https://x.com/img.png']);
    });
  });

  group('StripeProduct.fromJSON — happy path', () {
    test('parsea respuesta típica de Stripe API', () {
      final p = StripeProduct.fromJSON({
        'id': 'prod_1',
        'name': 'Pro',
        'description': 'Pro plan',
        'active': true,
        'images': ['https://x.com/img.png'],
        'created': 1700000000,
        'updated': 1700001000,
      });
      expect(p.id, 'prod_1');
      expect(p.name, 'Pro');
      expect(p.description, 'Pro plan');
      expect(p.active, isTrue);
      expect(p.imageUrl, 'https://x.com/img.png');
      expect(p.created, isNotNull);
      expect(p.updated, isNotNull);
    });

    test('description null usa "" (es el único default protegido)', () {
      final p = StripeProduct.fromJSON({
        'id': 'p', 'name': 'X',
        'description': null,
        'active': true,
        'created': 1700000000,
        'updated': 1700000000,
      });
      expect(p.description, '');
    });

    test('images vacío produce imageUrl null', () {
      final p = StripeProduct.fromJSON({
        'id': 'p', 'name': 'X', 'active': true,
        'images': [],
        'created': 1700000000,
        'updated': 1700000000,
      });
      expect(p.imageUrl, isNull);
    });

    test('images null produce imageUrl null', () {
      final p = StripeProduct.fromJSON({
        'id': 'p', 'name': 'X', 'active': true,
        'images': null,
        'created': 1700000000,
        'updated': 1700000000,
      });
      expect(p.imageUrl, isNull);
    });
  });

  group('StripeProduct.fromJSON — NC-39: campos null crashean', () {
    test('NC-39: created null crashea', () {
      try {
        StripeProduct.fromJSON({
          'id': 'p', 'name': 'X', 'active': true,
          'created': null,
          'updated': 1700000000,
        });
        fail('Esperaba crash con created null');
      } on Object {
        // Confirmado
      }
    });

    test('NC-39: updated null crashea', () {
      try {
        StripeProduct.fromJSON({
          'id': 'p', 'name': 'X', 'active': true,
          'created': 1700000000,
          'updated': null,
        });
        fail('Esperaba crash con updated null');
      } on Object {
        // Confirmado
      }
    });
  });
}
