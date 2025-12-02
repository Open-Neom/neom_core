import 'package:cloud_firestore/cloud_firestore.dart';

import '../../app_config.dart';
import '../../domain/model/nupale/nupale_session.dart';
import '../../domain/repository/nupale_session_repository.dart';

import 'constants/app_firestore_collection_constants.dart';
import 'constants/app_firestore_constants.dart';

class NupaleSessionFirestore implements NupaleSessionRepository {

  final nupaleSessionsReference = FirebaseFirestore.instance.collection(AppFirestoreCollectionConstants.nupaleSessions);

  @override
  Future<String> insert(NupaleSession session) async {
    AppConfig.logger.d("Inserting session ${session.id}");

    try {

      if(session.id.isNotEmpty) {
        await nupaleSessionsReference.doc(session.id).set(session.toJSON());
      } else {
        DocumentReference documentReference = await nupaleSessionsReference.add(session.toJSON());
        session.id = documentReference.id;
      }
      AppConfig.logger.d("NupaleSession for ${session.itemName} was added with id ${session.id}");
    } catch (e) {
      AppConfig.logger.e(e.toString());
    }

    return session.id;

  }


  @override
  Future<bool> remove(String sessionId) async {
    AppConfig.logger.d("Removing product $sessionId");

    try {
      await nupaleSessionsReference.doc(sessionId).delete();
      AppConfig.logger.d("session $sessionId was removed");
      return true;

    } catch (e) {
      AppConfig.logger.e(e.toString());
    }
    return false;
  }


  @override
  Future<NupaleSession> retrieveSession(String orderId) async {
    AppConfig.logger.d("Retrieving session for id $orderId");
    NupaleSession session = NupaleSession();

    try {

      DocumentSnapshot documentSnapshot = await nupaleSessionsReference.doc(orderId).get();

      if (documentSnapshot.exists) {
        AppConfig.logger.d("Snapshot is not empty");
          session = NupaleSession.fromJSON(documentSnapshot.data());
          session.id = documentSnapshot.id;
          AppConfig.logger.d(session.toString());
        AppConfig.logger.d("session ${session.id} was retrieved");
      } else {
        AppConfig.logger.w("session ${session.id} was not found");
      }

    } catch (e) {
      AppConfig.logger.e(e.toString());
    }
    return session;
  }


  @override
  Future<Map<String, NupaleSession>> retrieveFromList(List<String> sessionIds) async {
    AppConfig.logger.d("Getting sessions from list");

    Map<String, NupaleSession> sessions = {};

    try {
      QuerySnapshot querySnapshot = await nupaleSessionsReference.get();

      if (querySnapshot.docs.isNotEmpty) {
        AppConfig.logger.d("QuerySnapshot is not empty");
        for (var documentSnapshot in querySnapshot.docs) {
          if(sessionIds.contains(documentSnapshot.id)){
            NupaleSession session = NupaleSession.fromJSON(documentSnapshot.data());
            session.id = documentSnapshot.id;
            AppConfig.logger.d("session ${session.id} was retrieved with details");
            sessions[session.id] = session;
          }
        }
      }

      AppConfig.logger.d("${sessions.length} sessions were retrieved");
    } catch (e) {
      AppConfig.logger.e(e);
    }
    return sessions;
  }

  @override
  Future<Map<String, NupaleSession>> fetchAll({String? itemId, bool skipTest = true}) async {
    AppConfig.logger.d("Getting sessions from list");

    Map<String, NupaleSession> sessions = {};

    try {
      QuerySnapshot querySnapshot = await nupaleSessionsReference.get();

      if (querySnapshot.docs.isNotEmpty) {
        AppConfig.logger.d("QuerySnapshot is not empty");
        for (var documentSnapshot in querySnapshot.docs) {

          if(itemId == null || itemId == documentSnapshot.id){
            NupaleSession session = NupaleSession.fromJSON(documentSnapshot.data());
            if(skipTest && session.isTest) {
              AppConfig.logger.d("session ${session.id} is a test session");
              continue;
            }
            session.id = documentSnapshot.id;
            AppConfig.logger.t("session ${session.id} was retrieved with details");
            sessions[session.id] = session;
          }
        }
      }

      AppConfig.logger.d("${sessions.length} sessions were retrieved");
    } catch (e) {
      AppConfig.logger.e(e);
    }
    return sessions;
  }

  /// Elimina todos los documentos en la colección 'nupaleSessions' cuya ID tenga exactamente 4 caracteres.
  Future<int> removeSessionsWithShortIds() async {
    AppConfig.logger.d("Starting removal of sessions with 4-character IDs");
    int deletedCount = 0;

    try {
      // Obtener todos los documentos en la colección.
      // Nota: Si la colección es muy grande, esto puede ser ineficiente y costoso.
      // Firestore no tiene una consulta directa para "ID length".
      QuerySnapshot querySnapshot = await nupaleSessionsReference.get();

      if (querySnapshot.docs.isNotEmpty) {
        AppConfig.logger.d("Found ${querySnapshot.docs.length} sessions. Checking IDs...");
        // Iterar a través de los documentos
        for (var documentSnapshot in querySnapshot.docs) {
          // Verificar la longitud del ID del documento
          if (documentSnapshot.id.length == 4) {
            AppConfig.logger.d("Deleting session with short ID: ${documentSnapshot.id}");
            // Eliminar el documento usando su referencia
            await documentSnapshot.reference.delete();
            deletedCount++;
          } else {

          }
        }
        AppConfig.logger.d("Finished checking sessions. $deletedCount sessions with 4-character IDs were deleted.");
      } else {
        AppConfig.logger.d("No sessions found in the collection.");
      }

    } catch (e) {
      AppConfig.logger.e("Error removing sessions with short IDs: ${e.toString()}");
      // Considera cómo manejar este error, quizás lanzando la excepción
      // rethrow;
    }

    return deletedCount; // Retornar el número de documentos eliminados
  }

  /// Elimina todos los documentos en la colección 'nupaleSessions' donde el campo 'isTest' sea true.
  Future<int> removeTestSessions() async {
    AppConfig.logger.d("Starting removal of test sessions");
    int deletedCount = 0;

    try {
      // Crear una consulta para obtener documentos donde 'isTest' es true.
      Query query = nupaleSessionsReference.where(AppFirestoreConstants.isTest, isEqualTo: true); // Asumo que 'isTest' es el nombre del campo

      // Ejecutar la consulta
      QuerySnapshot querySnapshot = await query.get();

      if (querySnapshot.docs.isNotEmpty) {
        AppConfig.logger.d("Found ${querySnapshot.docs.length} test sessions to delete.");
        // Iterar a través de los documentos encontrados
        for (var documentSnapshot in querySnapshot.docs) {
          AppConfig.logger.d("Deleting test session with ID: ${documentSnapshot.id}");
          // Eliminar el documento usando su referencia
          await documentSnapshot.reference.delete();
          deletedCount++;
        }
        AppConfig.logger.d("Finished deleting test sessions. $deletedCount test sessions were deleted.");
      } else {
        AppConfig.logger.d("No test sessions found in the collection.");
      }

    } catch (e) {
      AppConfig.logger.e("Error removing test sessions: ${e.toString()}");
      // Considera cómo manejar este error, quizás lanzando la excepción
      // rethrow;
    }

    return deletedCount; // Retornar el número de documentos eliminados
  }


}
