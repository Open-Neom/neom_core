import '../model/post.dart';


abstract class PostRepository {

  Future<String> insert(Post post);
  Future<bool> remove(String profileId, String postId);

  Future<Post> retrieve(String postId);
  Future<List<Post>> retrievePosts();
  Future<bool> handleLikePost(String profileId, String postId, bool isLiked);
  Future<List<Post>> getProfilePosts(String profileId);
  Future<Map<String, Post>> getTimeline();
  ///DEPRECATED Future<Map<String, Post>> getNextTimeline();
  Future<bool> addComment(String postId, String commentId);
  Future<bool> removeComment(String postId, String commentId);
  Future<Post> retrievePostForEvent(String eventId);
  Future<Map<String, Post>> getBlogEntries({String profileId = ""});
  Future<Map<String, Post>> getDiverseTimeline({bool getRecent = true, bool
  getMoreLiked = true, bool getMoreComment = true, bool getReleases = true, bool
  getBlogEntries = true, List<String>? followingIds});

}
