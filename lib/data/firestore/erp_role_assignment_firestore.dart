import 'package:cloud_firestore/cloud_firestore.dart';

import '../../app_config.dart';
import '../../domain/model/erp_role_assignment.dart';
import 'constants/app_firestore_collection_constants.dart';

class ErpRoleAssignmentFirestore {

  final _collection = FirebaseFirestore.instance
      .collection(AppFirestoreCollectionConstants.erpRoleAssignments);

  /// Get the ERP role assignment for a specific user
  Future<ErpRoleAssignment?> getByUserId(String userId) async {
    try {
      final doc = await _collection.doc(userId).get();
      if (doc.exists) {
        return ErpRoleAssignment.fromJSON(doc.data() as Map<String, dynamic>);
      }
    } catch (e) {
      AppConfig.logger.e("Error getting ERP role assignment: $e");
    }
    return null;
  }

  /// Get all ERP role assignments
  Future<List<ErpRoleAssignment>> getAll() async {
    try {
      final snapshot = await _collection.get();
      return snapshot.docs
          .map((doc) => ErpRoleAssignment.fromJSON(doc.data()))
          .toList();
    } catch (e) {
      AppConfig.logger.e("Error getting all ERP role assignments: $e");
      return [];
    }
  }

  /// Create or update an ERP role assignment (keyed by userId)
  Future<void> upsert(ErpRoleAssignment assignment) async {
    try {
      await _collection.doc(assignment.userId).set(assignment.toJSON());
      AppConfig.logger.d("ERP role assignment upserted for: ${assignment.userId}");
    } catch (e) {
      AppConfig.logger.e("Error upserting ERP role assignment: $e");
    }
  }

  /// Remove ERP role assignment
  Future<void> remove(String userId) async {
    try {
      await _collection.doc(userId).delete();
      AppConfig.logger.d("ERP role assignment removed for: $userId");
    } catch (e) {
      AppConfig.logger.e("Error removing ERP role assignment: $e");
    }
  }
}
