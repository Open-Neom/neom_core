// Tests for `ReadingProgress` — value class agregada de NupaleSession.

import 'package:flutter_test/flutter_test.dart';
import 'package:neom_core/domain/model/nupale/nupale_session.dart';
import 'package:neom_core/domain/model/nupale/reading_progress.dart';

void main() {
  group('ReadingProgress — defaults', () {
    test('constructor con required mínimos', () {
      final p = ReadingProgress(itemId: 'b1', itemName: 'Book');
      expect(p.itemId, 'b1');
      expect(p.itemName, 'Book');
      expect(p.itemImgUrl, '');
      expect(p.itemOwnerName, '');
      expect(p.maxPageReached, 0);
      expect(p.totalPages, 0);
      expect(p.sessionCount, 0);
      expect(p.totalReadingTime, 0);
      expect(p.totalPagesRead, 0);
      expect(p.pagesViewed, isEmpty);
      expect(p.lastReadTime, 0);
    });
  });

  group('ReadingProgress.completionPercent', () {
    test('totalPages == 0 → 0', () {
      final p = ReadingProgress(itemId: 'b1', itemName: 'B');
      expect(p.completionPercent, 0.0);
    });

    test('mitad leída → 0.5', () {
      final p = ReadingProgress(
        itemId: 'b1', itemName: 'B',
        maxPageReached: 50, totalPages: 100,
      );
      expect(p.completionPercent, 0.5);
    });

    test('clamp a 1.0 cuando maxPage > totalPages', () {
      final p = ReadingProgress(
        itemId: 'b1', itemName: 'B',
        maxPageReached: 200, totalPages: 100,
      );
      expect(p.completionPercent, 1.0);
    });

    test('completo exacto', () {
      final p = ReadingProgress(
        itemId: 'b1', itemName: 'B',
        maxPageReached: 100, totalPages: 100,
      );
      expect(p.completionPercent, 1.0);
    });
  });

  group('ReadingProgress.hasReReads', () {
    test('false con 0 o 1 sesión', () {
      expect(ReadingProgress(itemId: 'b', itemName: 'B').hasReReads, isFalse);
      expect(
        ReadingProgress(itemId: 'b', itemName: 'B', sessionCount: 1).hasReReads,
        isFalse,
      );
    });

    test('true con 2+ sesiones', () {
      expect(
        ReadingProgress(itemId: 'b', itemName: 'B', sessionCount: 2).hasReReads,
        isTrue,
      );
    });
  });

  group('ReadingProgress.isComplete', () {
    test('true cuando >= 90%', () {
      final p = ReadingProgress(
        itemId: 'b', itemName: 'B',
        maxPageReached: 90, totalPages: 100,
      );
      expect(p.isComplete, isTrue);
    });

    test('false cuando < 90%', () {
      final p = ReadingProgress(
        itemId: 'b', itemName: 'B',
        maxPageReached: 89, totalPages: 100,
      );
      expect(p.isComplete, isFalse);
    });
  });

  group('ReadingProgress.fromSessions', () {
    test('lista vacía produce ReadingProgress vacío', () {
      final p = ReadingProgress.fromSessions('b1', []);
      expect(p.itemId, 'b1');
      expect(p.itemName, '');
      expect(p.totalPages, 0);
      expect(p.sessionCount, 0);
    });

    test('agrega múltiples sesiones', () {
      final sessions = [
        NupaleSession(
          itemId: 'b1', itemName: 'My Book',
          nupale: 30, totalPages: 200,
          createdTime: 1000,
          pagesDuration: {1: 60, 2: 45},
        ),
        NupaleSession(
          itemId: 'b1', itemName: 'My Book',
          nupale: 20, totalPages: 200,
          createdTime: 2000,
          pagesDuration: {3: 30, 4: 50},
        ),
      ];
      final p = ReadingProgress.fromSessions('b1', sessions);

      expect(p.itemId, 'b1');
      expect(p.itemName, 'My Book');
      expect(p.totalPages, 200);
      expect(p.sessionCount, 2);
      expect(p.totalPagesRead, 50, reason: '30 + 20');
      expect(p.maxPageReached, 4, reason: 'page 4 es la más alta');
      expect(p.totalReadingTime, 60 + 45 + 30 + 50);
      expect(p.lastReadTime, 2000);
      expect(p.pagesViewed, containsAll([1, 2, 3, 4]));
    });

    test('hasReReads y isComplete se computan correctamente desde sesiones', () {
      final p = ReadingProgress.fromSessions('b1', [
        NupaleSession(itemId: 'b1', itemName: 'B', totalPages: 100, pageViews: {95: 1}),
        NupaleSession(itemId: 'b1', itemName: 'B', totalPages: 100, pageViews: {99: 1}),
      ]);
      expect(p.hasReReads, isTrue);
      expect(p.isComplete, isTrue);
    });
  });

  group('ReadingProgress.copyWith', () {
    test('actualiza solo itemImgUrl y itemOwnerName', () {
      final original = ReadingProgress(
        itemId: 'b1', itemName: 'Book',
        maxPageReached: 50, totalPages: 100,
      );
      final updated = original.copyWith(
        itemImgUrl: 'https://x',
        itemOwnerName: 'Author',
      );
      expect(updated.itemId, original.itemId);
      expect(updated.itemName, original.itemName);
      expect(updated.maxPageReached, original.maxPageReached);
      expect(updated.totalPages, original.totalPages);
      expect(updated.itemImgUrl, 'https://x');
      expect(updated.itemOwnerName, 'Author');
    });
  });
}
