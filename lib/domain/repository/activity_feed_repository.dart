import '../../utils/enums/activity_feed_type.dart';
import '../model/activity_feed.dart';

abstract class ActivityFeedRepository {

  Future<void> removeActivityById(String ownerId, String activityFeedId);
  Future<void> removeByReferenceActivity(String ownerId, ActivityFeedType activityFeedType, {String activityReferenceId = ""});
  Future<bool> addFollowToActivity(String profileId, ActivityFeed activityFeed);
  Future<String> insert(ActivityFeed activityFeed);
  Future<List<ActivityFeed>> retrieve(String profileId);

  Future<bool> removePostActivity(String postId);
  Future<bool> removeEventActivity(String eventId);
  Future<bool> removeRequestActivity(String requestId);

  Future<bool> addFulfilledEventActivity(String eventId);
  Future<void> setAsRead({required String ownerId, required String activityFeedId});


}
