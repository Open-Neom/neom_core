// Tests for `Place`.
//
// Cubre defaults, toJSON estructura, round-trip evitando la dependencia
// con `AppProperties.getNoImageUrl()` (que requiere init de AppProperties).
// Para evitar tocar esa capa, todos los tests pasan ownerImgUrl explícito.

import 'package:flutter_test/flutter_test.dart';
import 'package:neom_core/domain/model/place.dart';
import 'package:neom_core/domain/model/price.dart';
import 'package:neom_core/utils/enums/place_type.dart';

void main() {
  group('Place — defaults', () {
    test('constructor sin params', () {
      final p = Place();
      expect(p.id, '');
      expect(p.name, '');
      expect(p.description, '');
      expect(p.ownerName, '');
      expect(p.ownerId, '');
      expect(p.ownerImgUrl, '');
      expect(p.type, PlaceType.publicSpace);
      expect(p.address, isNull);
      expect(p.reviewStars, 0.0);
      expect(p.isActive, isTrue,
          reason: 'constructor default isActive=true');
      expect(p.isMain, isTrue);
      expect(p.galleryImgUrls, isEmpty);
      expect(p.bookings, isEmpty);
      expect(p.reviews, isEmpty);
    });

    test('parámetros nombrados', () {
      final p = Place(
        id: 'pl1',
        name: 'Foro',
        description: 'venue',
        ownerName: 'Ana',
        ownerId: 'u1',
        ownerImgUrl: 'https://x',
        type: PlaceType.publicSpace,
        reviewStars: 4.5,
        price: Price(amount: 1000),
        isActive: false,
        isMain: false,
      );
      expect(p.id, 'pl1');
      expect(p.name, 'Foro');
      expect(p.type, PlaceType.publicSpace);
      expect(p.reviewStars, 4.5);
      expect(p.price?.amount, 1000);
      expect(p.isActive, isFalse);
      expect(p.isMain, isFalse);
    });
  });

  group('Place — toJSON', () {
    test('contiene 17 llaves principales', () {
      final json = Place().toJSON();
      expect(
        json.keys,
        containsAll([
          'id', 'name', 'description', 'ownerName', 'ownerId', 'ownerImgUrl',
          'type', 'address', 'reviewStars', 'price', 'placeCommodity',
          'position', 'isActive', 'isMain', 'galleryImgUrls', 'bookings', 'reviews',
        ]),
      );
    });

    test('type se serializa como string (.name)', () {
      expect(Place().toJSON()['type'], 'publicSpace');
    });

    test('toJSONSimple omite campos pesados', () {
      final json = Place().toJSONSimple();
      expect(json.containsKey('ownerName'), isFalse);
      expect(json.containsKey('isActive'), isFalse);
      expect(json.containsKey('bookings'), isFalse);
      // Pero sí incluye los esenciales
      expect(json.containsKey('id'), isTrue);
      expect(json.containsKey('name'), isTrue);
      expect(json.containsKey('type'), isTrue);
      expect(json.containsKey('reviews'), isTrue);
    });
  });

  group('Place — fromJSON', () {
    test('round-trip preserva campos básicos', () {
      final original = Place(
        id: 'pl1',
        name: 'Foro',
        description: 'desc',
        ownerName: 'Ana',
        ownerId: 'u1',
        ownerImgUrl: 'https://x',
        type: PlaceType.publicSpace,
        reviewStars: 4.5,
        price: Price(amount: 500),
        isActive: false,
        isMain: false,
      );
      final restored = Place.fromJSON(original.toJSON());
      expect(restored.id, original.id);
      expect(restored.name, original.name);
      expect(restored.description, original.description);
      expect(restored.ownerName, original.ownerName);
      expect(restored.ownerId, original.ownerId);
      expect(restored.ownerImgUrl, original.ownerImgUrl);
      expect(restored.type, original.type);
      expect(restored.reviewStars, original.reviewStars);
      expect(restored.price?.amount, original.price?.amount);
      expect(restored.isActive, original.isActive);
      expect(restored.isMain, original.isMain);
    });

    test('listas null se hidratan como vacías', () {
      final p = Place.fromJSON({
        'id': 'pl1',
        'ownerImgUrl': 'https://x',
        'galleryImgUrls': null,
        'bookings': null,
        'reviews': null,
        'type': 'publicSpace',
      });
      expect(p.galleryImgUrls, isEmpty);
      expect(p.bookings, isEmpty);
      expect(p.reviews, isEmpty);
    });

    test('reviewStars como int se parsea a double', () {
      final p = Place.fromJSON({
        'ownerImgUrl': 'https://x',
        'reviewStars': 5,
      });
      expect(p.reviewStars, 5.0);
    });

    test('reviewStars null usa default "10"', () {
      final p = Place.fromJSON({
        'ownerImgUrl': 'https://x',
        'reviewStars': null,
      });
      // El código hace `?.toString() ?? "10"` — null → "10" → 10.0
      expect(p.reviewStars, 10.0);
    });

    test('OBS: defaults de fromJSON divergen del constructor para isActive/isMain', () {
      // Constructor: isActive=true, isMain=true.
      // fromJSON sin las llaves: isActive=false, isMain=false.
      final fromEmpty = Place.fromJSON({'ownerImgUrl': 'https://x'});
      expect(fromEmpty.isActive, isFalse,
          reason: 'fromJSON default false, distinto del constructor true');
      expect(fromEmpty.isMain, isFalse,
          reason: 'fromJSON default false, distinto del constructor true');
    });
  });
}
