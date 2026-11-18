import 'package:cloud_firestore/cloud_firestore.dart';

import '../../app_config.dart';
import '../../domain/model/erp_role_assignment.dart';
import '../../utils/neom_error_logger.dart';
import 'constants/app_firestore_collection_constants.dart';
import 'core_firestore_guard.dart';

class ErpRoleAssignmentFirestore {

  CollectionReference<Map<String, dynamic>> get _collection =>
      FirebaseFirestore.instance
          .collection(AppFirestoreCollectionConstants.erpRoleAssignments);

  /// Get the ERP role assignment for a specific user
  Future<ErpRoleAssignment?> getByUserId(String userId) async {
    final cleanId = userId.trim();
    if (!CoreFirestoreGuard.isSafeDocId(cleanId)) return null;
    try {
      final doc = await _collection.doc(cleanId).get();
      if (doc.exists && doc.data() != null) {
        return ErpRoleAssignment.fromJSON(doc.data()!);
      }
    } catch (e, st) {
      NeomErrorLogger.recordError(e, st, module: 'neom_core', operation: 'getByUserId');
    }
    return null;
  }

  /// Get all ERP role assignments
  Future<List<ErpRoleAssignment>> getAll() async {
    try {
      final snapshot = await _collection.limit(500).get();
      return snapshot.docs
          .map((doc) => ErpRoleAssignment.fromJSON(doc.data()))
          .toList();
    } catch (e, st) {
      NeomErrorLogger.recordError(e, st, module: 'neom_core', operation: 'getAll');
      return [];
    }
  }

  /// Create or update an ERP role assignment (keyed by userId)
  Future<void> upsert(ErpRoleAssignment assignment) async {
    final cleanId = assignment.userId.trim();
    if (!CoreFirestoreGuard.isSafeDocId(cleanId)) return;
    try {
      await _collection.doc(cleanId).set(assignment.toJSON());
      AppConfig.logger.d("ERP role assignment upserted for: $cleanId");
    } catch (e, st) {
      NeomErrorLogger.recordError(e, st, module: 'neom_core', operation: 'upsert');
    }
  }

  /// Remove ERP role assignment
  Future<void> remove(String userId) async {
    final cleanId = userId.trim();
    if (!CoreFirestoreGuard.isSafeDocId(cleanId)) return;
    try {
      await _collection.doc(cleanId).delete();
      AppConfig.logger.d("ERP role assignment removed for: $cleanId");
    } catch (e, st) {
      NeomErrorLogger.recordError(e, st, module: 'neom_core', operation: 'remove');
    }
  }
}
