import 'package:cloud_firestore/cloud_firestore.dart';

import '../../app_config.dart';
import '../../domain/model/user_subscription.dart';
import '../../utils/enums/cancellation_reason.dart';
import '../../utils/enums/subscription_status.dart';
import '../../utils/neom_error_logger.dart';
import '../api/app_platform_api.dart';
import 'constants/app_firestore_collection_constants.dart';
import 'constants/app_firestore_constants.dart';

class UserSubscriptionFirestore {

  CollectionReference get userSubscriptionsReference => FirebaseFirestore.instance.collection(AppFirestoreCollectionConstants.userSubscriptions);

  // Insert a new subscription
  Future<void> insert(UserSubscription subscription) async {
    if (AppPlatformApi.isEnabled) return;
    try {
      await userSubscriptionsReference.doc(subscription.subscriptionId).set(subscription.toJSON());
      AppConfig.logger.d("Subscription inserted successfully: ${subscription.subscriptionId}");
    } catch (e, st) {
      NeomErrorLogger.recordError(e, st, module: 'neom_core', operation: 'UserSubscriptionFirestore.insert');
    }
  }

  // Get a subscription by its ID
  Future<UserSubscription?> getById(String subscriptionId) async {
    if (AppPlatformApi.isEnabled) {
      try {
        final res = await AppPlatformApi.client('subscriptions').read('getMySubscription', {});
        final items = res['items'];
        if (items is List && items.isNotEmpty) {
          final matched = items.cast<Map>().firstWhere(
            (s) => s['subscriptionId']?.toString() == subscriptionId,
            orElse: () => items.first as Map,
          );
          return UserSubscription.fromJSON(Map<String, dynamic>.from(matched));
        }
      } catch (e, st) {
        NeomErrorLogger.recordError(e, st, module: 'neom_core', operation: 'UserSubscriptionFirestore.getById.platform');
      }
      return null;
    }
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
    if (AppPlatformApi.isEnabled) {
      try {
        final res = await AppPlatformApi.client('subscriptions').read('getMySubscription', {'userId': userId});
        final items = res['items'];
        if (items is List) {
          return items
              .whereType<Map>()
              .map((m) => UserSubscription.fromJSON(Map<String, dynamic>.from(m)))
              .toList();
        }
      } catch (e, st) {
        NeomErrorLogger.recordError(e, st, module: 'neom_core', operation: 'UserSubscriptionFirestore.getByUserId.platform');
      }
      return [];
    }
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
    if (AppPlatformApi.isEnabled) {
      return getByUserId('');
    }
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
    if (AppPlatformApi.isEnabled) return;
    try {
      await userSubscriptionsReference.doc(subscriptionId).update(updates);
      AppConfig.logger.d("Subscription updated successfully: $subscriptionId");
    } catch (e, st) {
      NeomErrorLogger.recordError(e, st, module: 'neom_core', operation: 'UserSubscriptionFirestore.update');
    }
  }

  // Remove a subscription by its ID
  Future<void> remove(String subscriptionId) async {
    if (AppPlatformApi.isEnabled) {
      await cancel(subscriptionId);
      return;
    }
    try {
      await userSubscriptionsReference.doc(subscriptionId).delete();
      AppConfig.logger.d("Subscription removed successfully: $subscriptionId");
    } catch (e, st) {
      NeomErrorLogger.recordError(e, st, module: 'neom_core', operation: 'UserSubscriptionFirestore.remove');
    }
  }

  /// Schedule cancellation: keeps subscription active until [endDate], then auto-cancels.
  Future<void> scheduleCancellation(String subscriptionId, int endDateMs) async {
    if (AppPlatformApi.isEnabled) {
      try {
        await AppPlatformApi.client('subscriptions').mutate(
          'scheduleCancellation',
          {'subscriptionId': subscriptionId, 'endDate': endDateMs},
          durable: false,
        );
      } catch (e, st) {
        NeomErrorLogger.recordError(e, st, module: 'neom_core', operation: 'UserSubscriptionFirestore.scheduleCancellation.platform');
      }
      return;
    }
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
    if (AppPlatformApi.isEnabled) {
      try {
        await AppPlatformApi.client('subscriptions').mutate(
          'cancelSubscription',
          {'subscriptionId': subscriptionId},
          durable: false,
        );
      } catch (e, st) {
        NeomErrorLogger.recordError(e, st, module: 'neom_core', operation: 'UserSubscriptionFirestore.cancel.platform');
      }
      return;
    }
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
