import 'package:cloud_firestore/cloud_firestore.dart';

import '../../app_config.dart';
import '../../domain/model/financial_snapshot.dart';
import '../../utils/neom_error_logger.dart';
import 'constants/app_firestore_collection_constants.dart';
import 'core_firestore_guard.dart';

class FinancialSnapshotFirestore {

  CollectionReference<Map<String, dynamic>> get _collection =>
      FirebaseFirestore.instance
          .collection(AppFirestoreCollectionConstants.financialSnapshots);

  /// Get a specific snapshot by date ID (YYYY-MM-DD)
  Future<FinancialSnapshot?> getById(String snapshotId) async {
    final cleanId = snapshotId.trim();
    if (!CoreFirestoreGuard.isSafeDocId(cleanId)) return null;
    try {
      final doc = await _collection.doc(cleanId).get();
      if (doc.exists && doc.data() != null) {
        return FinancialSnapshot.fromJSON(doc.data()!);
      }
    } catch (e, st) {
      NeomErrorLogger.recordError(e, st, module: 'neom_core', operation: 'FinancialSnapshotFirestore.getById');
    }
    return null;
  }

  /// Get the latest snapshot (most recent by computedAt)
  Future<FinancialSnapshot?> getLatest() async {
    try {
      final snapshot = await _collection
          .orderBy('computedAt', descending: true)
          .limit(1)
          .get();
      if (snapshot.docs.isNotEmpty) {
        return FinancialSnapshot.fromJSON(snapshot.docs.first.data());
      }
    } catch (e, st) {
      NeomErrorLogger.recordError(e, st, module: 'neom_core', operation: 'FinancialSnapshotFirestore.getLatest');
    }
    return null;
  }

  /// Get snapshots for a date range (for MRR history chart)
  Future<List<FinancialSnapshot>> getRange(String startId, String endId) async {
    final cleanStart = startId.trim();
    final cleanEnd = endId.trim();
    if (!CoreFirestoreGuard.isSafeDocId(cleanStart) ||
        !CoreFirestoreGuard.isSafeDocId(cleanEnd)) {
      return [];
    }
    try {
      final snapshot = await _collection
          .where(FieldPath.documentId, isGreaterThanOrEqualTo: cleanStart)
          .where(FieldPath.documentId, isLessThanOrEqualTo: cleanEnd)
          .orderBy(FieldPath.documentId)
          .limit(1000)
          .get();
      return snapshot.docs
          .map((doc) => FinancialSnapshot.fromJSON(doc.data()))
          .toList();
    } catch (e, st) {
      NeomErrorLogger.recordError(e, st, module: 'neom_core', operation: 'FinancialSnapshotFirestore.getRange');
      return [];
    }
  }

  /// Get the last N snapshots (for charts/forecasting)
  Future<List<FinancialSnapshot>> getLastN(int count) async {
    final safeCount = CoreFirestoreGuard.clampLimit(count, defaultLimit: 30, maxLimit: 365);
    try {
      final snapshot = await _collection
          .orderBy('computedAt', descending: true)
          .limit(safeCount)
          .get();
      return snapshot.docs
          .map((doc) => FinancialSnapshot.fromJSON(doc.data()))
          .toList()
          .reversed
          .toList(); // chronological order
    } catch (e, st) {
      NeomErrorLogger.recordError(e, st, module: 'neom_core', operation: 'FinancialSnapshotFirestore.getLastN');
      return [];
    }
  }

  /// Insert a new snapshot (used by Cloud Functions, but available client-side for admin)
  Future<void> insert(FinancialSnapshot snapshot) async {
    final cleanId = snapshot.id.trim();
    if (!CoreFirestoreGuard.isSafeDocId(cleanId)) return;
    try {
      await _collection.doc(cleanId).set(snapshot.toJSON());
      AppConfig.logger.d("Financial snapshot inserted: $cleanId");
    } catch (e, st) {
      NeomErrorLogger.recordError(e, st, module: 'neom_core', operation: 'FinancialSnapshotFirestore.insert');
    }
  }
}
