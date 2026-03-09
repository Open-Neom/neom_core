import 'package:cloud_firestore/cloud_firestore.dart';

import '../../app_config.dart';
import '../../domain/model/subscription_event.dart';
import 'constants/app_firestore_collection_constants.dart';

class SubscriptionEventFirestore {

  final _collection = FirebaseFirestore.instance
      .collection(AppFirestoreCollectionConstants.subscriptionEvents);

  /// Get recent events (for ERP alert feed)
  Future<List<SubscriptionEvent>> getRecent({int limit = 50}) async {
    try {
      final snapshot = await _collection
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();
      return snapshot.docs
          .map((doc) => SubscriptionEvent.fromJSON(doc.data()))
          .toList();
    } catch (e) {
      AppConfig.logger.e("Error getting recent subscription events: $e");
      return [];
    }
  }

  /// Get only alert events (COO/CEO flagged)
  Future<List<SubscriptionEvent>> getAlerts({int limit = 20}) async {
    try {
      final snapshot = await _collection
          .where('alertCOO', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();
      return snapshot.docs
          .map((doc) => SubscriptionEvent.fromJSON(doc.data()))
          .toList();
    } catch (e) {
      AppConfig.logger.e("Error getting alert subscription events: $e");
      return [];
    }
  }

  /// Get events for a specific subscription
  Future<List<SubscriptionEvent>> getBySubscriptionId(String subscriptionId) async {
    try {
      final snapshot = await _collection
          .where('subscriptionId', isEqualTo: subscriptionId)
          .orderBy('createdAt', descending: true)
          .get();
      return snapshot.docs
          .map((doc) => SubscriptionEvent.fromJSON(doc.data()))
          .toList();
    } catch (e) {
      AppConfig.logger.e("Error getting events for subscription: $e");
      return [];
    }
  }

  /// Insert event (used by Cloud Functions webhook handler)
  Future<void> insert(SubscriptionEvent event) async {
    try {
      final docRef = event.id.isNotEmpty
          ? _collection.doc(event.id)
          : _collection.doc();
      if (event.id.isEmpty) event.id = docRef.id;
      await docRef.set(event.toJSON());
      AppConfig.logger.d("Subscription event inserted: ${event.id}");
    } catch (e) {
      AppConfig.logger.e("Error inserting subscription event: $e");
    }
  }
}
