// Tests for `Facility`.
//
// Posibles bugs:
// - NC-22: fromJSON NO carga reviewStars, price, facilityCommodity, isActive,
//   isMain — quedan en class-level defaults, perdidos tras round-trip.
// - Address.fromJSON sin `?? {}` puede crashear con address null.

import 'package:flutter_test/flutter_test.dart';
import 'package:neom_core/domain/model/facility.dart';
import 'package:neom_core/domain/model/price.dart';
import 'package:neom_core/utils/enums/facilitator_type.dart';

void main() {
  group('Facility — defaults', () {
    test('constructor sin params', () {
      final f = Facility();
      expect(f.id, '');
      expect(f.name, '');
      expect(f.description, '');
      expect(f.type, FacilityType.publisher);
      expect(f.address, isNull);
      expect(f.reviewStars, 0.0);
      expect(f.price, isNull);
      expect(f.facilityCommodity, isNull);
      expect(f.isActive, isTrue);
      expect(f.isMain, isTrue);
      expect(f.galleryImgUrls, isEmpty);
      expect(f.bookings, isEmpty);
      expect(f.reviews, isEmpty);
    });
  });

  group('Facility — toJSON', () {
    test('contiene 17 llaves', () {
      final json = Facility().toJSON();
      expect(
        json.keys,
        containsAll([
          'id', 'name', 'description', 'ownerName', 'ownerId', 'ownerImgUrl',
          'type', 'address', 'position', 'reviewStars', 'price',
          'facilityCommodity', 'isActive', 'isMain', 'galleryImgUrls',
          'bookings', 'reviews',
        ]),
      );
    });

    test('type se serializa como string', () {
      expect(Facility().toJSON()['type'], 'publisher');
    });
  });

  group('Facility — fromJSON (puede revelar NC-22)', () {
    test('NC-22: round-trip de reviewStars/price/isActive/isMain/facilityCommodity', () {
      // Bug: fromJSON línea 115-127 NO hidrata estos 5 campos. Quedan en
      // class-level defaults (reviewStars=0.0, isActive=true, isMain=true,
      // price=Price(), facilityCommodity=null).
      final original = Facility(
        id: 'f1',
        name: 'Studio',
        ownerImgUrl: 'https://x',
        type: FacilityType.publisher,
        reviewStars: 4.5,
        price: Price(amount: 500),
        isActive: false,
        isMain: false,
      );
      // Provee address explícito para evitar crash en fromJSON.
      final json = {
        ...original.toJSON(),
        'address': <String, dynamic>{},
      };
      final restored = Facility.fromJSON(json);

      // Campos que SÍ se cargan
      expect(restored.id, original.id);
      expect(restored.name, original.name);
      expect(restored.type, original.type);

      // NC-22: estos NO se preservan (fromJSON no los lee)
      expect(
        restored.reviewStars,
        original.reviewStars,
        reason: 'NC-22: fromJSON NO carga reviewStars — round-trip pierde rating',
      );
    });

    test('NC-22: isActive y isMain se pierden tras round-trip', () {
      final original = Facility(
        ownerImgUrl: 'https://x',
        isActive: false,
        isMain: false,
      );
      final json = {
        ...original.toJSON(),
        'address': <String, dynamic>{},
      };
      final restored = Facility.fromJSON(json);
      expect(
        restored.isActive,
        original.isActive,
        reason: 'NC-22: fromJSON NO carga isActive — siempre queda en true',
      );
    });

    test('lista null en galleryImgUrls (cast directo) puede crashear', () {
      // Bug: línea 125 hace `data["galleryImgUrls"].cast<String>()` con `.`,
      // no `?.` — crash si la lista es null.
      try {
        final f = Facility.fromJSON({
          'ownerImgUrl': 'https://x',
          'address': <String, dynamic>{},
          'galleryImgUrls': null,
          'bookings': null,
          'reviews': null,
        });
        expect(f.galleryImgUrls, isEmpty);
      } on Object catch (e) {
        fail('Facility.fromJSON crashea con galleryImgUrls null: $e');
      }
    });
  });
}
