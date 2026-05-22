// Tests for `OrganicPromoItem`.

import 'package:flutter_test/flutter_test.dart';
import 'package:neom_core/domain/model/organic_promo_item.dart';
import 'package:neom_core/utils/enums/app_in_use.dart';

void main() {
  group('OrganicPromoItem — constructor', () {
    test('constructor con required', () {
      final p = OrganicPromoItem(
        id: 'p1',
        sourceApp: AppInUse.e,
        itemType: 'EventType',
        title: 'Promo',
        description: 'desc',
        mediaUrl: 'https://x',
        deepLink: '/event/123',
      );
      expect(p.id, 'p1');
      expect(p.sourceApp, AppInUse.e);
      expect(p.itemType, 'EventType');
      expect(p.title, 'Promo');
      expect(p.description, 'desc');
      expect(p.mediaUrl, 'https://x');
      expect(p.deepLink, '/event/123');
      expect(p.slug, '');
    });
  });

  group('OrganicPromoItem.fromJson', () {
    test('parsea JSON completo', () {
      final p = OrganicPromoItem.fromJson({
        'id': 'p1',
        'sourceApp': 'e',
        'itemType': 'EventType',
        'title': 'Promo',
        'description': 'desc',
        'mediaUrl': 'https://x',
        'deepLink': '/event/123',
        'slug': 'mi-evento',
      });
      expect(p.id, 'p1');
      expect(p.sourceApp, AppInUse.e);
      expect(p.title, 'Promo');
      expect(p.slug, 'mi-evento');
    });

    test('mapa vacío usa defaults', () {
      final p = OrganicPromoItem.fromJson(<String, dynamic>{});
      expect(p.id, '');
      expect(p.itemType, '');
      expect(p.slug, '');
    });

    test('sourceApp desconocido cae al primer valor del enum', () {
      final p = OrganicPromoItem.fromJson({
        'id': 'p1',
        'sourceApp': 'invalid_app',
      });
      expect(p.sourceApp, AppInUse.a);
    });
  });

  group('OrganicPromoItem — round-trip', () {
    test('preserva todos los campos', () {
      final original = OrganicPromoItem(
        id: 'p1',
        sourceApp: AppInUse.e,
        itemType: 'PostType',
        title: 'Mi post',
        description: 'desc',
        mediaUrl: 'https://m',
        deepLink: '/post/123',
        slug: 'mi-post',
      );
      final restored = OrganicPromoItem.fromJson(original.toJson());
      expect(restored.id, original.id);
      expect(restored.sourceApp, original.sourceApp);
      expect(restored.itemType, original.itemType);
      expect(restored.title, original.title);
      expect(restored.description, original.description);
      expect(restored.mediaUrl, original.mediaUrl);
      expect(restored.deepLink, original.deepLink);
      expect(restored.slug, original.slug);
    });
  });
}
