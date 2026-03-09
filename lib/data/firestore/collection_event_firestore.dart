import 'package:cloud_firestore/cloud_firestore.dart';

import '../../app_config.dart';
import '../../domain/model/collection_event.dart';
import 'constants/app_firestore_collection_constants.dart';

class CollectionEventFirestore {

  final _collection = FirebaseFirestore.instance
      .collection(AppFirestoreCollectionConstants.collectionEvents);

  /// Get recent collection events (for ERP cobranza panel)
  Future<List<CollectionEvent>> getRecent({int limit = 50}) async {
    try {
      final snapshot = await _collection
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();
      return snapshot.docs
          .map((doc) => CollectionEvent.fromJSON(doc.data()))
          .toList();
    } catch (e) {
      AppConfig.logger.e("Error getting recent collection events: $e");
      return [];
    }
  }

  /// Get events for a specific subscription
  Future<List<CollectionEvent>> getBySubscriptionId(String subscriptionId) async {
    try {
      final snapshot = await _collection
          .where('subscriptionId', isEqualTo: subscriptionId)
          .orderBy('createdAt', descending: true)
          .get();
      return snapshot.docs
          .map((doc) => CollectionEvent.fromJSON(doc.data()))
          .toList();
    } catch (e) {
      AppConfig.logger.e("Error getting events for subscription: $e");
      return [];
    }
  }

  /// Get events for a specific user
  Future<List<CollectionEvent>> getByUserId(String userId) async {
    try {
      final snapshot = await _collection
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();
      return snapshot.docs
          .map((doc) => CollectionEvent.fromJSON(doc.data()))
          .toList();
    } catch (e) {
      AppConfig.logger.e("Error getting collection events for user: $e");
      return [];
    }
  }

  /// Get only payment_failed events
  Future<List<CollectionEvent>> getPaymentFailures({int limit = 30}) async {
    try {
      final snapshot = await _collection
          .where('type', isEqualTo: 'payment_failed')
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();
      return snapshot.docs
          .map((doc) => CollectionEvent.fromJSON(doc.data()))
          .toList();
    } catch (e) {
      AppConfig.logger.e("Error getting payment failure events: $e");
      return [];
    }
  }

  /// Insert a collection event
  Future<void> insert(CollectionEvent event) async {
    try {
      final docRef = event.id.isNotEmpty
          ? _collection.doc(event.id)
          : _collection.doc();
      if (event.id.isEmpty) event.id = docRef.id;
      await docRef.set(event.toJSON());
      AppConfig.logger.d("Collection event inserted: ${event.id}");
    } catch (e) {
      AppConfig.logger.e("Error inserting collection event: $e");
    }
  }
}
