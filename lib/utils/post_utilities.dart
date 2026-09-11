import '../domain/model/post.dart';

class PostUtilities {
  /// Determines if two posts appear to be duplicates based on owner, media, caption, and timing.
  static bool areLikelyDuplicates(Post a, Post b, {int timeThresholdMs = 120000}) {
    if (identical(a, b)) return true;
    if (a.id.isNotEmpty && b.id.isNotEmpty && a.id == b.id) return true;

    // Both must have an ownerId to be considered duplicates of each other
    if (a.ownerId.isEmpty || b.ownerId.isEmpty || a.ownerId != b.ownerId) {
      return false;
    }

    final sameMedia = a.mediaUrl.trim().isNotEmpty && a.mediaUrl.trim() == b.mediaUrl.trim();
    final sameThumbnail = a.thumbnailUrl.trim().isNotEmpty && a.thumbnailUrl.trim() == b.thumbnailUrl.trim();
    final sameReference = a.referenceId.trim().isNotEmpty && a.referenceId.trim() == b.referenceId.trim();

    // Identical media URL, thumbnail URL, or reference ID uploaded by the same owner
    if (sameMedia || sameThumbnail || sameReference) {
      return true;
    }


    // Matching caption & type within time threshold (e.g. 2 minutes)
    final timeDiff = (a.createdTime - b.createdTime).abs();
    final sameCaption = a.caption.trim().isNotEmpty && a.caption.trim() == b.caption.trim();

    if (a.type == b.type && sameCaption && timeDiff <= timeThresholdMs) {
      return true;
    }

    return false;
  }

  /// Filters a list of posts, removing likely duplicate posts while preserving order.
  /// If a duplicate is found, the one with more engagement (likes/comments) is preserved.
  static List<Post> deduplicatePosts(Iterable<Post> posts, {int timeThresholdMs = 120000}) {
    final List<Post> unique = [];
    for (final post in posts) {
      final existingIndex = unique.indexWhere(
        (u) => areLikelyDuplicates(u, post, timeThresholdMs: timeThresholdMs),
      );
      if (existingIndex == -1) {
        unique.add(post);
      } else {
        // Keep the one with more engagement or more complete data
        final existing = unique[existingIndex];
        final existingEngagement = existing.likedProfiles.length + existing.commentIds.length;
        final postEngagement = post.likedProfiles.length + post.commentIds.length;
        if (postEngagement > existingEngagement) {
          unique[existingIndex] = post;
        }
      }
    }
    return unique;
  }

  /// Deduplicates a Map<String, Post>
  static Map<String, Post> deduplicatePostsMap(Map<String, Post> postsMap, {int timeThresholdMs = 120000}) {
    final dedupedList = deduplicatePosts(postsMap.values, timeThresholdMs: timeThresholdMs);
    return {for (var p in dedupedList) p.id: p};
  }
}
