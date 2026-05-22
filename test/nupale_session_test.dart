// Tests for `NupaleSession` — telemetría de lectura.

import 'package:flutter_test/flutter_test.dart';
import 'package:neom_core/domain/model/nupale/nupale_session.dart';
import 'package:neom_core/utils/enums/subscription_level.dart';

void main() {
  group('NupaleSession — defaults', () {
    test('constructor sin params', () {
      final s = NupaleSession();
      expect(s.id, '');
      expect(s.itemId, '');
      expect(s.itemName, '');
      expect(s.ownerEmail, '');
      expect(s.readerEmail, '');
      expect(s.pagesDuration, isEmpty);
      expect(s.pageViews, isEmpty);
      expect(s.nupale, 0);
      expect(s.createdTime, 0);
      expect(s.totalPages, 0);
      expect(s.subscriptionLevel, isNull);
      expect(s.isTest, isFalse);
    });
  });

  group('NupaleSession — toJSON', () {
    test('serializa pagesDuration con keys como string', () {
      final s = NupaleSession(pagesDuration: {1: 30, 2: 45});
      final json = s.toJSON();
      expect(json['pagesDuration'], {'1': 30, '2': 45});
    });

    test('serializa pageViews con keys como string', () {
      final s = NupaleSession(pageViews: {1: 2, 2: 3});
      final json = s.toJSON();
      expect(json['pageViews'], {'1': 2, '2': 3});
    });
  });

  group('NupaleSession — round-trip', () {
    test('preserva campos básicos', () {
      final original = NupaleSession(
        id: 'ns1',
        itemId: 'book1',
        itemName: 'Mi libro',
        ownerEmail: 'o@x.com',
        readerEmail: 'r@x.com',
        nupale: 50,
        totalPages: 200,
        createdTime: 1700000000000,
        subscriptionLevel: SubscriptionLevel.basic,
        isTest: false,
      );
      final restored = NupaleSession.fromJSON(original.toJSON());
      expect(restored.id, original.id);
      expect(restored.itemId, original.itemId);
      expect(restored.itemName, original.itemName);
      expect(restored.ownerEmail, original.ownerEmail);
      expect(restored.readerEmail, original.readerEmail);
      expect(restored.nupale, original.nupale);
      expect(restored.totalPages, original.totalPages);
      expect(restored.createdTime, original.createdTime);
      expect(restored.subscriptionLevel, original.subscriptionLevel);
      expect(restored.isTest, original.isTest);
    });

    test('round-trip de pagesDuration (Map<int,int>)', () {
      final original = NupaleSession(
        pagesDuration: {1: 30, 2: 45, 10: 60},
      );
      final restored = NupaleSession.fromJSON(original.toJSON());
      expect(restored.pagesDuration[1], 30);
      expect(restored.pagesDuration[2], 45);
      expect(restored.pagesDuration[10], 60);
    });

    test('round-trip de pageViews', () {
      final original = NupaleSession(
        pageViews: {1: 2, 2: 5},
      );
      final restored = NupaleSession.fromJSON(original.toJSON());
      expect(restored.pageViews[1], 2);
      expect(restored.pageViews[2], 5);
    });

    test('legacy ownerId se mapea a ownerEmail', () {
      final s = NupaleSession.fromJSON({
        'ownerId': 'legacy@x.com',
      });
      expect(s.ownerEmail, 'legacy@x.com');
    });

    test('mapa vacío usa defaults', () {
      final s = NupaleSession.fromJSON(<String, dynamic>{});
      expect(s.id, '');
      expect(s.nupale, 0);
      expect(s.pagesDuration, isEmpty);
      expect(s.pageViews, isEmpty);
    });

    test('pagesDuration null se hidrata como mapa vacío', () {
      final s = NupaleSession.fromJSON({'pagesDuration': null});
      expect(s.pagesDuration, isEmpty);
    });
  });
}
