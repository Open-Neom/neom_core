import 'package:flutter/cupertino.dart';
import '../model/post.dart';
import '../model/post_comment.dart';

abstract class TimelineService {

  Future<void> getTimeline({bool removePrevious = false});
  bool isLikedPost(Post post);
  Future<void> handleLikePost(Post post);
  Future<void> hidePost(Post post);
  Future<void> getSponsorsTimeline();
  void removeCommentToPost(String postId, PostComment comment);
  Future<void> removePost(Post post);
  void addCommentToPost(String postId, PostComment newComment);
  void handleLikeOnPost(Post post);
  bool verifyIfCommented(List<String> postCommentIds, List<String> profileCommentIds);
  void removePostFromLists(Post post);
  void removePostsFromTimelineByParams({String postId = '', String ownerId = ''});
  Future<void> showRemovePostAlert(BuildContext context, Post post);
  Future<void> showHidePostAlert(BuildContext context, Post post);
  Future<void> showBlockProfileAlert(BuildContext context, String postOwnerId);
  Future<void> getReleaseItemsFromWoo();
  ScrollController getScrollController();
  double getScrollOffset();
  void setScrollOffset(double offset);
  Future<void> setMainScrollOffset(double offset);
  bool get showAppBar;

}
