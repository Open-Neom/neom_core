
import '../model/app_profile.dart';
import '../model/post.dart';

abstract class PostDetailsService {

  Future<void> retrievePost();
  void showPostInfo(bool show);
  bool isLikedPost(Post post);
  Future<void> handleLikePost(Post post);
  bool verifyIfCommented(List<String> postCommentIds, List<String> profileCommentIds);
  void setCommentToPost(String commentId);
  
  set profile(AppProfile profile);  
  set post(Post post);

}
