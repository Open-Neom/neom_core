import 'package:cloud_firestore/cloud_firestore.dart';

import '../../app_config.dart';
import '../../domain/model/collection_event.dart';
import '../../utils/neom_error_logger.dart';
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
    } catch (e, st) {
      NeomErrorLogger.recordError(e, st, module: 'neom_core', operation: 'getRecent');
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
    } catch (e, st) {
      NeomErrorLogger.recordError(e, st, module: 'neom_core', operation: 'getBySubscriptionId');
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
    } catch (e, st) {
      NeomErrorLogger.recordError(e, st, module: 'neom_core', operation: 'getByUserId');
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
    } catch (e, st) {
      NeomErrorLogger.recordError(e, st, module: 'neom_core', operation: 'getPaymentFailures');
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
    } catch (e, st) {
      NeomErrorLogger.recordError(e, st, module: 'neom_core', operation: 'insert');
    }
  }
}
