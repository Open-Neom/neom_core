import 'package:cloud_firestore/cloud_firestore.dart';

import '../../app_config.dart';
import '../../domain/model/withdrawal_request.dart';
import 'constants/app_firestore_collection_constants.dart';

class WithdrawalRequestFirestore {

  final withdrawalRequestsReference = FirebaseFirestore.instance
      .collection(AppFirestoreCollectionConstants.withdrawalRequests);

  Future<String> insert(WithdrawalRequest request) async {
    AppConfig.logger.d("Inserting withdrawal request for ${request.ownerEmail}");

    try {
      if (request.id.isNotEmpty) {
        await withdrawalRequestsReference.doc(request.id).set(request.toJSON());
      } else {
        DocumentReference ref = await withdrawalRequestsReference.add(request.toJSON());
        request.id = ref.id;
        await withdrawalRequestsReference.doc(request.id).update({'id': request.id});
      }
      AppConfig.logger.d("WithdrawalRequest ${request.id} inserted");
    } catch (e) {
      AppConfig.logger.e(e.toString());
    }

    return request.id;
  }

  Future<List<WithdrawalRequest>> fetchByOwner(String ownerEmail) async {
    AppConfig.logger.d("Fetching withdrawal requests for $ownerEmail");
    List<WithdrawalRequest> requests = [];

    try {
      QuerySnapshot querySnapshot = await withdrawalRequestsReference
          .where('ownerEmail', isEqualTo: ownerEmail)
          .orderBy('createdTime', descending: true)
          .get();

      for (var doc in querySnapshot.docs) {
        requests.add(WithdrawalRequest.fromJSON(doc.data()));
      }
    } catch (e) {
      AppConfig.logger.e(e.toString());
    }

    return requests;
  }

  Future<bool> updateStatus(String requestId, WithdrawalStatus status, {String? adminNote}) async {
    AppConfig.logger.d("Updating withdrawal $requestId to ${status.name}");

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

      await withdrawalRequestsReference.doc(requestId).update(updateData);
      return true;
    } catch (e) {
      AppConfig.logger.e(e.toString());
    }

    return false;
  }
}
