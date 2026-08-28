import 'package:flutter_test/flutter_test.dart';
import 'package:neom_core/data/firestore/release_deduplication_service.dart';
import 'package:neom_core/domain/model/app_release_item.dart';
import 'package:neom_core/domain/model/price.dart';
import 'package:neom_core/utils/enums/app_currency.dart';
import 'package:neom_core/utils/enums/release_status.dart';
import 'package:neom_core/utils/enums/release_type.dart';

void main() {
  late ReleaseDeduplicationService deduplicationService;

  setUp(() {
    deduplicationService = ReleaseDeduplicationService();
  });

  group('ReleaseDeduplicationService - normalizeKey', () {
    test('normalizes title and owner correctly', () {
      final item1 = AppReleaseItem(
        id: '1',
        name: 'Mujercitas',
        ownerName: 'Louisa May Alcott',
      );
      final item2 = AppReleaseItem(
        id: '2',
        name: '  MUJERCITAS  ',
        ownerName: 'louisa may alcott',
      );

      expect(
        deduplicationService.normalizeKey(item1),
        equals(deduplicationService.normalizeKey(item2)),
      );
      expect(deduplicationService.normalizeKey(item1), equals('mujercitas::louisa-may-alcott'));
    });

    test('falls back to ownerProfileId when available', () {
      final item = AppReleaseItem(
        id: '1',
        name: 'Mujercitas',
        ownerName: 'Louisa May Alcott',
        ownerProfileId: 'profile_123',
      );

      expect(deduplicationService.normalizeKey(item), equals('mujercitas::profile_123'));
    });
  });

  group('ReleaseDeduplicationService - calculateCompletenessScore', () {
    test('gives higher score to item with images, description and pricing', () {
      final completeItem = AppReleaseItem(
        id: 'complete_1',
        name: 'Mujercitas',
        ownerName: 'Louisa May Alcott',
        description: 'Novela clásica sobre cuatro hermanas que crecen durante la guerra.',
        imgUrl: 'https://storage.googleapis.com/emxi/covers/mujercitas.jpg',
        previewUrl: 'https://storage.googleapis.com/emxi/files/mujercitas.pdf',
        galleryUrls: ['https://storage.googleapis.com/emxi/covers/mujercitas.jpg'],
        categories: ['Literatura Clásica', 'Novela'],
        digitalPrice: Price(amount: 49.99, currency: AppCurrency.mxn),
        physicalPrice: Price(amount: 199.00, currency: AppCurrency.mxn),
        boughtUsers: ['user1', 'user2'],
        likedProfiles: ['p1', 'p2', 'p3'],
        commentIds: ['c1'],
        publishedYear: 1868,
        duration: 350,
        status: ReleaseStatus.publish,
      );

      final incompleteItem = AppReleaseItem(
        id: 'incomplete_2',
        name: 'Mujercitas',
        ownerName: 'Louisa May Alcott',
        description: '',
        imgUrl: '',
        previewUrl: '',
        categories: [],
        status: ReleaseStatus.draft,
      );

      final completeScore = deduplicationService.calculateCompletenessScore(completeItem);
      final incompleteScore = deduplicationService.calculateCompletenessScore(incompleteItem);

      expect(completeScore, greaterThan(incompleteScore));
      expect(completeScore, greaterThan(100));
      expect(incompleteScore, lessThan(20));
    });

    test('penalizes suspended items', () {
      final activeItem = AppReleaseItem(
        id: '1',
        name: 'Test',
        status: ReleaseStatus.publish,
      );
      final suspendedItem = AppReleaseItem(
        id: '2',
        name: 'Test',
        status: ReleaseStatus.publish,
        isSuspended: true,
      );

      expect(
        deduplicationService.calculateCompletenessScore(activeItem),
        greaterThan(deduplicationService.calculateCompletenessScore(suspendedItem)),
      );
    });
  });

  group('ReleaseDeduplicationService - groupDuplicates & selectCanonicalItem', () {
    test('groups duplicate items and selects the most complete as canonical', () {
      final itemComplete = AppReleaseItem(
        id: 'doc_canonical',
        name: 'Mujercitas',
        ownerName: 'Louisa May Alcott',
        description: 'Edición ilustrada completa.',
        imgUrl: 'https://emxi.org/cover.png',
        previewUrl: 'https://emxi.org/book.pdf',
        categories: ['Clásicos'],
        createdTime: 1700000000000,
        status: ReleaseStatus.publish,
      );

      final itemDuplicate = AppReleaseItem(
        id: 'doc_duplicate',
        name: 'Mujercitas',
        ownerName: 'Louisa May Alcott',
        description: '',
        imgUrl: '',
        previewUrl: '',
        createdTime: 1700000010000,
        status: ReleaseStatus.draft,
      );

      final uniqueItem = AppReleaseItem(
        id: 'doc_unique',
        name: 'Oculto en los pliegues del tiempo',
        ownerName: 'Alejandro Pohlenz',
        status: ReleaseStatus.publish,
      );

      final list = [itemDuplicate, uniqueItem, itemComplete];
      final groups = deduplicationService.groupDuplicates(list);

      expect(groups.length, equals(1));
      expect(groups.containsKey('mujercitas::louisa-may-alcott'), isTrue);
      expect(groups['mujercitas::louisa-may-alcott']!.length, equals(2));

      final canonical = deduplicationService.selectCanonicalItem(groups['mujercitas::louisa-may-alcott']!);
      expect(canonical.id, equals('doc_canonical'));
    });
  });

  group('ReleaseDeduplicationService - mergeMetadata', () {
    test('merges engagement and missing fields from duplicate to canonical', () {
      final canonical = AppReleaseItem(
        id: 'canonical',
        name: 'Mujercitas',
        ownerName: 'Louisa May Alcott',
        description: 'Descripción original',
        imgUrl: 'https://emxi.org/cover.png',
        previewUrl: 'https://emxi.org/book.pdf',
        categories: ['Novela'],
        likedProfiles: ['profile_A'],
        boughtUsers: ['user_A'],
        commentIds: ['comment_1'],
      );

      final duplicate = AppReleaseItem(
        id: 'duplicate',
        name: 'Mujercitas',
        ownerName: 'Louisa May Alcott',
        categories: ['Clásicos', 'Novela'],
        likedProfiles: ['profile_A', 'profile_B'],
        boughtUsers: ['user_B'],
        commentIds: ['comment_2'],
        digitalPrice: Price(amount: 50.0, currency: AppCurrency.mxn),
        publishedYear: 1868,
      );

      final changed = deduplicationService.mergeMetadata(canonical, duplicate);

      expect(changed, isTrue);
      expect(canonical.likedProfiles, containsAll(['profile_A', 'profile_B']));
      expect(canonical.boughtUsers, containsAll(['user_A', 'user_B']));
      expect(canonical.commentIds, containsAll(['comment_1', 'comment_2']));
      expect(canonical.categories, containsAll(['Novela', 'Clásicos']));
      expect(canonical.digitalPrice?.amount, equals(50.0));
      expect(canonical.publishedYear, equals(1868));
    });
  });

  group('ReleaseDeduplicationService - deduplicateList', () {
    test('deduplicates a mixed list and preserves unique items', () {
      final dup1 = AppReleaseItem(
        id: 'd1',
        name: 'Mujercitas',
        ownerName: 'Louisa May Alcott',
        imgUrl: 'https://emxi.org/cover.png',
        previewUrl: 'https://emxi.org/book.pdf',
        createdTime: 1000,
        likedProfiles: ['user1'],
      );

      final dup2 = AppReleaseItem(
        id: 'd2',
        name: 'Mujercitas',
        ownerName: 'Louisa May Alcott',
        imgUrl: '',
        createdTime: 2000,
        likedProfiles: ['user2'],
      );

      final unique1 = AppReleaseItem(
        id: 'u1',
        name: 'Oculto en los pliegues del tiempo',
        ownerName: 'Alejandro Pohlenz',
        createdTime: 3000,
      );

      final unique2 = AppReleaseItem(
        id: 'u2',
        name: 'Cartas para Luille',
        ownerName: 'Victor Hugo Silva',
        createdTime: 4000,
      );

      final input = [dup1, unique1, dup2, unique2];
      final output = deduplicationService.deduplicateList(input);

      expect(output.length, equals(3));
      final mujercitas = output.firstWhere((i) => i.name == 'Mujercitas');
      expect(mujercitas.id, equals('d1'));
      expect(mujercitas.likedProfiles, containsAll(['user1', 'user2']));
    });
  });
}
