// Tests for `AppProduct` — productos en commerce.
//
// Revela bug NC-10 potencial: toJSON sobreescribe createdTime y updatedTime
// con DateTime.now() en cada serialización. Eso significa que round-trip
// pierde el timestamp original.

import 'package:flutter_test/flutter_test.dart';
import 'package:neom_core/domain/model/app_product.dart';
import 'package:neom_core/utils/enums/product_type.dart';

void main() {
  group('AppProduct — defaults', () {
    test('constructor sin params', () {
      final p = AppProduct();
      expect(p.id, '');
      expect(p.name, '');
      expect(p.description, '');
      expect(p.type, ProductType.service);
      expect(p.regularPrice, isNull);
      expect(p.salePrice, isNull);
      expect(p.qty, 0);
      expect(p.imgUrl, '');
      expect(p.isAvailable, isTrue);
      expect(p.numberOfSales, 0);
      expect(p.reviewStars, 10.0);
      expect(p.lastReview, isNull);
      expect(p.reviewIds, isNull);
      expect(p.createdTime, 0);
      expect(p.updatedTime, 0);
      expect(p.ownerEmail, isNull);
    });
  });

  group('AppProduct.clone', () {
    test('preserva todos los campos', () {
      final original = AppProduct(
        id: 'p1',
        name: 'Producto',
        description: 'desc',
        type: ProductType.service,
        qty: 5,
        imgUrl: 'https://x',
        isAvailable: false,
        numberOfSales: 10,
        reviewStars: 4.5,
        ownerEmail: 'a@x.com',
        createdTime: 1700000000000,
      );
      final clone = AppProduct.clone(original);
      expect(clone.id, original.id);
      expect(clone.name, original.name);
      expect(clone.type, original.type);
      expect(clone.qty, original.qty);
      expect(clone.imgUrl, original.imgUrl);
      expect(clone.isAvailable, original.isAvailable);
      expect(clone.numberOfSales, original.numberOfSales);
      expect(clone.reviewStars, original.reviewStars);
      expect(clone.ownerEmail, original.ownerEmail);
      expect(clone.createdTime, original.createdTime);
    });
  });

  group('AppProduct — fromJSON', () {
    test('preserva campos básicos', () {
      final p = AppProduct.fromJSON({
        'id': 'p1',
        'name': 'Producto',
        'description': 'desc',
        'type': 'service',
        'qty': 5,
        'imgUrl': 'https://x',
        'isAvailable': false,
        'numberOfSales': 10,
        'reviewStars': 4.5,
        'createdTime': 1700000000000,
        'updatedTime': 1700000001000,
        'ownerEmail': 'a@x.com',
      });
      expect(p.id, 'p1');
      expect(p.name, 'Producto');
      expect(p.type, ProductType.service);
      expect(p.qty, 5);
      expect(p.isAvailable, isFalse);
      expect(p.numberOfSales, 10);
      expect(p.reviewStars, 4.5);
      expect(p.createdTime, 1700000000000);
      expect(p.updatedTime, 1700000001000);
      expect(p.ownerEmail, 'a@x.com');
    });

    test('mapa vacío usa defaults', () {
      final p = AppProduct.fromJSON(<String, dynamic>{});
      expect(p.id, '');
      expect(p.type, ProductType.service);
      expect(p.isAvailable, isTrue);
      expect(p.reviewStars, 10.0);
    });

    test('reviewStars int se convierte a double', () {
      final p = AppProduct.fromJSON({'reviewStars': 5});
      expect(p.reviewStars, 5.0);
      expect(p.reviewStars, isA<double>());
    });
  });

  group('AppProduct — toJSON (puede revelar NC-10)', () {
    test('serializa type como string', () {
      expect(AppProduct(type: ProductType.service).toJSON()['type'], 'service');
    });

    test('NC-10: createdTime debería preservarse, NO sobrescribirse con now()', () {
      // Bug: toJSON ignora `this.createdTime` y siempre escribe DateTime.now().
      // Esto rompe round-trip y el "fecha de creación" se renueva en cada save.
      final original = AppProduct(createdTime: 1700000000000);
      final json = original.toJSON();
      expect(
        json['createdTime'],
        1700000000000,
        reason: 'NC-10: toJSON sobrescribe createdTime con DateTime.now() — '
            'rompe el campo "fecha de creación" en cada serialización.',
      );
    });

    test('NC-10: updatedTime tras toJSON debería respetar el campo del modelo', () {
      // Si el caller setea updatedTime manualmente, toJSON lo descarta y
      // pone now(). Esto puede ser intencional (auto-stamp) pero hace
      // imposible mantener un updatedTime "preservado" si el caller quiere.
      final original = AppProduct(updatedTime: 1500000000000);
      final json = original.toJSON();
      expect(
        json['updatedTime'],
        1500000000000,
        reason: 'NC-10: toJSON ignora `updatedTime` del modelo y usa now().',
      );
    });
  });
}
