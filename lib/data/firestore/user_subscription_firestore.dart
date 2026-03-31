import 'package:cloud_firestore/cloud_firestore.dart';

import '../../app_config.dart';
import '../../domain/model/user_subscription.dart';
import '../../utils/enums/cancellation_reason.dart';
import '../../utils/enums/subscription_status.dart';
import '../../utils/neom_error_logger.dart';
import 'constants/app_firestore_collection_constants.dart';
import 'constants/app_firestore_constants.dart';

class UserSubscriptionFirestore {

  final userSubscriptionsReference = FirebaseFirestore.instance.collection(AppFirestoreCollectionConstants.userSubscriptions);

  // Insert a new subscription
  Future<void> insert(UserSubscription subscription) async {
    try {
      await userSubscriptionsReference.doc(subscription.subscriptionId).set(subscription.toJSON());
      AppConfig.logger.d("Subscription inserted successfully: ${subscription.subscriptionId}");
    } catch (e, st) {
      NeomErrorLogger.recordError(e, st, module: 'neom_core', operation: 'UserSubscriptionFirestore.insert');
    }
  }

  // Get a subscription by its ID
  Future<UserSubscription?> getById(String subscriptionId) async {
    try {
      DocumentSnapshot doc = await userSubscriptionsReference.doc(subscriptionId).get();
      if (doc.exists) {
        AppConfig.logger.d("Subscription retrieved: $subscriptionId");
        return UserSubscription.fromJSON(doc.data() as Map<String, dynamic>);
      } else {
        AppConfig.logger.d("Subscription not found: $subscriptionId");
      }
    } catch (e, st) {
      NeomErrorLogger.recordError(e, st, module: 'neom_core', operation: 'UserSubscriptionFirestore.getById');
    }
    return null;
  }

  // Get all subscriptions by User ID
  Future<List<UserSubscription>> getByUserId(String userId) async {
    try {
      QuerySnapshot querySnapshot = await userSubscriptionsReference
          .where(AppFirestoreConstants.userId, isEqualTo: userId)
          .get();

      List<UserSubscription> subscriptions = querySnapshot.docs.map((doc) {
        return UserSubscription.fromJSON(doc.data() as Map<String, dynamic>);
      }).toList();

      AppConfig.logger.d("${subscriptions.length} Subscriptions retrieved for user: $userId");
      return subscriptions;
    } catch (e, st) {
      NeomErrorLogger.recordError(e, st, module: 'neom_core', operation: 'UserSubscriptionFirestore.getByUserId');
      return [];
    }
  }


  // Get all subscriptions
  Future<List<UserSubscription>> getAll() async {
    try {
      QuerySnapshot querySnapshot = await userSubscriptionsReference.get();
      List<UserSubscription> subscriptions = querySnapshot.docs.map((doc) {
        return UserSubscription.fromJSON(doc.data() as Map<String, dynamic>);
      }).toList();
      AppConfig.logger.d("All subscriptions retrieved.");
      return subscriptions;
    } catch (e, st) {
      NeomErrorLogger.recordError(e, st, module: 'neom_core', operation: 'UserSubscriptionFirestore.getAll');
      return [];
    }
  }

  // Update a subscription by its ID
  Future<void> update(String subscriptionId, Map<String, dynamic> updates) async {
    try {
      await userSubscriptionsReference.doc(subscriptionId).update(updates);
      AppConfig.logger.d("Subscription updated successfully: $subscriptionId");
    } catch (e, st) {
      NeomErrorLogger.recordError(e, st, module: 'neom_core', operation: 'UserSubscriptionFirestore.update');
    }
  }

  // Remove a subscription by its ID
  Future<void> remove(String subscriptionId) async {
    try {
      await userSubscriptionsReference.doc(subscriptionId).delete();
      AppConfig.logger.d("Subscription removed successfully: $subscriptionId");
    } catch (e, st) {
      NeomErrorLogger.recordError(e, st, module: 'neom_core', operation: 'UserSubscriptionFirestore.remove');
    }
  }

  /// Schedule cancellation: keeps subscription active until [endDate], then auto-cancels.
  Future<void> scheduleCancellation(String subscriptionId, int endDateMs) async {
    try {
      await userSubscriptionsReference.doc(subscriptionId).update({
        AppFirestoreConstants.status: SubscriptionStatus.active.name,
        AppFirestoreConstants.endReason: CancellationReason.userCancelled.name,
        AppFirestoreConstants.endDate: endDateMs,
      });
      AppConfig.logger.d("Subscription $subscriptionId scheduled to cancel at $endDateMs");
    } catch (e, st) {
      NeomErrorLogger.recordError(e, st, module: 'neom_core', operation: 'UserSubscriptionFirestore.scheduleCancellation');
    }
  }

  /// Immediately mark a subscription as cancelled.
  Future<void> cancel(String subscriptionId) async {
    try {
      await userSubscriptionsReference.doc(subscriptionId).update({
        AppFirestoreConstants.status: SubscriptionStatus.cancelled.name,
        AppFirestoreConstants.endReason: CancellationReason.userCancelled.name,
      });
      AppConfig.logger.d("Subscription cancelled successfully: $subscriptionId");
    } catch (e, st) {
      NeomErrorLogger.recordError(e, st, module: 'neom_core', operation: 'UserSubscriptionFirestore.cancel');
    }
  }
}
