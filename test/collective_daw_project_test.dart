// Tests for `CollectiveDawProject`.

import 'package:flutter_test/flutter_test.dart';
import 'package:neom_core/domain/model/collective_daw_project.dart';

void main() {
  group('CollectiveDawProject — defaults', () {
    test('constructor sin params', () {
      final p = CollectiveDawProject();
      expect(p.id, '');
      expect(p.name, '');
      expect(p.description, '');
      expect(p.ownerId, '');
      expect(p.ownerName, '');
      expect(p.ownerImgUrl, '');
      expect(p.collectiveId, isNull);
      expect(p.collectiveName, isNull);
      expect(p.bpm, 120, reason: 'BPM default es 120');
      expect(p.trackCount, 0);
      expect(p.coverImgUrl, isNull);
      expect(p.status, CollectiveDawProjectStatus.draft);
      expect(p.createdTime, 0);
      expect(p.updatedTime, 0);
    });
  });

  group('CollectiveDawProject.isCollectiveProject', () {
    test('false cuando collectiveId es null', () {
      expect(CollectiveDawProject().isCollectiveProject, isFalse);
    });

    test('false cuando collectiveId es vacío', () {
      expect(
        CollectiveDawProject(collectiveId: '').isCollectiveProject,
        isFalse,
      );
    });

    test('true cuando collectiveId no vacío', () {
      expect(
        CollectiveDawProject(collectiveId: 'c1').isCollectiveProject,
        isTrue,
      );
    });
  });

  group('CollectiveDawProject — round-trip', () {
    test('preserva todos los campos', () {
      final original = CollectiveDawProject(
        id: 'p1',
        name: 'My Beat',
        description: 'desc',
        ownerId: 'u1',
        ownerName: 'Ana',
        ownerImgUrl: 'https://x',
        collectiveId: 'c1',
        collectiveName: 'My Band',
        bpm: 128,
        trackCount: 5,
        coverImgUrl: 'https://cover',
        status: CollectiveDawProjectStatus.recording,
        createdTime: 1700000000000,
        updatedTime: 1700000001000,
      );
      final restored = CollectiveDawProject.fromJSON(original.toJSON());

      expect(restored.id, original.id);
      expect(restored.name, original.name);
      expect(restored.description, original.description);
      expect(restored.ownerId, original.ownerId);
      expect(restored.ownerName, original.ownerName);
      expect(restored.ownerImgUrl, original.ownerImgUrl);
      expect(restored.collectiveId, original.collectiveId);
      expect(restored.collectiveName, original.collectiveName);
      expect(restored.bpm, original.bpm);
      expect(restored.trackCount, original.trackCount);
      expect(restored.coverImgUrl, original.coverImgUrl);
      expect(restored.status, original.status);
      expect(restored.createdTime, original.createdTime);
      expect(restored.updatedTime, original.updatedTime);
    });

    test('mapa vacío usa defaults', () {
      final p = CollectiveDawProject.fromJSON(<String, dynamic>{});
      expect(p.id, '');
      expect(p.bpm, 120);
      expect(p.status, CollectiveDawProjectStatus.draft);
    });

    test('bpm como string se parsea (num?.toInt) ', () {
      // El código hace `(json['bpm'] as num?)?.toInt() ?? 120`
      // String NO es num, así que cast falla. Pero como el cast es a num?,
      // si no es num retorna null. Esperamos default 120.
      final p = CollectiveDawProject.fromJSON({'bpm': 'not_a_num'});
      expect(p.bpm, 120, reason: 'cast inválido cae al default');
    });

    test('bpm null usa 120', () {
      final p = CollectiveDawProject.fromJSON({'bpm': null});
      expect(p.bpm, 120);
    });

    test('status desconocido cae a draft', () {
      final p = CollectiveDawProject.fromJSON({'status': 'totally_invalid'});
      expect(p.status, CollectiveDawProjectStatus.draft);
    });

    test('todos los status válidos son round-trip-able', () {
      for (final s in CollectiveDawProjectStatus.values) {
        final original = CollectiveDawProject(status: s);
        final restored = CollectiveDawProject.fromJSON(original.toJSON());
        expect(restored.status, s);
      }
    });

    test('campos opcionales null preservan null', () {
      final original = CollectiveDawProject();
      final restored = CollectiveDawProject.fromJSON(original.toJSON());
      expect(restored.collectiveId, isNull);
      expect(restored.collectiveName, isNull);
      expect(restored.coverImgUrl, isNull);
    });
  });
}
