
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/model/activity_feed.dart';
import '../../domain/repository/activity_feed_repository.dart';
import '../../utils/app_utilities.dart';
import '../../utils/constants/app_constants.dart';
import '../../utils/enums/activity_feed_type.dart';
import 'constants/app_firestore_collection_constants.dart';
import 'constants/app_firestore_constants.dart';

class ActivityFeedFirestore implements ActivityFeedRepository {

  var logger = AppUtilities.logger;

  final activityFeedReference = FirebaseFirestore.instance.collection(AppFirestoreCollectionConstants.activityFeed);
  final feedItemsReference = FirebaseFirestore.instance.collection(AppFirestoreCollectionConstants.activityFeedItems);

  @override
  Future<void> removeActivityById(String ownerId, String activityFeedId) async {

    logger.d("");

    try {
      activityFeedReference.doc(ownerId)
          .collection(AppFirestoreCollectionConstants.activityFeedItems)
          .doc(activityFeedId).get()
          .then((doc) async {
            if (doc.exists) await doc.reference.delete();
          });
    } catch (e) {
      logger.e(e.toString());
    }
  }


  @override
  Future<void> removeByReferenceActivity(String ownerId, ActivityFeedType activityFeedType,
      {String activityReferenceId = ""}) async {

    logger.d("");

    try {
      QuerySnapshot querySnapshot = await activityFeedReference
          .doc(ownerId).collection(AppFirestoreCollectionConstants.activityFeedItems)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        logger.d("Snapshot is not empty");
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
      logger.e(e.toString());
    }
  }


  @override
  Future<String> insert(ActivityFeed activityFeed) async {
    //add only activity my by other user (to avoid getting notification for our own like)
    logger.v("Insert Activity Feed");
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
      logger.e(e.toString());
    }

    return activityFeedId;
  }


  @override
  Future<List<ActivityFeed>> retrieve(String profileId) async {

    logger.v("");
    List<ActivityFeed> feedItems=[];

    try {
      QuerySnapshot querySnapshot = await activityFeedReference.doc(profileId)
          .collection(AppFirestoreCollectionConstants.activityFeedItems)
          .orderBy(AppFirestoreConstants.createdTime, descending: true)
          .limit(AppConstants.activityFeedLimit)
          .get();

      for (var doc in querySnapshot.docs) {
        feedItems.add(ActivityFeed.fromJSON(doc.data())..id = doc.id);
      }
    } catch (e) {
      logger.e(e.toString());
    }

    return feedItems;
  }


  @override
  Future<bool> removePostActivity(String postId) async {
    logger.d("");
    bool postActivityFeedRemoved = false;
    QuerySnapshot querySnapshot = await feedItemsReference
        .where(AppFirestoreConstants.activityFeedId, isEqualTo: postId)
        .get();

    int activityFeedCounter = 0;
    if (querySnapshot.docs.isNotEmpty) {
      logger.d("Snapshot is not empty ${querySnapshot.docs.length} results found");
      for (var snapshot in querySnapshot.docs) {
        await snapshot.reference.delete();
        activityFeedCounter++;
      }

      postActivityFeedRemoved = true;
      logger.d("$activityFeedCounter were removed from feed Collection");
    }

    return postActivityFeedRemoved;

  }


  @override
  Future<bool> removeEventActivity(String eventId) async {
    logger.d("");
    bool eventActivityFeedRemoved = false;
    QuerySnapshot querySnapshot = await feedItemsReference
        .where(AppFirestoreConstants.activityFeedId, isEqualTo: eventId)
        .get();

    int activityFeedCounter = 0;
    if (querySnapshot.docs.isNotEmpty) {
      logger.d("Snapshot is not empty ${querySnapshot.docs.length} results found");
      for (var snapshot in querySnapshot.docs) {
        await snapshot.reference.delete();
        activityFeedCounter++;
      }

      eventActivityFeedRemoved = true;
      logger.d("$activityFeedCounter were removed from feed Collection");
    }

    return eventActivityFeedRemoved;
  }


  @override
  Future<bool> removeRequestActivity(String requestId) async {
    logger.d("");
    bool eventActivityFeedRemoved = false;
    QuerySnapshot querySnapshot = await feedItemsReference
        .where(AppFirestoreConstants.activityFeedId, isEqualTo: requestId)
        .get();

    int activityFeedCounter = 0;
    if (querySnapshot.docs.isNotEmpty) {
      logger.d("Snapshot is not empty ${querySnapshot.docs.length} results found");

      for (var snapshot in querySnapshot.docs) {
        await snapshot.reference.delete();
        activityFeedCounter++;
      }

      eventActivityFeedRemoved = true;
      logger.d("$activityFeedCounter were removed from feed Collection");
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
    logger.d("");

    try {
      activityFeedReference.doc(ownerId)
          .collection(AppFirestoreCollectionConstants.activityFeedItems)
          .doc(activityFeedId).update({
            AppFirestoreConstants.unread: false
          });
    } catch (e) {
      logger.e(e.toString());
    }
  }


}
