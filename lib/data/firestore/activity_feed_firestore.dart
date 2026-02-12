
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../app_config.dart';
import '../../domain/model/activity_feed.dart';
import '../../domain/repository/activity_feed_repository.dart';
import '../../utils/constants/core_constants.dart';
import '../../utils/enums/activity_feed_type.dart';
import 'constants/app_firestore_collection_constants.dart';
import 'constants/app_firestore_constants.dart';

class ActivityFeedFirestore implements ActivityFeedRepository {

  final activityFeedReference = FirebaseFirestore.instance.collection(AppFirestoreCollectionConstants.activityFeed);
  final feedItemsReference = FirebaseFirestore.instance.collection(AppFirestoreCollectionConstants.activityFeedItems);

  @override
  Future<void> removeActivityById(String ownerId, String activityFeedId) async {
    AppConfig.logger.d("removeActivityById for ownerId $ownerId & activityFeedId $activityFeedId");

    if (ownerId.isEmpty || activityFeedId.isEmpty) {
      AppConfig.logger.w("Owner ID or Activity Feed ID is empty");
      return;
    }

    try {
      // OPTIMIZED: Use await instead of .then() and direct delete
      final docRef = activityFeedReference.doc(ownerId)
          .collection(AppFirestoreCollectionConstants.activityFeedItems)
          .doc(activityFeedId);
      final doc = await docRef.get();
      if (doc.exists) await docRef.delete();
    } catch (e) {
      AppConfig.logger.e(e.toString());
    }
  }


  @override
  Future<void> removeByReferenceActivity(String ownerId, ActivityFeedType activityFeedType,
      {String activityReferenceId = ""}) async {

    AppConfig.logger.d("removeByReferenceActivity for ownerId $ownerId,"
        " activityFeedType $activityFeedType, activityReferenceId $activityReferenceId");


    try {
      QuerySnapshot querySnapshot = await activityFeedReference
          .doc(ownerId).collection(AppFirestoreCollectionConstants.activityFeedItems)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        AppConfig.logger.d("Snapshot is not empty");
        for (var activitySnapshot in querySnapshot.docs) {
          ActivityFeed activityFeed = ActivityFeed
              .fromJSON(activitySnapshot.data());
          if (activityFeed.activityReferenceId == activityReferenceId &&
              activityFeed.activityFeedType == activityFeedType) {
            await activitySnapshot.reference.delete();
          }
        }
      }
    } catch (e) {
      AppConfig.logger.e(e.toString());
    }
  }


  @override
  Future<String> insert(ActivityFeed activityFeed) async {
    //add only activity my by other user (to avoid getting notification for our own like)
    AppConfig.logger.d("Inserting activity feed for ${activityFeed.ownerId} with type ${activityFeed.activityFeedType}");
    bool isNotActivityOwner = activityFeed.profileId != activityFeed.ownerId;
    String activityFeedId = "";

    try {
      if(isNotActivityOwner) {
        DocumentReference documentReference = await activityFeedReference
            .doc(activityFeed.ownerId)
            .collection(AppFirestoreCollectionConstants.activityFeedItems)
            .add(activityFeed.toJSON());

        activityFeedId = documentReference.id;
      }
    } catch (e) {
      AppConfig.logger.e(e.toString());
    }

    return activityFeedId;
  }


  @override
  Future<List<ActivityFeed>> retrieve(String profileId) async {

    AppConfig.logger.t("");
    List<ActivityFeed> feedItems=[];

    try {
      QuerySnapshot querySnapshot = await activityFeedReference.doc(profileId)
          .collection(AppFirestoreCollectionConstants.activityFeedItems)
          .orderBy(AppFirestoreConstants.createdTime, descending: true)
          .limit(CoreConstants.activityFeedLimit)
          .get();

      for (var doc in querySnapshot.docs) {
        feedItems.add(ActivityFeed.fromJSON(doc.data())..id = doc.id);
      }
    } catch (e) {
      AppConfig.logger.e(e.toString());
    }

    return feedItems;
  }


  @override
  Future<bool> removePostActivity(String postId) async {
    AppConfig.logger.t("Removing post $postId");
    bool postActivityFeedRemoved = false;
    QuerySnapshot querySnapshot = await feedItemsReference
        .where(AppFirestoreConstants.activityFeedId, isEqualTo: postId)
        .get();

    int activityFeedCounter = 0;
    if (querySnapshot.docs.isNotEmpty) {
      AppConfig.logger.d("Snapshot is not empty ${querySnapshot.docs.length} results found");
      for (var snapshot in querySnapshot.docs) {
        await snapshot.reference.delete();
        activityFeedCounter++;
      }

      postActivityFeedRemoved = true;
      AppConfig.logger.d("$activityFeedCounter were removed from feed Collection");
    }

    return postActivityFeedRemoved;

  }


  @override
  Future<bool> removeEventActivity(String eventId) async {
    AppConfig.logger.t("Remove event activity for $eventId");
    bool eventActivityFeedRemoved = false;
    QuerySnapshot querySnapshot = await feedItemsReference
        .where(AppFirestoreConstants.activityFeedId, isEqualTo: eventId)
        .get();

    int activityFeedCounter = 0;
    if (querySnapshot.docs.isNotEmpty) {
      AppConfig.logger.d("Snapshot is not empty ${querySnapshot.docs.length} results found");
      for (var snapshot in querySnapshot.docs) {
        await snapshot.reference.delete();
        activityFeedCounter++;
      }

      eventActivityFeedRemoved = true;
      AppConfig.logger.d("$activityFeedCounter were removed from feed Collection");
    }

    return eventActivityFeedRemoved;
  }


  @override
  Future<bool> removeRequestActivity(String requestId) async {
    AppConfig.logger.d("");
    bool eventActivityFeedRemoved = false;
    QuerySnapshot querySnapshot = await feedItemsReference
        .where(AppFirestoreConstants.activityFeedId, isEqualTo: requestId)
        .get();

    int activityFeedCounter = 0;
    if (querySnapshot.docs.isNotEmpty) {
      AppConfig.logger.d("Snapshot is not empty ${querySnapshot.docs.length} results found");

      for (var snapshot in querySnapshot.docs) {
        await snapshot.reference.delete();
        activityFeedCounter++;
      }

      eventActivityFeedRemoved = true;
      AppConfig.logger.d("$activityFeedCounter were removed from feed Collection");
    }

    return eventActivityFeedRemoved;
  }


  @override
  Future<bool> addFollowToActivity(String profileId, ActivityFeed activityFeed) {
    // TODO: implement addFollowToActivityFeed
    throw UnimplementedError();
  }


  @override
  Future<bool> addFulfilledEventActivity(String eventId) {
    // TODO: implement addFulfilledEventActivity
    throw UnimplementedError();
  }

  @override
  Future<void> setAsRead({required String ownerId, required String activityFeedId}) async {
    AppConfig.logger.d("");

    try {
      activityFeedReference.doc(ownerId)
          .collection(AppFirestoreCollectionConstants.activityFeedItems)
          .doc(activityFeedId).update({
            AppFirestoreConstants.unread: false
          });
    } catch (e) {
      AppConfig.logger.e(e.toString());
    }
  }

  /// Stream para obtener el conteo de notificaciones sin leer en tiempo real.
  Stream<int> getUnreadNotificationsCountStream(String profileId) {
    AppConfig.logger.t("Starting unread notifications count stream for profile $profileId");

    return activityFeedReference
        .doc(profileId)
        .collection(AppFirestoreCollectionConstants.activityFeedItems)
        .where(AppFirestoreConstants.unread, isEqualTo: true)
        .snapshots()
        .map((snapshot) {
      final count = snapshot.docs.length;
      AppConfig.logger.d("Unread notifications count (stream): $count");
      return count;
    });
  }

}
