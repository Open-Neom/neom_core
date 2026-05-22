// Tests for `AppPhysicalItem` — items físicos.
//
// Modelo simple. Posible bug NC-11: fromJSON hace `data["genres"].map(...)`
// que crashea cuando data["genres"] es null.

import 'package:flutter_test/flutter_test.dart';
import 'package:neom_core/domain/model/app_physical_item.dart';
import 'package:neom_core/utils/enums/app_item_size.dart';
import 'package:neom_core/utils/enums/app_item_type.dart';

void main() {
  group('AppPhysicalItem — defaults', () {
    test('constructor sin params', () {
      final p = AppPhysicalItem();
      expect(p.id, '');
      expect(p.name, '');
      expect(p.imgUrl, '');
      expect(p.description, '');
      expect(p.ownerId, '');
      expect(p.ownerName, '');
      expect(p.ownerImgUrl, '');
      expect(p.duration, 0);
      expect(p.previewUrl, '');
      expect(p.size, AppItemSize.halfLetter);
      expect(p.type, AppItemType.a);
      expect(p.genres, isEmpty);
      expect(p.publisher, '');
      expect(p.publishedDate, '');
    });
  });

  group('AppPhysicalItem — toJSON', () {
    test('contiene 14 llaves esperadas', () {
      final json = AppPhysicalItem().toJSON();
      expect(
        json.keys,
        containsAll([
          'id', 'name', 'description', 'imgUrl',
          'ownerId', 'ownerName', 'ownerImgUrl',
          'duration', 'previewUrl', 'size', 'type',
          'genres', 'publisher', 'publishedDate',
        ]),
      );
    });

    test('size y type se serializan como string (.name)', () {
      final json = AppPhysicalItem(
        size: AppItemSize.halfLetter,
        type: AppItemType.a,
      ).toJSON();
      expect(json['size'], 'halfLetter');
      expect(json['type'], 'a');
    });

    test('genres lista vacía produce lista vacía en JSON', () {
      expect(AppPhysicalItem().toJSON()['genres'], <dynamic>[]);
    });
  });

  group('AppPhysicalItem — fromJSON (puede revelar NC-11)', () {
    test('NC-11: fromJSON con genres null no debería crashear', () {
      // Bug: `data["genres"].map(...)` — si genres es null, .map sobre
      // null lanza NoSuchMethodError.
      try {
        final p = AppPhysicalItem.fromJSON({
          'id': 'p1',
          'name': 'item',
          'genres': null,
        });
        expect(p.genres, isEmpty);
      } on NoSuchMethodError catch (e) {
        fail('NC-11: fromJSON crashea con genres null. $e');
      }
    });

    test('NC-11: fromJSON con mapa vacío no debería crashear', () {
      try {
        final p = AppPhysicalItem.fromJSON(<String, dynamic>{});
        expect(p.id, '');
        expect(p.genres, isEmpty);
      } on NoSuchMethodError catch (e) {
        fail('NC-11: fromJSON crashea con mapa vacío. $e');
      }
    });

    test('fromJSON con genres lista vacía no crashea', () {
      final p = AppPhysicalItem.fromJSON({
        'id': 'p1',
        'genres': <Map<String, dynamic>>[],
      });
      expect(p.id, 'p1');
      expect(p.genres, isEmpty);
    });

    test('fromJSON con campos string básicos', () {
      final p = AppPhysicalItem.fromJSON({
        'id': 'p1',
        'name': 'Libro',
        'description': 'desc',
        'imgUrl': 'https://x',
        'ownerName': 'Ana',
        'duration': 120,
        'previewUrl': 'https://preview',
        'publisher': 'Editor',
        'publishedDate': '2024',
        'genres': <Map<String, dynamic>>[],
      });
      expect(p.id, 'p1');
      expect(p.name, 'Libro');
      expect(p.description, 'desc');
      expect(p.duration, 120);
      expect(p.publisher, 'Editor');
      expect(p.publishedDate, '2024');
    });
  });
}
