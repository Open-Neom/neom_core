
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
  final globalActivityFeedReference = FirebaseFirestore.instance.collection(AppFirestoreCollectionConstants.globalActivityFeed);

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

    if (activityReferenceId.isEmpty) {
      AppConfig.logger.w("activityReferenceId is empty, skipping removal");
      return;
    }

    try {
      // OPTIMIZED: Use where query instead of fetching all activities
      QuerySnapshot querySnapshot = await activityFeedReference
          .doc(ownerId).collection(AppFirestoreCollectionConstants.activityFeedItems)
          .where(AppFirestoreConstants.activityReferenceId, isEqualTo: activityReferenceId)
          .where(AppFirestoreConstants.activityFeedType, isEqualTo: activityFeedType.name)
          .limit(10) // Usually only a few activities per reference
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        AppConfig.logger.d("Found ${querySnapshot.docs.length} activities to remove");
        for (var activitySnapshot in querySnapshot.docs) {
          await activitySnapshot.reference.delete();
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

  /// OPTIMIZED: Future-based method to get unread notifications count once.
  /// Use this instead of streams for polling-based updates to reduce Firestore reads.
  Future<int> getUnreadNotificationsCount(String profileId) async {
    AppConfig.logger.t("Getting unread notifications count for profile $profileId");

    try {
      // Use count() aggregation if available (Firestore 3.x+), otherwise use limited query
      final querySnapshot = await activityFeedReference
          .doc(profileId)
          .collection(AppFirestoreCollectionConstants.activityFeedItems)
          .where(AppFirestoreConstants.unread, isEqualTo: true)
          .limit(20) // OPTIMIZED: Reduced limit - only need to know if there are unread items
          .get();

      final count = querySnapshot.docs.length;
      AppConfig.logger.d("Unread notifications count: $count");
      return count;
    } catch (e) {
      AppConfig.logger.e("Error getting unread notifications count: $e");
      return 0;
    }
  }

  /// Stream para obtener el conteo de notificaciones sin leer en tiempo real.
  /// DEPRECATED: Use getUnreadNotificationsCount() with polling instead to reduce reads.
  /// Limita a 100 para evitar lecturas excesivas - si hay más de 99, muestra "99+"
  @Deprecated('Use getUnreadNotificationsCount() with polling instead to reduce Firestore reads')
  Stream<int> getUnreadNotificationsCountStream(String profileId) {
    AppConfig.logger.t("Starting unread notifications count stream for profile $profileId");

    return activityFeedReference
        .doc(profileId)
        .collection(AppFirestoreCollectionConstants.activityFeedItems)
        .where(AppFirestoreConstants.unread, isEqualTo: true)
        .limit(100) // Limit to reduce Firestore reads
        .snapshots()
        .map((snapshot) {
      final count = snapshot.docs.length;
      AppConfig.logger.d("Unread notifications count (stream): $count");
      return count;
    });
  }

  /// Insert a GLOBAL activity feed notification.
  /// Global notifications are stored once and downloaded by all users.
  /// They are mixed with personal notifications on the client side.
  Future<String> insertGlobal(ActivityFeed activityFeed) async {
    AppConfig.logger.d("Inserting GLOBAL activity feed: ${activityFeed.activityFeedType}");
    String activityFeedId = "";

    try {
      DocumentReference documentReference = await globalActivityFeedReference
          .add(activityFeed.toJSON());

      activityFeedId = documentReference.id;
      AppConfig.logger.i("Global notification created with id: $activityFeedId");
    } catch (e) {
      AppConfig.logger.e("Error inserting global notification: $e");
    }

    return activityFeedId;
  }

  /// Retrieve GLOBAL activity feed notifications.
  /// These are notifications that all users should see.
  /// [lastCheckTime] - Only get notifications after this timestamp (milliseconds)
  /// [limit] - Maximum number of notifications to retrieve
  Future<List<ActivityFeed>> retrieveGlobal({int lastCheckTime = 0, int limit = 50}) async {
    AppConfig.logger.t("Retrieving global notifications since $lastCheckTime");
    List<ActivityFeed> globalFeedItems = [];

    try {
      Query query = globalActivityFeedReference
          .orderBy(AppFirestoreConstants.createdTime, descending: true)
          .limit(limit);

      // If lastCheckTime is provided, only get newer notifications
      if (lastCheckTime > 0) {
        query = query.where(AppFirestoreConstants.createdTime, isGreaterThan: lastCheckTime);
      }

      QuerySnapshot querySnapshot = await query.get();

      for (var doc in querySnapshot.docs) {
        globalFeedItems.add(ActivityFeed.fromJSON(doc.data())..id = doc.id);
      }

      AppConfig.logger.d("Retrieved ${globalFeedItems.length} global notifications");
    } catch (e) {
      AppConfig.logger.e("Error retrieving global notifications: $e");
    }

    return globalFeedItems;
  }

  /// Insert multiple activity feeds using batched writes.
  /// Firestore allows up to 500 operations per batch.
  /// This is much more efficient than individual inserts.
  Future<void> insertBatch(List<ActivityFeed> activityFeeds) async {
    if (activityFeeds.isEmpty) return;

    AppConfig.logger.d("Inserting ${activityFeeds.length} activity feeds in batch");

    try {
      // Firestore batch limit is 500 operations
      const batchLimit = 500;
      final batches = <WriteBatch>[];
      var currentBatch = FirebaseFirestore.instance.batch();
      var operationCount = 0;

      for (final activityFeed in activityFeeds) {
        // Skip if profile is the owner (no self-notifications)
        if (activityFeed.profileId == activityFeed.ownerId) continue;

        final docRef = activityFeedReference
            .doc(activityFeed.ownerId)
            .collection(AppFirestoreCollectionConstants.activityFeedItems)
            .doc(); // Auto-generate ID

        currentBatch.set(docRef, activityFeed.toJSON());
        operationCount++;

        // If we hit the batch limit, save this batch and start a new one
        if (operationCount >= batchLimit) {
          batches.add(currentBatch);
          currentBatch = FirebaseFirestore.instance.batch();
          operationCount = 0;
        }
      }

      // Add the last batch if it has operations
      if (operationCount > 0) {
        batches.add(currentBatch);
      }

      // Commit all batches
      await Future.wait(batches.map((batch) => batch.commit()));

      AppConfig.logger.d("Successfully inserted ${activityFeeds.length} activity feeds in ${batches.length} batch(es)");
    } catch (e) {
      AppConfig.logger.e("Error inserting activity feeds batch: $e");
    }
  }

}
