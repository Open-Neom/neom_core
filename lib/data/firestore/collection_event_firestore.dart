import 'package:cloud_firestore/cloud_firestore.dart';

import '../../app_config.dart';
import '../../domain/model/collection_event.dart';
import '../../utils/neom_error_logger.dart';
import 'constants/app_firestore_collection_constants.dart';
import 'core_firestore_guard.dart';

class CollectionEventFirestore {

  CollectionReference<Map<String, dynamic>> get _collection =>
      FirebaseFirestore.instance
          .collection(AppFirestoreCollectionConstants.collectionEvents);

  /// Get recent collection events (for ERP cobranza panel)
  Future<List<CollectionEvent>> getRecent({int limit = 50}) async {
    final safeLimit = CoreFirestoreGuard.clampLimit(limit);
    try {
      final snapshot = await _collection
          .orderBy('createdAt', descending: true)
          .limit(safeLimit)
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
    final cleanId = subscriptionId.trim();
    if (!CoreFirestoreGuard.isSafeDocId(cleanId)) return [];
    try {
      final snapshot = await _collection
          .where('subscriptionId', isEqualTo: cleanId)
          .orderBy('createdAt', descending: true)
          .limit(200)
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
    final cleanId = userId.trim();
    if (!CoreFirestoreGuard.isSafeDocId(cleanId)) return [];
    try {
      final snapshot = await _collection
          .where('userId', isEqualTo: cleanId)
          .orderBy('createdAt', descending: true)
          .limit(200)
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
    final safeLimit = CoreFirestoreGuard.clampLimit(limit, defaultLimit: 30);
    try {
      final snapshot = await _collection
          .where('type', isEqualTo: 'payment_failed')
          .orderBy('createdAt', descending: true)
          .limit(safeLimit)
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
      AppConfig.logger.d("Collection event inserted: ${event.id}");
    } catch (e, st) {
      NeomErrorLogger.recordError(e, st, module: 'neom_core', operation: 'insert');
    }
  }

  /// Marks a collection event as having had its WhatsApp reminder sent. Used
  /// from the Cobranza panel so ops can confirm contact was made when the
  /// automated send didn't trigger or was done manually.
  Future<bool> markWhatsappSent(String eventId, {String messageId = 'manual'}) async {
    final cleanId = eventId.trim();
    if (!CoreFirestoreGuard.isSafeDocId(cleanId)) return false;
    try {
      await _collection.doc(cleanId).update({
        'whatsappSent': true,
        'whatsappMessageId': messageId,
      });
      return true;
    } catch (e, st) {
      NeomErrorLogger.recordError(e, st, module: 'neom_core', operation: 'markWhatsappSent');
      return false;
    }
  }
}
