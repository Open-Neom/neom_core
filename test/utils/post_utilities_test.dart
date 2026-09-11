import 'package:flutter_test/flutter_test.dart';
import 'package:neom_core/domain/model/post.dart';
import 'package:neom_core/utils/enums/post_type.dart';
import 'package:neom_core/utils/post_utilities.dart';

void main() {
  group('PostUtilities.areLikelyDuplicates', () {
    test('identical objects or same ID are duplicates', () {
      final p1 = Post(id: 'post_1', ownerId: 'user_1');
      expect(PostUtilities.areLikelyDuplicates(p1, p1), isTrue);

      final p2 = Post(id: 'post_1', ownerId: 'user_2');
      expect(PostUtilities.areLikelyDuplicates(p1, p2), isTrue);
    });

    test('different ownerId are never duplicates', () {
      final p1 = Post(id: 'p1', ownerId: 'user_1', mediaUrl: 'https://cdn.com/video.mp4');
      final p2 = Post(id: 'p2', ownerId: 'user_2', mediaUrl: 'https://cdn.com/video.mp4');
      expect(PostUtilities.areLikelyDuplicates(p1, p2), isFalse);
    });

    test('same owner and identical mediaUrl are duplicates', () {
      final p1 = Post(id: 'p1', ownerId: 'user_1', mediaUrl: 'https://cdn.com/video.mp4', createdTime: 1000);
      final p2 = Post(id: 'p2', ownerId: 'user_1', mediaUrl: 'https://cdn.com/video.mp4', createdTime: 5000);
      expect(PostUtilities.areLikelyDuplicates(p1, p2), isTrue);
    });

    test('same owner and identical thumbnailUrl are duplicates', () {
      final p1 = Post(id: 'p1', ownerId: 'user_1', thumbnailUrl: 'https://cdn.com/thumb.jpg', createdTime: 1000);
      final p2 = Post(id: 'p2', ownerId: 'user_1', thumbnailUrl: 'https://cdn.com/thumb.jpg', createdTime: 5000);
      expect(PostUtilities.areLikelyDuplicates(p1, p2), isTrue);
    });

    test('same owner and identical referenceId are duplicates', () {
      final p1 = Post(id: 'p1', ownerId: 'user_1', referenceId: 'rel_123', createdTime: 1000);
      final p2 = Post(id: 'p2', ownerId: 'user_1', referenceId: 'rel_123', createdTime: 5000);
      expect(PostUtilities.areLikelyDuplicates(p1, p2), isTrue);
    });


    test('same owner, same caption, same type within time threshold are duplicates', () {
      final p1 = Post(
        id: 'p1',
        ownerId: 'user_1',
        caption: 'Mi nuevo libro!',
        type: PostType.caption,
        createdTime: 100000,
      );
      final p2 = Post(
        id: 'p2',
        ownerId: 'user_1',
        caption: '  Mi nuevo libro!  ',
        type: PostType.caption,
        createdTime: 130000, // 30s diff
      );
      expect(PostUtilities.areLikelyDuplicates(p1, p2), isTrue);
    });

    test('same caption outside time threshold are NOT duplicates', () {
      final p1 = Post(
        id: 'p1',
        ownerId: 'user_1',
        caption: 'Buenos días!',
        type: PostType.caption,
        createdTime: 100000,
      );
      final p2 = Post(
        id: 'p2',
        ownerId: 'user_1',
        caption: 'Buenos días!',
        type: PostType.caption,
        createdTime: 100000 + 300000, // 5 min diff
      );
      expect(PostUtilities.areLikelyDuplicates(p1, p2), isFalse);
    });
  });

  group('PostUtilities.deduplicatePosts', () {
    test('removes duplicate posts and preserves higher engagement', () {
      final p1 = Post(
        id: 'p1',
        ownerId: 'user_1',
        mediaUrl: 'https://cdn.com/video.mp4',
        createdTime: 1000,
        likedProfiles: ['u2'],
      );
      final p2 = Post(
        id: 'p2',
        ownerId: 'user_1',
        mediaUrl: 'https://cdn.com/video.mp4',
        createdTime: 1500,
        likedProfiles: ['u2', 'u3', 'u4'],
      );
      final p3 = Post(
        id: 'p3',
        ownerId: 'user_2',
        mediaUrl: 'https://cdn.com/other.mp4',
        createdTime: 2000,
      );

      final deduped = PostUtilities.deduplicatePosts([p1, p2, p3]);
      expect(deduped.length, equals(2));
      // First slot preserved with p2's higher engagement
      expect(deduped[0].id, equals('p2'));
      expect(deduped[1].id, equals('p3'));
    });

    test('deduplicatePostsMap removes duplicate values', () {
      final p1 = Post(id: 'p1', ownerId: 'user_1', mediaUrl: 'https://cdn.com/v.mp4');
      final p2 = Post(id: 'p2', ownerId: 'user_1', mediaUrl: 'https://cdn.com/v.mp4');

      final map = {'p1': p1, 'p2': p2};
      final dedupedMap = PostUtilities.deduplicatePostsMap(map);
      expect(dedupedMap.length, equals(1));
    });
  });
}
