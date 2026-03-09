import 'package:cloud_firestore/cloud_firestore.dart';

import '../../app_config.dart';
import '../../domain/model/financial_snapshot.dart';
import 'constants/app_firestore_collection_constants.dart';

class FinancialSnapshotFirestore {

  final _collection = FirebaseFirestore.instance
      .collection(AppFirestoreCollectionConstants.financialSnapshots);

  /// Get a specific snapshot by date ID (YYYY-MM-DD)
  Future<FinancialSnapshot?> getById(String snapshotId) async {
    try {
      final doc = await _collection.doc(snapshotId).get();
      if (doc.exists) {
        return FinancialSnapshot.fromJSON(doc.data() as Map<String, dynamic>);
      }
    } catch (e) {
      AppConfig.logger.e("Error getting financial snapshot: $e");
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
    } catch (e) {
      AppConfig.logger.e("Error getting latest financial snapshot: $e");
    }
    return null;
  }

  /// Get snapshots for a date range (for MRR history chart)
  Future<List<FinancialSnapshot>> getRange(String startId, String endId) async {
    try {
      final snapshot = await _collection
          .where(FieldPath.documentId, isGreaterThanOrEqualTo: startId)
          .where(FieldPath.documentId, isLessThanOrEqualTo: endId)
          .orderBy(FieldPath.documentId)
          .get();
      return snapshot.docs
          .map((doc) => FinancialSnapshot.fromJSON(doc.data()))
          .toList();
    } catch (e) {
      AppConfig.logger.e("Error getting financial snapshot range: $e");
      return [];
    }
  }

  /// Get the last N snapshots (for charts/forecasting)
  Future<List<FinancialSnapshot>> getLastN(int count) async {
    try {
      final snapshot = await _collection
          .orderBy('computedAt', descending: true)
          .limit(count)
          .get();
      return snapshot.docs
          .map((doc) => FinancialSnapshot.fromJSON(doc.data()))
          .toList()
          .reversed
          .toList(); // chronological order
    } catch (e) {
      AppConfig.logger.e("Error getting last $count financial snapshots: $e");
      return [];
    }
  }

  /// Insert a new snapshot (used by Cloud Functions, but available client-side for admin)
  Future<void> insert(FinancialSnapshot snapshot) async {
    try {
      await _collection.doc(snapshot.id).set(snapshot.toJSON());
      AppConfig.logger.d("Financial snapshot inserted: ${snapshot.id}");
    } catch (e) {
      AppConfig.logger.e("Error inserting financial snapshot: $e");
    }
  }
}
