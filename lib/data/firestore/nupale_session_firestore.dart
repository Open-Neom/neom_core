import 'package:cloud_firestore/cloud_firestore.dart';

import '../../app_config.dart';
import '../../domain/model/nupale/nupale_session.dart';
import '../../domain/repository/nupale_session_repository.dart';
import '../../utils/enums/consumption_audience.dart';
import '../../utils/neom_error_logger.dart';

import 'constants/app_firestore_collection_constants.dart';
import 'constants/app_firestore_constants.dart';
import 'core_firestore_guard.dart';

class NupaleSessionFirestore implements NupaleSessionRepository {

  FirebaseFirestore get _firestore => FirebaseFirestore.instance;
  CollectionReference<Map<String, dynamic>> get nupaleSessionsReference =>
      _firestore.collection(AppFirestoreCollectionConstants.nupaleSessions);

  /// One collection per audience. The monthly payout reads only the member
  /// one, so authors' and free-tier reading can never reach the pool.
  static const Map<ConsumptionAudience, String> collectionByAudience = {
    ConsumptionAudience.member: AppFirestoreCollectionConstants.nupaleSessions,
    ConsumptionAudience.author: AppFirestoreCollectionConstants.authorsNupaleSessions,
    ConsumptionAudience.freeTier: AppFirestoreCollectionConstants.freemiumNupaleSessions,
  };

  CollectionReference<Map<String, dynamic>> _referenceFor(ConsumptionAudience audience) =>
      _firestore.collection(collectionByAudience[audience]!);

  static Map<String, NupaleSession> _cachedAllSessions = {};
  static DateTime? _lastAllSessionsFetchTime;
  static const Duration _allSessionsCacheTtl = Duration(minutes: 5);

  static void invalidateAllSessionsCache() {
    _cachedAllSessions.clear();
    _lastAllSessionsFetchTime = null;
  }

  @override
  Future<String> insert(NupaleSession session) async {
    if (!AppConfig.instance.canPersistUserActivity) {
      AppConfig.logger.d(
        "Skipping Nupale session persistence for guest or unloaded user",
      );
      return session.id;
    }

    AppConfig.logger.d("Inserting session ${session.id}");

    try {
      final reference = _referenceFor(session.audience);
      if(session.id.isNotEmpty) {
        final cleanId = session.id.trim();
        if (!CoreFirestoreGuard.isSafeDocId(cleanId)) return '';
        session.id = cleanId;
        await reference.doc(cleanId).set(session.toJSON());
      } else {
        DocumentReference documentReference = await reference.add(session.toJSON());
        session.id = documentReference.id;
      }
      AppConfig.logger.d("NupaleSession for ${session.itemName} was added with id ${session.id}");
      invalidateAllSessionsCache();
    } catch (e, st) {
      NeomErrorLogger.recordError(e, st, module: 'neom_core', operation: 'NupaleSessionFirestore.insert');
    }

    return session.id;
  }


  @override
  Future<bool> remove(String sessionId) async {
    final cleanId = sessionId.trim();
    if (!CoreFirestoreGuard.isSafeDocId(cleanId)) return false;
    AppConfig.logger.d("Removing product $cleanId");

    try {
      await nupaleSessionsReference.doc(cleanId).delete();
      AppConfig.logger.d("session $cleanId was removed");
      return true;
    } catch (e, st) {
      NeomErrorLogger.recordError(e, st, module: 'neom_core', operation: 'NupaleSessionFirestore.remove');
    }
    return false;
  }


  @override
  Future<NupaleSession> retrieveSession(String orderId) async {
    final cleanId = orderId.trim();
    NupaleSession session = NupaleSession();
    if (!CoreFirestoreGuard.isSafeDocId(cleanId)) return session;
    AppConfig.logger.d("Retrieving session for id $cleanId");

    try {
      DocumentSnapshot documentSnapshot = await nupaleSessionsReference.doc(cleanId).get();

      if (documentSnapshot.exists && documentSnapshot.data() != null) {
        AppConfig.logger.d("Snapshot is not empty");
        session = NupaleSession.fromJSON(documentSnapshot.data());
        session.id = documentSnapshot.id;
        AppConfig.logger.d(session.toString());
        AppConfig.logger.d("session ${session.id} was retrieved");
      } else {
        AppConfig.logger.w("session $cleanId was not found");
      }
    } catch (e, st) {
      NeomErrorLogger.recordError(e, st, module: 'neom_core', operation: 'NupaleSessionFirestore.retrieveSession');
    }
    return session;
  }


  @override
  Future<Map<String, NupaleSession>> retrieveFromList(List<String> sessionIds) async {
    AppConfig.logger.d("Getting ${sessionIds.length} sessions from list");

    Map<String, NupaleSession> sessions = {};
    final chunks = CoreFirestoreGuard.chunkValidIds(sessionIds);
    if (chunks.isEmpty) return sessions;

    try {
      for (final chunk in chunks) {
        final snapshot = await nupaleSessionsReference
            .where(FieldPath.documentId, whereIn: chunk)
            .get();
        for (var doc in snapshot.docs) {
          NupaleSession session = NupaleSession.fromJSON(doc.data());
          session.id = doc.id;
          sessions[session.id] = session;
        }
      }

      AppConfig.logger.d("${sessions.length} sessions were retrieved");
    } catch (e, st) {
      NeomErrorLogger.recordError(e, st, module: 'neom_core', operation: 'NupaleSessionFirestore.retrieveFromList');
    }
    return sessions;
  }

  @override
  Future<Map<String, NupaleSession>> fetchAll({String? itemId, bool skipTest = true, int limit = 200, bool forceRefresh = false}) async {
    if (itemId == null && !forceRefresh && _cachedAllSessions.isNotEmpty && _lastAllSessionsFetchTime != null &&
        DateTime.now().difference(_lastAllSessionsFetchTime!) < _allSessionsCacheTtl) {
      AppConfig.logger.d("fetchAll returned from in-memory cache: ${_cachedAllSessions.length} sessions");
      return Map<String, NupaleSession>.from(_cachedAllSessions);
    }

    final safeLimit = CoreFirestoreGuard.clampLimit(limit, defaultLimit: 200, maxLimit: 500);
    AppConfig.logger.d("Getting sessions from list (limit: $safeLimit)");

    Map<String, NupaleSession> sessions = {};

    try {
      // Analytics show every audience; royalty math filters on
      // session.audience. The collection is the source of truth for it.
      for (final audience in ConsumptionAudience.values) {
        Query query = _referenceFor(audience);
        if (itemId != null) {
          final cleanItemId = itemId.trim();
          if (!CoreFirestoreGuard.isSafeDocId(cleanItemId)) continue;
          query = query.where(AppFirestoreConstants.itemId, isEqualTo: cleanItemId);
        }
        query = query.limit(safeLimit);

        QuerySnapshot querySnapshot = await query.get();
        for (var documentSnapshot in querySnapshot.docs) {
          final data = documentSnapshot.data() as Map<String, dynamic>?;
          if (data != null) {
            NupaleSession session = NupaleSession.fromJSON(data);
            if (skipTest && session.isTest) {
              continue;
            }
            session.id = documentSnapshot.id;
            session.audience = audience;
            sessions[session.id] = session;
          }
        }
      }

      if (itemId == null) {
        _cachedAllSessions = Map<String, NupaleSession>.from(sessions);
        _lastAllSessionsFetchTime = DateTime.now();
      }

      AppConfig.logger.d("${sessions.length} sessions were retrieved");
    } catch (e, st) {
      NeomErrorLogger.recordError(e, st, module: 'neom_core', operation: 'NupaleSessionFirestore.fetchAll');
    }
    return sessions;
  }

  @override
  Future<Map<String, NupaleSession>> fetchByReaderEmail(String email, {bool skipTest = true}) async {
    final cleanEmail = email.trim();
    if (cleanEmail.isEmpty) return {};
    AppConfig.logger.d("Fetching sessions for readerEmail: $cleanEmail");

    Map<String, NupaleSession> sessions = {};

    try {
      for (final audience in ConsumptionAudience.values) {
        QuerySnapshot querySnapshot = await _referenceFor(audience)
            .where(AppFirestoreConstants.readerEmail, isEqualTo: cleanEmail)
            .limit(500)
            .get();
        for (var documentSnapshot in querySnapshot.docs) {
          NupaleSession session = NupaleSession.fromJSON(documentSnapshot.data());
          if (skipTest && session.isTest) continue;
          session.id = documentSnapshot.id;
          session.audience = audience;
          sessions[session.id] = session;
        }
      }

      AppConfig.logger.d("${sessions.length} sessions found for $cleanEmail");
    } catch (e, st) {
      NeomErrorLogger.recordError(e, st, module: 'neom_core', operation: 'NupaleSessionFirestore.fetchByReaderEmail');
    }

    return sessions;
  }

  /// Elimina todos los documentos en la colección 'nupaleSessions' cuya ID tenga exactamente 4 caracteres.
  Future<int> removeSessionsWithShortIds() async {
    AppConfig.logger.d("Starting removal of sessions with 4-character IDs");
    int deletedCount = 0;

    try {
      QuerySnapshot querySnapshot = await nupaleSessionsReference.limit(2000).get();

      if (querySnapshot.docs.isNotEmpty) {
        AppConfig.logger.d("Found ${querySnapshot.docs.length} sessions. Checking IDs...");
        WriteBatch batch = _firestore.batch();
        int ops = 0;
        for (var documentSnapshot in querySnapshot.docs) {
          if (documentSnapshot.id.length == 4) {
            batch.delete(documentSnapshot.reference);
            deletedCount++;
            ops++;
            if (ops >= 450) {
              await batch.commit();
              batch = _firestore.batch();
              ops = 0;
            }
          }
        }
        if (ops > 0) {
          await batch.commit();
        }
        AppConfig.logger.d("Finished checking sessions. $deletedCount sessions with 4-character IDs were deleted.");
      } else {
        AppConfig.logger.d("No sessions found in the collection.");
      }

    } catch (e, st) {
      NeomErrorLogger.recordError(e, st, module: 'neom_core', operation: 'NupaleSessionFirestore.removeSessionsWithShortIds');
    }

    return deletedCount;
  }

  /// Elimina todos los documentos en la colección 'nupaleSessions' donde el campo 'isTest' sea true.
  Future<int> removeTestSessions() async {
    AppConfig.logger.d("Starting removal of test sessions");
    int deletedCount = 0;

    try {
      QuerySnapshot querySnapshot = await nupaleSessionsReference
          .where(AppFirestoreConstants.isTest, isEqualTo: true)
          .limit(2000)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        AppConfig.logger.d("Found ${querySnapshot.docs.length} test sessions to delete.");
        WriteBatch batch = _firestore.batch();
        int ops = 0;
        for (var documentSnapshot in querySnapshot.docs) {
          batch.delete(documentSnapshot.reference);
          deletedCount++;
          ops++;
          if (ops >= 450) {
            await batch.commit();
            batch = _firestore.batch();
            ops = 0;
          }
        }
        if (ops > 0) {
          await batch.commit();
        }
        AppConfig.logger.d("Finished deleting test sessions. $deletedCount test sessions were deleted.");
      } else {
        AppConfig.logger.d("No test sessions found in the collection.");
      }

    } catch (e, st) {
      NeomErrorLogger.recordError(e, st, module: 'neom_core', operation: 'NupaleSessionFirestore.removeTestSessions');
    }

    return deletedCount;
  }

}
