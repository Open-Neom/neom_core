import 'package:cloud_firestore/cloud_firestore.dart';

import '../../app_config.dart';
import '../../domain/model/subscription_event.dart';
import '../../utils/neom_error_logger.dart';
import 'constants/app_firestore_collection_constants.dart';
import 'core_firestore_guard.dart';

class SubscriptionEventFirestore {

  CollectionReference<Map<String, dynamic>> get _collection =>
      FirebaseFirestore.instance
          .collection(AppFirestoreCollectionConstants.subscriptionEvents);

  /// Get recent events (for ERP alert feed)
  Future<List<SubscriptionEvent>> getRecent({int limit = 50}) async {
    final safeLimit = CoreFirestoreGuard.clampLimit(limit);
    try {
      final snapshot = await _collection
          .orderBy('createdAt', descending: true)
          .limit(safeLimit)
          .get();
      return snapshot.docs
          .map((doc) => SubscriptionEvent.fromJSON(doc.data()))
          .toList();
    } catch (e, st) {
      NeomErrorLogger.recordError(e, st, module: 'neom_core', operation: 'SubscriptionEventFirestore.getRecent');
      return [];
    }
  }

  /// Get only alert events (COO/CEO flagged)
  Future<List<SubscriptionEvent>> getAlerts({int limit = 20}) async {
    final safeLimit = CoreFirestoreGuard.clampLimit(limit, defaultLimit: 20);
    try {
      final snapshot = await _collection
          .where('alertCOO', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .limit(safeLimit)
          .get();
      return snapshot.docs
          .map((doc) => SubscriptionEvent.fromJSON(doc.data()))
          .toList();
    } catch (e, st) {
      NeomErrorLogger.recordError(e, st, module: 'neom_core', operation: 'SubscriptionEventFirestore.getAlerts');
      return [];
    }
  }

  /// Get events for a specific subscription
  Future<List<SubscriptionEvent>> getBySubscriptionId(String subscriptionId) async {
    final cleanId = subscriptionId.trim();
    if (!CoreFirestoreGuard.isSafeDocId(cleanId)) return [];
    try {
      final snapshot = await _collection
          .where('subscriptionId', isEqualTo: cleanId)
          .orderBy('createdAt', descending: true)
          .limit(200)
          .get();
      return snapshot.docs
          .map((doc) => SubscriptionEvent.fromJSON(doc.data()))
          .toList();
    } catch (e, st) {
      NeomErrorLogger.recordError(e, st, module: 'neom_core', operation: 'SubscriptionEventFirestore.getBySubscriptionId');
      return [];
    }
  }

  /// Insert event (used by Cloud Functions webhook handler)
  Future<void> insert(SubscriptionEvent event) async {
    try {
      DocumentReference<Map<String, dynamic>> docRef;
      if (event.id.isNotEmpty) {
        final cleanId = event.id.trim();
        if (!CoreFirestoreGuard.isSafeDocId(cleanId)) return;
        event.id = cleanId;
        docRef = _collection.doc(cleanId);
      } else {
        docRef = _collection.doc();
        event.id = docRef.id;
      }
      await docRef.set(event.toJSON());
      AppConfig.logger.d("Subscription event inserted: ${event.id}");
    } catch (e, st) {
      NeomErrorLogger.recordError(e, st, module: 'neom_core', operation: 'SubscriptionEventFirestore.insert');
    }
  }
}
