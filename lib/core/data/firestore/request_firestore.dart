import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/model/app_request.dart';
import '../../domain/repository/request_repository.dart';
import '../../utils/app_utilities.dart';
import '../../utils/enums/request_decision.dart';
import '../../utils/enums/request_type.dart';
import 'activity_feed_firestore.dart';
import 'constants/app_firestore_collection_constants.dart';
import 'constants/app_firestore_constants.dart';
import 'profile_firestore.dart';

class RequestFirestore implements RequestRepository {

  final requestsReference = FirebaseFirestore.instance.collection(AppFirestoreCollectionConstants.requests);


  @override
  Future<List<AppRequest>> retrieveRequests(String profileId) async {
    AppUtilities.logger.t("Retrieving Requests for Profile $profileId");
    List<AppRequest> requests = <AppRequest>[];

    try {
      QuerySnapshot querySnapshot = await requestsReference
          .where(AppFirestoreConstants.to, isEqualTo: profileId)
          //.orderBy(GigFirestoreConstants.createdTime, descending: true)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        for (var snapshot in querySnapshot.docs) {
          AppRequest request = AppRequest.fromJSON(snapshot.data());
          request.id = snapshot.id;
          AppUtilities.logger.d(request.id);
          requests.add(request);
        }
      }
    } catch (e) {
      AppUtilities.logger.e(e.toString());
    }

    AppUtilities.logger.d("${requests.length} requests found");
    return requests;
  }


  @override
  Future<List<AppRequest>> retrieveSentRequests(String profileId) async {
    AppUtilities.logger.t("Retrieving Requests Sent");

    List<AppRequest> requests = [];

    try {
      QuerySnapshot querySnapshot = await requestsReference
          .where(AppFirestoreConstants.from, isEqualTo: profileId)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        for (var snapshot in querySnapshot.docs) {
          AppRequest request = AppRequest.fromJSON(snapshot.data());
          request.id = snapshot.id;
          AppUtilities.logger.t(request.toString());
          requests.add(request);
        }

      }
    } catch (e) {
      AppUtilities.logger.e(e.toString());
    }

    AppUtilities.logger.d("${requests .length} requests Sent found");
    return requests;
  }


  @override
  Future<List<AppRequest>> retrieveInvitationRequests(String profileId) async {
    AppUtilities.logger.t("Retrieving Invitation requests");

    List<AppRequest> requests = [];

    try {
      QuerySnapshot querySnapshot = await requestsReference
          .where(AppFirestoreConstants.from, isEqualTo: profileId)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        for (var snapshot in querySnapshot.docs) {
          AppRequest request = AppRequest.fromJSON(snapshot.data());
          request.id = snapshot.id;
          AppUtilities.logger.d(request.toString());
          requests.add(request);
        }

      }
    } catch (e) {
      AppUtilities.logger.e(e.toString());
    }

    AppUtilities.logger.d("${requests .length} requests Sent found");
    return requests;
  }


  Future<List<AppRequest>> retrieveEventRequests(String eventId) async {
    AppUtilities.logger.t("Retrieving Requests for Event $eventId");

    List<AppRequest> requests = [];

    try {
      QuerySnapshot querySnapshot = await requestsReference
          .where(AppFirestoreConstants.eventId, isEqualTo: eventId)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        for (var snapshot in querySnapshot.docs) {
          AppRequest request = AppRequest.fromJSON(snapshot.data());
          request.id = snapshot.id;
          AppUtilities.logger.d(request.toString());
          requests.add(request);
        }
      }
    } catch (e) {
      AppUtilities.logger.e(e.toString());
    }

    AppUtilities.logger.d("${requests .length} requests Sent found");
    return requests;
  }


  @override
  Future<String> insert(AppRequest request) async {
    AppUtilities.logger.t("insert request to firestore");
    String requestId = "";
    try {
      DocumentReference documentReference = await requestsReference.add(request.toJSON());
      requestId  = documentReference.id;
    } catch (e) {
      AppUtilities.logger.e(e.toString());
    }

    return requestId;
  }


  @override
  Future<bool> remove(AppRequest request) async {
    AppUtilities.logger.t("Remove request ${request.id} from firestore");
    bool wasDeleted = false;
    try {
      if(await removeRequestsFromProfiles(request)) {
        await requestsReference.doc(request.id).delete();
      }
    } catch (e) {
      AppUtilities.logger.e(e.toString());
    }

    return wasDeleted;
  }


  Future<bool> removeEventRequests(String eventId) async {
    AppUtilities.logger.t("Remove event requests for $eventId");

    bool requestsRemoved = false;

    try {
      QuerySnapshot querySnapshot = await requestsReference
          .where(AppFirestoreConstants.eventId, isEqualTo: eventId)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        AppUtilities.logger.d("Snapshot is not empty");
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
      AppUtilities.logger.e(e.toString());
    }

    AppUtilities.logger.d("Requests removed for event $eventId");
    return requestsRemoved;
  }


  Future<bool> removeBandRequests(String bandId) async {
    AppUtilities.logger.t("Removing Band $bandId requests");

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
      AppUtilities.logger.e(e.toString());
    }

    AppUtilities.logger.d("Requests removed for band $bandId");
    return requestsRemoved;
  }

  Future<bool> removeRequestsFromProfiles(AppRequest request) async {
    AppUtilities.logger.t("Moving ${request.id} to accepted");

    try {
      await ProfileFirestore().removeRequest(request.from, request.id, RequestType.sent);
      await ProfileFirestore().removeRequest(request.to, request.id, RequestType.received);
      await ProfileFirestore().removeRequest(request.to, request.id, RequestType.invitation);
      await ActivityFeedFirestore().removeRequestActivity(request.id);
      AppUtilities.logger.d("Request ${request.id} has been remove from profile data");
    } catch (e) {
      AppUtilities.logger.e(e.toString());
      return false;
    }

    return true;
  }

  Future<bool> acceptRequest(String requestId) async {
    AppUtilities.logger.t("Moving Request $requestId to accepted");

    try {

      await requestsReference.doc(requestId).get()
          .then((querySnapshot) {
        querySnapshot.reference
            .update({
          AppFirestoreConstants.requestDecision: RequestDecision.confirmed.name
        });
      }
      );

      AppUtilities.logger.d("Request $requestId has been change to accepted");
    } catch (e) {
      AppUtilities.logger.e.toString();
      return false;
    }

    return true;
  }


  Future<bool> declineRequest(String requestId) async {
    AppUtilities.logger.t("Movingr request $requestId to declined");

    try {

      await requestsReference.doc(requestId).get()
          .then((querySnapshot) {
        querySnapshot.reference
            .update({
          AppFirestoreConstants.requestDecision: RequestDecision.declined.name
        });
      });

      AppUtilities.logger.d("Request $requestId has been change to declined");
    } catch (e) {
      AppUtilities.logger.e.toString();
      return false;
    }

    return true;
  }


  Future<bool> moveToPending(String requestId) async {
    AppUtilities.logger.t("Moving request $requestId to pending");

    try {

      await requestsReference.doc(requestId).get()
          .then((querySnapshot) {
        querySnapshot.reference
            .update({
          AppFirestoreConstants.requestDecision: RequestDecision.pending.name
        });
      }
      );


      AppUtilities.logger.d("Request $requestId has been change to pending");
    } catch (e) {
      AppUtilities.logger.e.toString();
      return false;
    }

    return true;
  }


}
