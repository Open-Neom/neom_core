import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:neom_commons/core/data/firestore/constants/app_firestore_collection_constants.dart';
import 'package:neom_commons/core/utils/app_utilities.dart';
import '../../domain/model/nupale/nupale_session.dart';
import '../../domain/use_cases/nupale_session_service.dart';
import '../../ui/analytics/nupale/nupale_stats_page.dart';

class NupaleSessionFirestore implements NupaleSessionService {

  final nupaleSessionsReference = FirebaseFirestore.instance.collection(AppFirestoreCollectionConstants.nupaleSessions);

  @override
  Future<String> insert(NupaleSession session) async {
    AppUtilities.logger.d("Inserting session ${session.id}");

    try {

      if(session.id.isNotEmpty) {
        await nupaleSessionsReference.doc(session.id).set(session.toJSON());
      } else {
        DocumentReference documentReference = await nupaleSessionsReference.add(session.toJSON());
        session.id = documentReference.id;
      }
      AppUtilities.logger.d("NupaleSession for ${session.itemName} was added with id ${session.id}");
    } catch (e) {
      AppUtilities.logger.e(e.toString());
    }

    return session.id;

  }


  @override
  Future<bool> remove(NupaleSession session) async {
    AppUtilities.logger.d("Removing product ${session.id}");

    try {
      await nupaleSessionsReference.doc(session.id).delete();
      AppUtilities.logger.d("session ${session.id} was removed");
      return true;

    } catch (e) {
      AppUtilities.logger.e(e.toString());
    }
    return false;
  }


  @override
  Future<NupaleSession> retrieveSession(String orderId) async {
    AppUtilities.logger.d("Retrieving session for id $orderId");
    NupaleSession session = NupaleSession();

    try {

      DocumentSnapshot documentSnapshot = await nupaleSessionsReference.doc(orderId).get();

      if (documentSnapshot.exists) {
        AppUtilities.logger.d("Snapshot is not empty");
          session = NupaleSession.fromJSON(documentSnapshot.data());
          session.id = documentSnapshot.id;
          AppUtilities.logger.d(session.toString());
        AppUtilities.logger.d("session ${session.id} was retrieved");
      } else {
        AppUtilities.logger.w("session ${session.id} was not found");
      }

    } catch (e) {
      AppUtilities.logger.e(e.toString());
    }
    return session;
  }


  @override
  Future<Map<String, NupaleSession>> retrieveFromList(List<String> sessionIds) async {
    AppUtilities.logger.d("Getting sessions from list");

    Map<String, NupaleSession> sessions = {};

    try {
      QuerySnapshot querySnapshot = await nupaleSessionsReference.get();

      if (querySnapshot.docs.isNotEmpty) {
        AppUtilities.logger.d("QuerySnapshot is not empty");
        for (var documentSnapshot in querySnapshot.docs) {
          if(sessionIds.contains(documentSnapshot.id)){
            NupaleSession session = NupaleSession.fromJSON(documentSnapshot.data());
            session.id = documentSnapshot.id;
            AppUtilities.logger.d("session ${session.id} was retrieved with details");
            sessions[session.id] = session;
          }
        }
      }

      AppUtilities.logger.d("${sessions.length} sessions were retrieved");
    } catch (e) {
      AppUtilities.logger.e(e);
    }
    return sessions;
  }

  @override
  Future<Map<String, NupaleSession>> fetchAll({String? itemId}) async {
    AppUtilities.logger.d("Getting sessions from list");

    Map<String, NupaleSession> sessions = {};

    try {
      QuerySnapshot querySnapshot = await nupaleSessionsReference.get();

      if (querySnapshot.docs.isNotEmpty) {
        AppUtilities.logger.d("QuerySnapshot is not empty");
        for (var documentSnapshot in querySnapshot.docs) {

          if(itemId == null || itemId == documentSnapshot.id){
            NupaleSession session = NupaleSession.fromJSON(documentSnapshot.data());
            session.id = documentSnapshot.id;
            AppUtilities.logger.d("session ${session.id} was retrieved with details");
            sessions[session.id] = session;
          }
        }
      }

      AppUtilities.logger.d("${sessions.length} sessions were retrieved");
    } catch (e) {
      AppUtilities.logger.e(e);
    }
    return sessions;
  }

}
