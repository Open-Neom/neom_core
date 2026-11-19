import '../model/post_comment.dart';

/// Canonical Open Neom contract for reading and mutating post comments.
///
/// Implemented by `CommentFirestore` (in `neom_posts`) for cloud apps and by
/// `MeshCommentRepository` / `HybridCommentRepository` (in `neom_mesh`) for
/// offline-first and hybrid mesh apps.
abstract class CommentRepository {
  Future<String> insert(PostComment comment);
  Future<bool> remove(PostComment comment);

  /// Paginated comment retrieval ordered by creation time.
  Future<List<PostComment>> retrieveComments({
    required String postId,
    int limit = 50,
    int? lastCreatedTime,
  });

  Future<bool> handleLikeComment(
    String profileId,
    String commentId,
    bool isLiked,
  );
}
