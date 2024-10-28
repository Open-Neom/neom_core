import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/model/user_subscription.dart';
import '../../utils/app_utilities.dart';
import '../../utils/enums/cancellation_reason.dart';
import '../../utils/enums/subscription_status.dart';
import 'constants/app_firestore_collection_constants.dart';
import 'constants/app_firestore_constants.dart';

class UserSubscriptionFirestore {
  
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Insert a new subscription
  Future<void> insert(UserSubscription subscription) async {
    try {
      await _firestore.collection(AppFirestoreCollectionConstants.userSubscriptions)
          .doc(subscription.subscriptionId).set(subscription.toJSON());
      AppUtilities.logger.d("Subscription inserted successfully: ${subscription.subscriptionId}");
    } catch (e) {
      AppUtilities.logger.d("Error inserting subscription: $e");
    }
  }

  // Get a subscription by its ID
  Future<UserSubscription?> getById(String subscriptionId) async {
    try {
      DocumentSnapshot doc = await _firestore.collection(AppFirestoreCollectionConstants.userSubscriptions).doc(subscriptionId).get();
      if (doc.exists) {
        AppUtilities.logger.d("Subscription retrieved: $subscriptionId");
        return UserSubscription.fromJSON(doc.data() as Map<String, dynamic>);
      } else {
        AppUtilities.logger.d("Subscription not found: $subscriptionId");
      }
    } catch (e) {
      AppUtilities.logger.d("Error getting subscription: $e");
    }
    return null;
  }

  // Get all subscriptions by User ID
  Future<List<UserSubscription>> getByUserId(String userId) async {
    try {
      QuerySnapshot querySnapshot = await _firestore
          .collection(AppFirestoreCollectionConstants.userSubscriptions)
          .where(AppFirestoreConstants.userId, isEqualTo: userId)
          .get();

      List<UserSubscription> subscriptions = querySnapshot.docs.map((doc) {
        return UserSubscription.fromJSON(doc.data() as Map<String, dynamic>);
      }).toList();

      AppUtilities.logger.d("Subscriptions retrieved for user: $userId");
      return subscriptions;
    } catch (e) {
      AppUtilities.logger.d("Error getting subscriptions for user: $e");
      return [];
    }
  }


  // Get all subscriptions
  Future<List<UserSubscription>> getAll() async {
    try {
      QuerySnapshot querySnapshot = await _firestore.collection(AppFirestoreCollectionConstants.userSubscriptions).get();
      List<UserSubscription> subscriptions = querySnapshot.docs.map((doc) {
        return UserSubscription.fromJSON(doc.data() as Map<String, dynamic>);
      }).toList();
      AppUtilities.logger.d("All subscriptions retrieved.");
      return subscriptions;
    } catch (e) {
      AppUtilities.logger.d("Error getting all subscriptions: $e");
      return [];
    }
  }

  // Update a subscription by its ID
  Future<void> update(String subscriptionId, Map<String, dynamic> updates) async {
    try {
      await _firestore.collection(AppFirestoreCollectionConstants.userSubscriptions).doc(subscriptionId).update(updates);
      AppUtilities.logger.d("Subscription updated successfully: $subscriptionId");
    } catch (e) {
      AppUtilities.logger.d("Error updating subscription: $e");
    }
  }

  // Remove a subscription by its ID
  Future<void> remove(String subscriptionId) async {
    try {
      await _firestore.collection(AppFirestoreCollectionConstants.userSubscriptions).doc(subscriptionId).delete();
      AppUtilities.logger.d("Subscription removed successfully: $subscriptionId");
    } catch (e) {
      AppUtilities.logger.d("Error removing subscription: $e");
    }
  }

  // Update a subscription by its ID
  Future<void> cancel(String subscriptionId) async {
    try {
      await _firestore.collection(AppFirestoreCollectionConstants.userSubscriptions).doc(subscriptionId).update({
        AppFirestoreConstants.status: SubscriptionStatus.cancelled.name,
        AppFirestoreConstants.endReason: CancellationReason.userCancelled.name,

      });
      AppUtilities.logger.d("Subscription cancelled successfully: $subscriptionId");
    } catch (e) {
      AppUtilities.logger.d("Error cancelling subscription: $e");
    }
  }
}
