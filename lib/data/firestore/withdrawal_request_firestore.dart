import 'package:cloud_firestore/cloud_firestore.dart';

import '../../app_config.dart';
import '../../domain/model/withdrawal_request.dart';
import '../../utils/neom_error_logger.dart';
import 'constants/app_firestore_collection_constants.dart';
import 'core_firestore_guard.dart';

class WithdrawalRequestFirestore {

  CollectionReference<Map<String, dynamic>> get withdrawalRequestsReference =>
      FirebaseFirestore.instance
          .collection(AppFirestoreCollectionConstants.withdrawalRequests);

  Future<String> insert(WithdrawalRequest request) async {
    if (!request.appCoinsAmount.isFinite ||
        !request.mxnAmount.isFinite ||
        request.appCoinsAmount < 0 ||
        request.mxnAmount < 0 ||
        (request.appCoinsAmount <= 0 && request.mxnAmount <= 0)) {
      AppConfig.logger.w(
        'Rejected withdrawal request with invalid amounts: '
        'appCoins=${request.appCoinsAmount}, mxn=${request.mxnAmount}',
      );
      return '';
    }
    AppConfig.logger.d("Inserting withdrawal request for ${request.ownerEmail}");

    try {
      if (request.id.isNotEmpty) {
        final cleanId = request.id.trim();
        if (!CoreFirestoreGuard.isSafeDocId(cleanId)) return '';
        request.id = cleanId;
        await withdrawalRequestsReference.doc(cleanId).set(request.toJSON());
      } else {
        DocumentReference ref = await withdrawalRequestsReference.add(request.toJSON());
        request.id = ref.id;
        await withdrawalRequestsReference.doc(request.id).update({'id': request.id});
      }
      AppConfig.logger.d("WithdrawalRequest ${request.id} inserted");
    } catch (e, st) {
      NeomErrorLogger.recordError(e, st, module: 'neom_core', operation: 'WithdrawalRequestFirestore.insert');
    }

    return request.id;
  }

  Future<List<WithdrawalRequest>> fetchByOwner(String ownerEmail) async {
    final cleanEmail = ownerEmail.trim();
    if (cleanEmail.isEmpty) return [];
    AppConfig.logger.d("Fetching withdrawal requests for $cleanEmail");
    List<WithdrawalRequest> requests = [];

    try {
      QuerySnapshot querySnapshot = await withdrawalRequestsReference
          .where('ownerEmail', isEqualTo: cleanEmail)
          .orderBy('createdTime', descending: true)
          .limit(200)
          .get();

      for (var doc in querySnapshot.docs) {
        requests.add(WithdrawalRequest.fromJSON(doc.data()));
      }
    } catch (e, st) {
      NeomErrorLogger.recordError(e, st, module: 'neom_core', operation: 'WithdrawalRequestFirestore.fetchByOwner');
    }

    return requests;
  }

  Future<bool> updateStatus(String requestId, WithdrawalStatus status, {String? adminNote}) async {
    final cleanId = requestId.trim();
    if (!CoreFirestoreGuard.isSafeDocId(cleanId)) return false;
    AppConfig.logger.d("Updating withdrawal $cleanId to ${status.name}");

    try {
      Map<String, dynamic> updateData = {
        'status': status.name,
      };
      if (status == WithdrawalStatus.completed || status == WithdrawalStatus.rejected) {
        updateData['processedTime'] = DateTime.now().millisecondsSinceEpoch;
      }
      if (adminNote != null) {
        updateData['adminNote'] = adminNote;
      }

      await withdrawalRequestsReference.doc(cleanId).update(updateData);
      return true;
    } catch (e, st) {
      NeomErrorLogger.recordError(e, st, module: 'neom_core', operation: 'WithdrawalRequestFirestore.updateStatus');
    }

    return false;
  }
}
