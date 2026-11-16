import 'package:cloud_firestore/cloud_firestore.dart';

import '../../app_config.dart';
import '../../domain/model/user_subscription.dart';
import '../../utils/enums/cancellation_reason.dart';
import '../../utils/enums/subscription_status.dart';
import '../../utils/neom_error_logger.dart';
import 'constants/app_firestore_collection_constants.dart';
import 'constants/app_firestore_constants.dart';
import 'core_firestore_guard.dart';

class UserSubscriptionFirestore {

  CollectionReference<Map<String, dynamic>> get userSubscriptionsReference =>
      FirebaseFirestore.instance.collection(AppFirestoreCollectionConstants.userSubscriptions);

  // Insert a new subscription
  Future<void> insert(UserSubscription subscription) async {
    final cleanId = subscription.subscriptionId.trim();
    if (!CoreFirestoreGuard.isSafeDocId(cleanId)) return;
    try {
      await userSubscriptionsReference.doc(cleanId).set(subscription.toJSON());
      AppConfig.logger.d("Subscription inserted successfully: $cleanId");
    } catch (e, st) {
      NeomErrorLogger.recordError(e, st, module: 'neom_core', operation: 'UserSubscriptionFirestore.insert');
    }
  }

  // Get a subscription by its ID
  Future<UserSubscription?> getById(String subscriptionId) async {
    final cleanId = subscriptionId.trim();
    if (!CoreFirestoreGuard.isSafeDocId(cleanId)) return null;
    try {
      final doc = await userSubscriptionsReference.doc(cleanId).get();
      if (doc.exists && doc.data() != null) {
        AppConfig.logger.d("Subscription retrieved: $cleanId");
        return UserSubscription.fromJSON(doc.data()!);
      } else {
        AppConfig.logger.d("Subscription not found: $cleanId");
      }
    } catch (e, st) {
      NeomErrorLogger.recordError(e, st, module: 'neom_core', operation: 'UserSubscriptionFirestore.getById');
    }
    return null;
  }

  // Get all subscriptions by User ID
  Future<List<UserSubscription>> getByUserId(String userId) async {
    final cleanUserId = userId.trim();
    if (!CoreFirestoreGuard.isSafeDocId(cleanUserId)) return [];
    try {
      final querySnapshot = await userSubscriptionsReference
          .where(AppFirestoreConstants.userId, isEqualTo: cleanUserId)
          .limit(200)
          .get();

      List<UserSubscription> subscriptions = querySnapshot.docs.map((doc) {
        return UserSubscription.fromJSON(doc.data());
      }).toList();

      AppConfig.logger.d("${subscriptions.length} Subscriptions retrieved for user: $cleanUserId");
      return subscriptions;
    } catch (e, st) {
      NeomErrorLogger.recordError(e, st, module: 'neom_core', operation: 'UserSubscriptionFirestore.getByUserId');
      return [];
    }
  }


  // Get all subscriptions
  Future<List<UserSubscription>> getAll() async {
    try {
      final querySnapshot = await userSubscriptionsReference.limit(500).get();
      List<UserSubscription> subscriptions = querySnapshot.docs.map((doc) {
        return UserSubscription.fromJSON(doc.data());
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
    final cleanId = subscriptionId.trim();
    if (!CoreFirestoreGuard.isSafeDocId(cleanId)) return;
    final safeUpdates = CoreFirestoreGuard.sanitizeUpdateMap(
      updates,
      immutableKeys: const {'id', 'subscriptionId', 'userId', 'createdAt', 'createdTime'},
    );
    if (safeUpdates.isEmpty) return;
    try {
      await userSubscriptionsReference.doc(cleanId).update(safeUpdates);
      AppConfig.logger.d("Subscription updated successfully: $cleanId");
    } catch (e, st) {
      NeomErrorLogger.recordError(e, st, module: 'neom_core', operation: 'UserSubscriptionFirestore.update');
    }
  }

  // Remove a subscription by its ID
  Future<void> remove(String subscriptionId) async {
    final cleanId = subscriptionId.trim();
    if (!CoreFirestoreGuard.isSafeDocId(cleanId)) return;
    try {
      await userSubscriptionsReference.doc(cleanId).delete();
      AppConfig.logger.d("Subscription removed successfully: $cleanId");
    } catch (e, st) {
      NeomErrorLogger.recordError(e, st, module: 'neom_core', operation: 'UserSubscriptionFirestore.remove');
    }
  }

  /// Schedule cancellation: keeps subscription active until [endDate], then auto-cancels.
  Future<void> scheduleCancellation(String subscriptionId, int endDateMs) async {
    final cleanId = subscriptionId.trim();
    if (!CoreFirestoreGuard.isSafeDocId(cleanId) || endDateMs <= 0) return;
    try {
      await userSubscriptionsReference.doc(cleanId).update({
        AppFirestoreConstants.status: SubscriptionStatus.active.name,
        AppFirestoreConstants.endReason: CancellationReason.userCancelled.name,
        AppFirestoreConstants.endDate: endDateMs,
      });
      AppConfig.logger.d("Subscription $cleanId scheduled to cancel at $endDateMs");
    } catch (e, st) {
      NeomErrorLogger.recordError(e, st, module: 'neom_core', operation: 'UserSubscriptionFirestore.scheduleCancellation');
    }
  }

  /// Immediately mark a subscription as cancelled.
  Future<void> cancel(String subscriptionId) async {
    final cleanId = subscriptionId.trim();
    if (!CoreFirestoreGuard.isSafeDocId(cleanId)) return;
    try {
      await userSubscriptionsReference.doc(cleanId).update({
        AppFirestoreConstants.status: SubscriptionStatus.cancelled.name,
        AppFirestoreConstants.endReason: CancellationReason.userCancelled.name,
      });
      AppConfig.logger.d("Subscription cancelled successfully: $cleanId");
    } catch (e, st) {
      NeomErrorLogger.recordError(e, st, module: 'neom_core', operation: 'UserSubscriptionFirestore.cancel');
    }
  }
}
