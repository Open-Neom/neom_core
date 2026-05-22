// Tests for `BaseItem` — clase base sin JSON.

import 'package:flutter_test/flutter_test.dart';
import 'package:neom_core/domain/model/base_item.dart';

void main() {
  group('BaseItem — defaults', () {
    test('constructor sin params', () {
      final b = BaseItem();
      expect(b.id, '');
      expect(b.name, '');
      expect(b.description, isNull);
      expect(b.imgUrl, '');
      expect(b.galleryUrls, isNull);
      expect(b.url, '');
      expect(b.duration, 0);
      expect(b.state, 0);
      expect(b.permaUrl, '');
      expect(b.ownerId, '');
      expect(b.ownerName, '');
      expect(b.publishedYear, 0);
      expect(b.metaOwner, isNull);
      expect(b.categories, isEmpty);
    });

    test('parámetros nombrados', () {
      final b = BaseItem(
        id: 'b1',
        name: 'Item',
        description: 'desc',
        imgUrl: 'https://x',
        galleryUrls: ['url1', 'url2'],
        url: 'https://stream',
        duration: 240,
        state: 3,
        permaUrl: 'https://perma',
        ownerId: 'u1',
        ownerName: 'Ana',
        publishedYear: 2024,
        metaOwner: 'Editor',
        categories: ['rock', 'jazz'],
      );
      expect(b.id, 'b1');
      expect(b.name, 'Item');
      expect(b.description, 'desc');
      expect(b.galleryUrls, ['url1', 'url2']);
      expect(b.url, 'https://stream');
      expect(b.duration, 240);
      expect(b.state, 3);
      expect(b.publishedYear, 2024);
      expect(b.metaOwner, 'Editor');
      expect(b.categories, ['rock', 'jazz']);
    });
  });
}
