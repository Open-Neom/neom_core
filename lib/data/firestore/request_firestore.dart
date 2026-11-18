import 'package:cloud_firestore/cloud_firestore.dart';

import '../../app_config.dart';
import '../../domain/model/app_request.dart';
import '../../domain/repository/request_repository.dart';
import '../../utils/enums/request_decision.dart';
import '../../utils/enums/request_type.dart';
import '../../utils/neom_error_logger.dart';
import '../api/app_platform_api.dart';
import 'activity_feed_firestore.dart';
import 'constants/app_firestore_collection_constants.dart';
import 'constants/app_firestore_constants.dart';
import 'core_firestore_guard.dart';
import 'profile_firestore.dart';

class RequestFirestore implements RequestRepository {

  CollectionReference<Map<String, dynamic>> get requestsReference =>
      FirebaseFirestore.instance.collection(AppFirestoreCollectionConstants.requests);

  List<AppRequest> _parsePlatformItems(Map<String, dynamic> res) {
    final raw = res['items'];
    if (raw is! List) return <AppRequest>[];
    return raw
        .whereType<Map>()
        .map((m) {
          final map = Map<String, dynamic>.from(m);
          final r = AppRequest.fromJSON(map);
          if (r.id.isEmpty && map['id'] != null) {
            r.id = map['id'].toString();
          }
          return r;
        })
        .toList();
  }

  /// OPTIMIZED: Added limit and orderBy to prevent unbounded reads
  @override
  Future<List<AppRequest>> retrieveRequests(String profileId, {int limit = 50}) async {
    final cleanProfileId = profileId.trim();
    final safeLimit = CoreFirestoreGuard.clampLimit(limit, defaultLimit: 50, maxLimit: 200);
    if (AppPlatformApi.isEnabled) {
      AppConfig.logger.t("Retrieving Requests for Profile $cleanProfileId (limit: $safeLimit)");
      try {
        final res = await AppPlatformApi.client('requests').read(
          'retrieveRequests',
          <String, Object?>{
            if (cleanProfileId.isNotEmpty) 'profileId': cleanProfileId,
            'limit': safeLimit,
          },
          private: true,
        );
        return _parsePlatformItems(res);
      } catch (e, st) {
        NeomErrorLogger.recordError(e, st, module: 'neom_core', operation: 'RequestFirestore.retrieveRequests.api');
        return <AppRequest>[];
      }
    }
    if (!CoreFirestoreGuard.isSafeDocId(cleanProfileId)) return <AppRequest>[];
    AppConfig.logger.t("Retrieving Requests for Profile $cleanProfileId (limit: $safeLimit)");
    List<AppRequest> requests = <AppRequest>[];

    try {
      QuerySnapshot querySnapshot = await requestsReference
          .where(AppFirestoreConstants.to, isEqualTo: cleanProfileId)
          .orderBy(AppFirestoreConstants.createdTime, descending: true)
          .limit(safeLimit)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        for (var snapshot in querySnapshot.docs) {
          AppRequest request = AppRequest.fromJSON(snapshot.data());
          request.id = snapshot.id;
          AppConfig.logger.t('Request ${request.id} retrieved');
          requests.add(request);
        }
      }
    } catch (e, st) {
      NeomErrorLogger.recordError(e, st, module: 'neom_core', operation: 'RequestFirestore.retrieveRequests');
    }

    AppConfig.logger.d("${requests.length} requests found");
    return requests;
  }


  /// OPTIMIZED: Added limit and orderBy to prevent unbounded reads
  @override
  Future<List<AppRequest>> retrieveSentRequests(String profileId, {int limit = 50}) async {
    final cleanProfileId = profileId.trim();
    final safeLimit = CoreFirestoreGuard.clampLimit(limit, defaultLimit: 50, maxLimit: 200);
    if (AppPlatformApi.isEnabled) {
      AppConfig.logger.t("Retrieving Requests Sent (limit: $safeLimit)");
      try {
        final res = await AppPlatformApi.client('requests').read(
          'retrieveSentRequests',
          <String, Object?>{
            if (cleanProfileId.isNotEmpty) 'profileId': cleanProfileId,
            'limit': safeLimit,
          },
          private: true,
        );
        return _parsePlatformItems(res);
      } catch (e, st) {
        NeomErrorLogger.recordError(e, st, module: 'neom_core', operation: 'RequestFirestore.retrieveSentRequests.api');
        return <AppRequest>[];
      }
    }
    if (!CoreFirestoreGuard.isSafeDocId(cleanProfileId)) return [];
    AppConfig.logger.t("Retrieving Requests Sent (limit: $safeLimit)");

    List<AppRequest> requests = [];

    try {
      QuerySnapshot querySnapshot = await requestsReference
          .where(AppFirestoreConstants.from, isEqualTo: cleanProfileId)
          .orderBy(AppFirestoreConstants.createdTime, descending: true)
          .limit(safeLimit)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        for (var snapshot in querySnapshot.docs) {
          AppRequest request = AppRequest.fromJSON(snapshot.data());
          request.id = snapshot.id;
          AppConfig.logger.t(request.toString());
          requests.add(request);
        }

      }
    } catch (e, st) {
      NeomErrorLogger.recordError(e, st, module: 'neom_core', operation: 'RequestFirestore.retrieveSentRequests');
    }

    AppConfig.logger.d("${requests.length} requests Sent found");
    return requests;
  }


  /// OPTIMIZED: Added limit and orderBy to prevent unbounded reads
  @override
  Future<List<AppRequest>> retrieveInvitationRequests(String profileId, {int limit = 50}) async {
    final cleanProfileId = profileId.trim();
    final safeLimit = CoreFirestoreGuard.clampLimit(limit, defaultLimit: 50, maxLimit: 200);
    if (AppPlatformApi.isEnabled) {
      AppConfig.logger.t("Retrieving Invitation requests (limit: $safeLimit)");
      return retrieveSentRequests(cleanProfileId, limit: safeLimit);
    }
    if (!CoreFirestoreGuard.isSafeDocId(cleanProfileId)) return [];
    AppConfig.logger.t("Retrieving Invitation requests (limit: $safeLimit)");

    List<AppRequest> requests = [];

    try {
      QuerySnapshot querySnapshot = await requestsReference
          .where(AppFirestoreConstants.from, isEqualTo: cleanProfileId)
          .orderBy(AppFirestoreConstants.createdTime, descending: true)
          .limit(safeLimit)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        for (var snapshot in querySnapshot.docs) {
          AppRequest request = AppRequest.fromJSON(snapshot.data());
          request.id = snapshot.id;
          AppConfig.logger.d(request.toString());
          requests.add(request);
        }

      }
    } catch (e, st) {
      NeomErrorLogger.recordError(e, st, module: 'neom_core', operation: 'RequestFirestore.retrieveInvitationRequests');
    }

    AppConfig.logger.d("${requests.length} requests Sent found");
    return requests;
  }


  /// OPTIMIZED: Added limit to prevent unbounded reads for popular events
  Future<List<AppRequest>> retrieveEventRequests(String eventId, {int limit = 100}) async {
    final cleanEventId = eventId.trim();
    final safeLimit = CoreFirestoreGuard.clampLimit(limit, defaultLimit: 100, maxLimit: 500);
    if (AppPlatformApi.isEnabled) {
      if (cleanEventId.isEmpty) return <AppRequest>[];
      AppConfig.logger.t("Retrieving Requests for Event $cleanEventId (limit: $safeLimit)");
      try {
        final res = await AppPlatformApi.client('requests').read(
          'retrieveEventRequests',
          <String, Object?>{'eventId': cleanEventId, 'limit': safeLimit},
          private: false,
        );
        return _parsePlatformItems(res);
      } catch (e, st) {
        NeomErrorLogger.recordError(e, st, module: 'neom_core', operation: 'RequestFirestore.retrieveEventRequests.api');
        return <AppRequest>[];
      }
    }
    if (!CoreFirestoreGuard.isSafeDocId(cleanEventId)) return [];
    AppConfig.logger.t("Retrieving Requests for Event $cleanEventId (limit: $safeLimit)");

    List<AppRequest> requests = [];

    try {
      QuerySnapshot querySnapshot = await requestsReference
          .where(AppFirestoreConstants.eventId, isEqualTo: cleanEventId)
          .limit(safeLimit)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        for (var snapshot in querySnapshot.docs) {
          AppRequest request = AppRequest.fromJSON(snapshot.data());
          request.id = snapshot.id;
          AppConfig.logger.d(request.toString());
          requests.add(request);
        }
      }
    } catch (e, st) {
      NeomErrorLogger.recordError(e, st, module: 'neom_core', operation: 'RequestFirestore.retrieveEventRequests');
    }

    AppConfig.logger.d("${requests.length} event requests found");
    return requests;
  }


  @override
  Future<String> insert(AppRequest request) async {
    AppConfig.logger.t("insert request to firestore");
    if (AppPlatformApi.isEnabled) {
      try {
        final res = await AppPlatformApi.client('requests').mutate(
          'insert',
          <String, Object?>{'request': request.toJSON()},
          durable: false,
        );
        return res is Map
            ? (res['value'] ?? res['id'] ?? '').toString()
            : (res ?? '').toString();
      } catch (e, st) {
        NeomErrorLogger.recordError(e, st, module: 'neom_core', operation: 'RequestFirestore.insert.api');
        return '';
      }
    }

    String requestId = "";
    try {
      DocumentReference documentReference = await requestsReference.add(request.toJSON());
      requestId  = documentReference.id;
    } catch (e, st) {
      NeomErrorLogger.recordError(e, st, module: 'neom_core', operation: 'RequestFirestore.insert');
    }

    return requestId;
  }


  @override
  Future<bool> remove(AppRequest request) async {
    final cleanId = request.id.trim();
    if (!CoreFirestoreGuard.isSafeDocId(cleanId)) return false;
    AppConfig.logger.t("Remove request $cleanId from firestore");
    if (AppPlatformApi.isEnabled) {
      return declineRequest(cleanId);
    }
    bool wasDeleted = false;
    try {
      if (await removeRequestsFromProfiles(request)) {
        await requestsReference.doc(cleanId).delete();
        wasDeleted = true;
      }
    } catch (e, st) {
      NeomErrorLogger.recordError(e, st, module: 'neom_core', operation: 'RequestFirestore.remove');
    }

    return wasDeleted;
  }


  Future<bool> removeEventRequests(String eventId) async {
    final cleanEventId = eventId.trim();
    if (!CoreFirestoreGuard.isSafeDocId(cleanEventId)) return false;
    AppConfig.logger.t("Remove event requests for $cleanEventId");
    if (AppPlatformApi.isEnabled) return true;

    bool requestsRemoved = false;

    try {
      QuerySnapshot querySnapshot = await requestsReference
          .where(AppFirestoreConstants.eventId, isEqualTo: cleanEventId)
          .limit(500)
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
    } catch (e, st) {
      NeomErrorLogger.recordError(e, st, module: 'neom_core', operation: 'RequestFirestore.removeEventRequests');
    }

    AppConfig.logger.d("Requests removed for event $cleanEventId");
    return requestsRemoved;
  }


  Future<bool> removeCollectiveRequests(String collectiveId) async {
    final cleanCollectiveId = collectiveId.trim();
    if (!CoreFirestoreGuard.isSafeDocId(cleanCollectiveId)) return false;
    AppConfig.logger.t("Removing Collective $cleanCollectiveId requests");
    if (AppPlatformApi.isEnabled) return true;

    bool requestsRemoved = false;

    try {
      QuerySnapshot querySnapshot = await requestsReference
          .where(AppFirestoreConstants.collectiveId, isEqualTo: cleanCollectiveId)
          .limit(500)
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
    } catch (e, st) {
      NeomErrorLogger.recordError(e, st, module: 'neom_core', operation: 'RequestFirestore.removeCollectiveRequests');
    }

    AppConfig.logger.d("Requests removed for collective $cleanCollectiveId");
    return requestsRemoved;
  }

  Future<bool> removeRequestsFromProfiles(AppRequest request) async {
    AppConfig.logger.t("Moving ${request.id} to accepted");
    if (AppPlatformApi.isEnabled) return true;

    try {
      await ProfileFirestore().removeRequest(request.from, request.id, RequestType.sent);
      await ProfileFirestore().removeRequest(request.to, request.id, RequestType.received);
      await ProfileFirestore().removeRequest(request.to, request.id, RequestType.invitation);
      await ActivityFeedFirestore().removeRequestActivity(request.id);
      AppConfig.logger.d("Request ${request.id} has been remove from profile data");
    } catch (e, st) {
      NeomErrorLogger.recordError(e, st, module: 'neom_core', operation: 'RequestFirestore.removeRequestsFromProfiles');
      return false;
    }

    return true;
  }

  Future<bool> approveChangeOnPlatform(String requestId, {String notes = ''}) async {
    try {
      await AppPlatformApi.client('requests').mutate(
        'approveChange',
        <String, Object?>{
          'requestId': requestId,
          if (notes.isNotEmpty) 'notes': notes,
        },
        durable: false,
      );
      return true;
    } catch (e, st) {
      NeomErrorLogger.recordError(e, st, module: 'neom_core', operation: 'RequestFirestore.approveChangeOnPlatform');
      return false;
    }
  }

  Future<bool> declineChangeOnPlatform(String requestId, {String notes = ''}) async {
    try {
      await AppPlatformApi.client('requests').mutate(
        'declineChange',
        <String, Object?>{
          'requestId': requestId,
          if (notes.isNotEmpty) 'notes': notes,
        },
        durable: false,
      );
      return true;
    } catch (e, st) {
      NeomErrorLogger.recordError(e, st, module: 'neom_core', operation: 'RequestFirestore.declineChangeOnPlatform');
      return false;
    }
  }

  Future<bool> acceptRequest(String requestId) async {
    final cleanId = requestId.trim();
    if (!CoreFirestoreGuard.isSafeDocId(cleanId)) return false;
    AppConfig.logger.t("Moving Request $cleanId to accepted");
    if (AppPlatformApi.isEnabled) {
      return approveChangeOnPlatform(cleanId);
    }

    try {
      await requestsReference.doc(cleanId).update({
        AppFirestoreConstants.requestDecision: RequestDecision.confirmed.name
      });

      AppConfig.logger.d("Request $cleanId has been change to accepted");
    } catch (e, st) {
      NeomErrorLogger.recordError(e, st, module: 'neom_core', operation: 'RequestFirestore.acceptRequest');
      return false;
    }

    return true;
  }


  Future<bool> declineRequest(String requestId) async {
    final cleanId = requestId.trim();
    if (!CoreFirestoreGuard.isSafeDocId(cleanId)) return false;
    AppConfig.logger.t("Movingr request $cleanId to declined");
    if (AppPlatformApi.isEnabled) {
      return declineChangeOnPlatform(cleanId);
    }

    try {
      await requestsReference.doc(cleanId).update({
        AppFirestoreConstants.requestDecision: RequestDecision.declined.name
      });

      AppConfig.logger.d("Request $cleanId has been change to declined");
    } catch (e, st) {
      NeomErrorLogger.recordError(e, st, module: 'neom_core', operation: 'RequestFirestore.declineRequest');
      return false;
    }

    return true;
  }


  Future<bool> moveToPending(String requestId) async {
    final cleanId = requestId.trim();
    if (!CoreFirestoreGuard.isSafeDocId(cleanId)) return false;
    AppConfig.logger.t("Moving request $cleanId to pending");
    if (AppPlatformApi.isEnabled) return true;

    try {
      await requestsReference.doc(cleanId).update({
        AppFirestoreConstants.requestDecision: RequestDecision.pending.name
      });

      AppConfig.logger.d("Request $cleanId has been change to pending");
    } catch (e, st) {
      NeomErrorLogger.recordError(e, st, module: 'neom_core', operation: 'RequestFirestore.moveToPending');
      return false;
    }

    return true;
  }

  /// Stream a single request by ID for real-time updates
  Stream<AppRequest?> streamRequest(String requestId) {
    final cleanId = requestId.trim();
    if (!CoreFirestoreGuard.isSafeDocId(cleanId)) {
      return Stream<AppRequest?>.value(null);
    }
    if (AppPlatformApi.isEnabled) {
      return Stream.fromFuture(getRequest(cleanId));
    }
    return requestsReference.doc(cleanId).snapshots().map((snapshot) {
      if (!snapshot.exists || snapshot.data() == null) return null;
      final request = AppRequest.fromJSON(snapshot.data()!);
      request.id = snapshot.id;
      return request;
    });
  }

  /// Stream sent requests for a profile
  /// Limits to 30 most recent requests to reduce Firestore reads
  Stream<List<AppRequest>> streamSentRequests(String profileId, {int limit = 30}) {
    final cleanProfileId = profileId.trim();
    final safeLimit = CoreFirestoreGuard.clampLimit(limit, defaultLimit: 30, maxLimit: 100);
    if (AppPlatformApi.isEnabled) {
      return Stream.fromFuture(retrieveSentRequests(cleanProfileId, limit: safeLimit));
    }
    if (!CoreFirestoreGuard.isSafeDocId(cleanProfileId)) {
      return Stream<List<AppRequest>>.value(const []);
    }
    return requestsReference
        .where(AppFirestoreConstants.from, isEqualTo: cleanProfileId)
        .orderBy(AppFirestoreConstants.createdTime, descending: true)
        .limit(safeLimit)
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
    final cleanProfileId = profileId.trim();
    final safeLimit = CoreFirestoreGuard.clampLimit(limit, defaultLimit: 30, maxLimit: 100);
    if (AppPlatformApi.isEnabled) {
      return Stream.fromFuture(retrieveRequests(cleanProfileId, limit: safeLimit));
    }
    if (!CoreFirestoreGuard.isSafeDocId(cleanProfileId)) {
      return Stream<List<AppRequest>>.value(const []);
    }
    return requestsReference
        .where(AppFirestoreConstants.to, isEqualTo: cleanProfileId)
        .orderBy(AppFirestoreConstants.createdTime, descending: true)
        .limit(safeLimit)
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
    final cleanId = requestId.trim();
    if (!CoreFirestoreGuard.isSafeDocId(cleanId)) return null;
    if (AppPlatformApi.isEnabled) {
      final sent = await retrieveSentRequests('');
      final foundSent = sent.where((r) => r.id == cleanId);
      if (foundSent.isNotEmpty) return foundSent.first;
      final received = await retrieveRequests('');
      final foundReceived = received.where((r) => r.id == cleanId);
      return foundReceived.isNotEmpty ? foundReceived.first : null;
    }
    try {
      final doc = await requestsReference.doc(cleanId).get();
      if (!doc.exists || doc.data() == null) return null;
      final request = AppRequest.fromJSON(doc.data()!);
      request.id = doc.id;
      return request;
    } catch (e, st) {
      NeomErrorLogger.recordError(e, st, module: 'neom_core', operation: 'RequestFirestore.getRequest');
      return null;
    }
  }

  /// Retrieves release approval requests for support+ users to review
  /// These are requests with 'to' = 'appBot' and pending status
  Future<List<AppRequest>> retrieveReleaseApprovalRequests({int limit = 50}) async {
    final safeLimit = CoreFirestoreGuard.clampLimit(limit, defaultLimit: 50, maxLimit: 200);
    AppConfig.logger.t("Retrieving Release Approval Requests (limit: $safeLimit)");
    if (AppPlatformApi.isEnabled) {
      return <AppRequest>[];
    }
    List<AppRequest> requests = <AppRequest>[];

    try {
      QuerySnapshot querySnapshot = await requestsReference
          .where(AppFirestoreConstants.to, isEqualTo: 'appBot')
          .where(AppFirestoreConstants.requestDecision, isEqualTo: RequestDecision.pending.name)
          .orderBy(AppFirestoreConstants.createdTime, descending: true)
          .limit(safeLimit)
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
    } catch (e, st) {
      NeomErrorLogger.recordError(e, st, module: 'neom_core', operation: 'RequestFirestore.retrieveReleaseApprovalRequests');
    }

    AppConfig.logger.d("${requests.length} release approval requests found");
    return requests;
  }

  /// Retrieves pending change-approval requests (content edits, ERP sensitive
  /// changes, Rehearsal Room approvals) for support+ reviewers.
  Future<List<AppRequest>> retrieveChangeApprovalRequests({int limit = 50}) async {
    final safeLimit = CoreFirestoreGuard.clampLimit(limit, defaultLimit: 50, maxLimit: 200);
    AppConfig.logger.t("Retrieving Change Approval Requests (limit: $safeLimit)");
    if (AppPlatformApi.isEnabled) {
      try {
        final res = await AppPlatformApi.client('requests').read(
          'retrieveChangeApprovalRequests',
          <String, Object?>{'onlyPending': true, 'limit': safeLimit},
          private: true,
        );
        return _parsePlatformItems(res);
      } catch (e, st) {
        NeomErrorLogger.recordError(e, st, module: 'neom_core', operation: 'RequestFirestore.retrieveChangeApprovalRequests.api');
        return <AppRequest>[];
      }
    }

    List<AppRequest> requests = <AppRequest>[];

    try {
      QuerySnapshot querySnapshot = await requestsReference
          .where(AppFirestoreConstants.to, isEqualTo: 'appBot')
          .where(AppFirestoreConstants.requestDecision, isEqualTo: RequestDecision.pending.name)
          .orderBy(AppFirestoreConstants.createdTime, descending: true)
          .limit(safeLimit)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        for (var snapshot in querySnapshot.docs) {
          AppRequest request = AppRequest.fromJSON(snapshot.data());
          request.id = snapshot.id;
          if (request.isChangeApprovalRequest) {
            requests.add(request);
            AppConfig.logger.t('Change approval request ${request.id} retrieved');
          }
        }
      }
    } catch (e, st) {
      NeomErrorLogger.recordError(e, st, module: 'neom_core', operation: 'RequestFirestore.retrieveChangeApprovalRequests');
    }

    AppConfig.logger.d("${requests.length} change approval requests found");
    return requests;
  }

}
