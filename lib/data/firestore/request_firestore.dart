import 'package:cloud_firestore/cloud_firestore.dart';

import '../../app_config.dart';
import '../../domain/model/app_request.dart';
import '../../domain/repository/request_repository.dart';
import '../../utils/enums/request_decision.dart';
import '../../utils/enums/request_type.dart';
import 'activity_feed_firestore.dart';
import 'constants/app_firestore_collection_constants.dart';
import 'constants/app_firestore_constants.dart';
import 'profile_firestore.dart';

class RequestFirestore implements RequestRepository {

  final requestsReference = FirebaseFirestore.instance.collection(AppFirestoreCollectionConstants.requests);


  /// OPTIMIZED: Added limit and orderBy to prevent unbounded reads
  @override
  Future<List<AppRequest>> retrieveRequests(String profileId, {int limit = 50}) async {
    AppConfig.logger.t("Retrieving Requests for Profile $profileId (limit: $limit)");
    List<AppRequest> requests = <AppRequest>[];

    try {
      QuerySnapshot querySnapshot = await requestsReference
          .where(AppFirestoreConstants.to, isEqualTo: profileId)
          .orderBy(AppFirestoreConstants.createdTime, descending: true)
          .limit(limit)  // OPTIMIZATION: Prevent reading all requests
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        for (var snapshot in querySnapshot.docs) {
          AppRequest request = AppRequest.fromJSON(snapshot.data());
          request.id = snapshot.id;
          AppConfig.logger.t('Request ${request.id} retrieved');
          requests.add(request);
        }
      }
    } catch (e) {
      AppConfig.logger.e(e.toString());
    }

    AppConfig.logger.d("${requests.length} requests found");
    return requests;
  }


  /// OPTIMIZED: Added limit and orderBy to prevent unbounded reads
  @override
  Future<List<AppRequest>> retrieveSentRequests(String profileId, {int limit = 50}) async {
    AppConfig.logger.t("Retrieving Requests Sent (limit: $limit)");

    List<AppRequest> requests = [];

    try {
      QuerySnapshot querySnapshot = await requestsReference
          .where(AppFirestoreConstants.from, isEqualTo: profileId)
          .orderBy(AppFirestoreConstants.createdTime, descending: true)
          .limit(limit)  // OPTIMIZATION: Prevent reading all requests
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        for (var snapshot in querySnapshot.docs) {
          AppRequest request = AppRequest.fromJSON(snapshot.data());
          request.id = snapshot.id;
          AppConfig.logger.t(request.toString());
          requests.add(request);
        }

      }
    } catch (e) {
      AppConfig.logger.e(e.toString());
    }

    AppConfig.logger.d("${requests.length} requests Sent found");
    return requests;
  }


  /// OPTIMIZED: Added limit and orderBy to prevent unbounded reads
  @override
  Future<List<AppRequest>> retrieveInvitationRequests(String profileId, {int limit = 50}) async {
    AppConfig.logger.t("Retrieving Invitation requests (limit: $limit)");

    List<AppRequest> requests = [];

    try {
      QuerySnapshot querySnapshot = await requestsReference
          .where(AppFirestoreConstants.from, isEqualTo: profileId)
          .orderBy(AppFirestoreConstants.createdTime, descending: true)
          .limit(limit)  // OPTIMIZATION: Prevent reading all requests
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        for (var snapshot in querySnapshot.docs) {
          AppRequest request = AppRequest.fromJSON(snapshot.data());
          request.id = snapshot.id;
          AppConfig.logger.d(request.toString());
          requests.add(request);
        }

      }
    } catch (e) {
      AppConfig.logger.e(e.toString());
    }

    AppConfig.logger.d("${requests.length} requests Sent found");
    return requests;
  }


  /// OPTIMIZED: Added limit to prevent unbounded reads for popular events
  Future<List<AppRequest>> retrieveEventRequests(String eventId, {int limit = 100}) async {
    AppConfig.logger.t("Retrieving Requests for Event $eventId (limit: $limit)");

    List<AppRequest> requests = [];

    try {
      QuerySnapshot querySnapshot = await requestsReference
          .where(AppFirestoreConstants.eventId, isEqualTo: eventId)
          .limit(limit)  // OPTIMIZATION: Prevent reading all requests for popular events
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        for (var snapshot in querySnapshot.docs) {
          AppRequest request = AppRequest.fromJSON(snapshot.data());
          request.id = snapshot.id;
          AppConfig.logger.d(request.toString());
          requests.add(request);
        }
      }
    } catch (e) {
      AppConfig.logger.e(e.toString());
    }

    AppConfig.logger.d("${requests.length} event requests found");
    return requests;
  }


  @override
  Future<String> insert(AppRequest request) async {
    AppConfig.logger.t("insert request to firestore");
    String requestId = "";
    try {
      DocumentReference documentReference = await requestsReference.add(request.toJSON());
      requestId  = documentReference.id;
    } catch (e) {
      AppConfig.logger.e(e.toString());
    }

    return requestId;
  }


  @override
  Future<bool> remove(AppRequest request) async {
    AppConfig.logger.t("Remove request ${request.id} from firestore");
    bool wasDeleted = false;
    try {
      if(await removeRequestsFromProfiles(request)) {
        await requestsReference.doc(request.id).delete();
      }
    } catch (e) {
      AppConfig.logger.e(e.toString());
    }

    return wasDeleted;
  }


  Future<bool> removeEventRequests(String eventId) async {
    AppConfig.logger.t("Remove event requests for $eventId");

    bool requestsRemoved = false;

    try {
      QuerySnapshot querySnapshot = await requestsReference
          .where(AppFirestoreConstants.eventId, isEqualTo: eventId)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        AppConfig.logger.d("Snapshot is not empty");
        for (var snapshot in querySnapshot.docs) {
          AppRequest request = AppRequest.fromJSON(snapshot.data());
          request.id = snapshot.id;
          if(await removeRequestsFromProfiles(request)) {
            await snapshot.reference.delete();
          }
        }
        requestsRemoved = true;
      }
    } catch (e) {
      AppConfig.logger.e(e.toString());
    }

    AppConfig.logger.d("Requests removed for event $eventId");
    return requestsRemoved;
  }


  Future<bool> removeBandRequests(String bandId) async {
    AppConfig.logger.t("Removing Band $bandId requests");

    bool requestsRemoved = false;

    try {
      QuerySnapshot querySnapshot = await requestsReference
          .where(AppFirestoreConstants.bandId, isEqualTo: bandId)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        for (var snapshot in querySnapshot.docs) {
            AppRequest request = AppRequest.fromJSON(snapshot.data());
            request.id = snapshot.id;
            if(await removeRequestsFromProfiles(request)) {
              await snapshot.reference.delete();
            }
        }
        requestsRemoved = true;
      }
    } catch (e) {
      AppConfig.logger.e(e.toString());
    }

    AppConfig.logger.d("Requests removed for band $bandId");
    return requestsRemoved;
  }

  Future<bool> removeRequestsFromProfiles(AppRequest request) async {
    AppConfig.logger.t("Moving ${request.id} to accepted");

    try {
      await ProfileFirestore().removeRequest(request.from, request.id, RequestType.sent);
      await ProfileFirestore().removeRequest(request.to, request.id, RequestType.received);
      await ProfileFirestore().removeRequest(request.to, request.id, RequestType.invitation);
      await ActivityFeedFirestore().removeRequestActivity(request.id);
      AppConfig.logger.d("Request ${request.id} has been remove from profile data");
    } catch (e) {
      AppConfig.logger.e(e.toString());
      return false;
    }

    return true;
  }

  Future<bool> acceptRequest(String requestId) async {
    AppConfig.logger.t("Moving Request $requestId to accepted");

    try {

      // OPTIMIZED: Use direct update instead of get().then()
      await requestsReference.doc(requestId).update({
        AppFirestoreConstants.requestDecision: RequestDecision.confirmed.name
      });

      AppConfig.logger.d("Request $requestId has been change to accepted");
    } catch (e) {
      AppConfig.logger.e.toString();
      return false;
    }

    return true;
  }


  Future<bool> declineRequest(String requestId) async {
    AppConfig.logger.t("Movingr request $requestId to declined");

    try {

      // OPTIMIZED: Use direct update instead of get().then()
      await requestsReference.doc(requestId).update({
        AppFirestoreConstants.requestDecision: RequestDecision.declined.name
      });

      AppConfig.logger.d("Request $requestId has been change to declined");
    } catch (e) {
      AppConfig.logger.e.toString();
      return false;
    }

    return true;
  }


  Future<bool> moveToPending(String requestId) async {
    AppConfig.logger.t("Moving request $requestId to pending");

    try {

      // OPTIMIZED: Use direct update instead of get().then()
      await requestsReference.doc(requestId).update({
        AppFirestoreConstants.requestDecision: RequestDecision.pending.name
      });


      AppConfig.logger.d("Request $requestId has been change to pending");
    } catch (e) {
      AppConfig.logger.e.toString();
      return false;
    }

    return true;
  }

  /// Stream a single request by ID for real-time updates
  Stream<AppRequest?> streamRequest(String requestId) {
    return requestsReference.doc(requestId).snapshots().map((snapshot) {
      if (!snapshot.exists) return null;
      final request = AppRequest.fromJSON(snapshot.data()!);
      request.id = snapshot.id;
      return request;
    });
  }

  /// Stream sent requests for a profile
  /// Limits to 30 most recent requests to reduce Firestore reads
  Stream<List<AppRequest>> streamSentRequests(String profileId, {int limit = 30}) {
    return requestsReference
        .where(AppFirestoreConstants.from, isEqualTo: profileId)
        .orderBy(AppFirestoreConstants.createdTime, descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final request = AppRequest.fromJSON(doc.data());
        request.id = doc.id;
        return request;
      }).toList();
    });
  }

  /// Stream received requests for a profile
  /// Limits to 30 most recent requests to reduce Firestore reads
  Stream<List<AppRequest>> streamRequests(String profileId, {int limit = 30}) {
    return requestsReference
        .where(AppFirestoreConstants.to, isEqualTo: profileId)
        .orderBy(AppFirestoreConstants.createdTime, descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final request = AppRequest.fromJSON(doc.data());
        request.id = doc.id;
        return request;
      }).toList();
    });
  }

  /// Get a single request by ID
  Future<AppRequest?> getRequest(String requestId) async {
    try {
      final doc = await requestsReference.doc(requestId).get();
      if (!doc.exists) return null;
      final request = AppRequest.fromJSON(doc.data()!);
      request.id = doc.id;
      return request;
    } catch (e) {
      AppConfig.logger.e('Error getting request: $e');
      return null;
    }
  }

  /// Retrieves release approval requests for support+ users to review
  /// These are requests with 'to' = 'appBot' and pending status
  Future<List<AppRequest>> retrieveReleaseApprovalRequests({int limit = 50}) async {
    AppConfig.logger.t("Retrieving Release Approval Requests (limit: $limit)");
    List<AppRequest> requests = <AppRequest>[];

    try {
      QuerySnapshot querySnapshot = await requestsReference
          .where(AppFirestoreConstants.to, isEqualTo: 'appBot')
          .where(AppFirestoreConstants.requestDecision, isEqualTo: RequestDecision.pending.name)
          .orderBy(AppFirestoreConstants.createdTime, descending: true)
          .limit(limit)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        for (var snapshot in querySnapshot.docs) {
          AppRequest request = AppRequest.fromJSON(snapshot.data());
          request.id = snapshot.id;
          // Only include release approval requests
          if (request.isReleaseApprovalRequest) {
            requests.add(request);
            AppConfig.logger.t('Release approval request ${request.id} retrieved');
          }
        }
      }
    } catch (e) {
      AppConfig.logger.e('Error retrieving release approval requests: $e');
    }

    AppConfig.logger.d("${requests.length} release approval requests found");
    return requests;
  }


}
