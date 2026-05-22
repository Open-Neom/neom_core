// Tests for `CollectiveFile` — archivos compartidos en collectives.

import 'package:flutter_test/flutter_test.dart';
import 'package:neom_core/domain/model/collective_file.dart';

void main() {
  group('CollectiveFile — defaults', () {
    test('constructor usa defaults', () {
      final f = CollectiveFile();
      expect(f.id, '');
      expect(f.collectiveId, '');
      expect(f.name, '');
      expect(f.description, '');
      expect(f.url, '');
      expect(f.thumbnailUrl, '');
      expect(f.fileType, 'other');
      expect(f.fileSize, 0);
      expect(f.uploadedBy, '');
      expect(f.uploaderName, '');
      expect(f.uploaderImgUrl, '');
      expect(f.folder, '');
      expect(f.createdAt, 0);
    });
  });

  group('CollectiveFile — round-trip', () {
    test('preserva todos los campos', () {
      final original = CollectiveFile(
        id: 'f1',
        collectiveId: 'c1',
        name: 'demo.mp3',
        description: 'first take',
        url: 'https://x/demo.mp3',
        thumbnailUrl: 'https://x/demo.jpg',
        fileType: 'audio',
        fileSize: 1024 * 1024 * 5,
        uploadedBy: 'u1',
        uploaderName: 'Ana',
        uploaderImgUrl: 'https://x/avatar.jpg',
        folder: 'demos',
        createdAt: 1700000000000,
      );
      final json = {...original.toJSON(), 'id': original.id};
      final restored = CollectiveFile.fromJSON(json);

      expect(restored.id, original.id);
      expect(restored.collectiveId, original.collectiveId);
      expect(restored.name, original.name);
      expect(restored.description, original.description);
      expect(restored.url, original.url);
      expect(restored.thumbnailUrl, original.thumbnailUrl);
      expect(restored.fileType, original.fileType);
      expect(restored.fileSize, original.fileSize);
      expect(restored.uploadedBy, original.uploadedBy);
      expect(restored.uploaderName, original.uploaderName);
      expect(restored.uploaderImgUrl, original.uploaderImgUrl);
      expect(restored.folder, original.folder);
      expect(restored.createdAt, original.createdAt);
    });

    test('fromJSON con mapa vacío usa defaults', () {
      final f = CollectiveFile.fromJSON(<String, dynamic>{});
      expect(f.fileType, 'other');
      expect(f.fileSize, 0);
      expect(f.folder, '');
    });

    test('fileSize grande (5GB) no rompe', () {
      final big = 5 * 1024 * 1024 * 1024; // 5 GB
      final f = CollectiveFile(fileSize: big);
      expect(CollectiveFile.fromJSON(f.toJSON()).fileSize, big);
    });

    test('URLs con caracteres especiales se preservan', () {
      final url = 'https://example.com/files/foo bar%2Fbaz?token=xyz&v=1';
      final f = CollectiveFile(url: url);
      expect(CollectiveFile.fromJSON(f.toJSON()).url, url);
    });
  });

  group('CollectiveFile.toString', () {
    test('contiene id, name, fileType, folder', () {
      final f = CollectiveFile(
        id: 'f1',
        name: 'demo.mp3',
        collectiveId: 'c1',
        fileType: 'audio',
        folder: 'demos',
      );
      final s = f.toString();
      expect(s, contains('f1'));
      expect(s, contains('demo.mp3'));
      expect(s, contains('audio'));
      expect(s, contains('demos'));
    });
  });
}
