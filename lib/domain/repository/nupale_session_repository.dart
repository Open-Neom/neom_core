import '../model/nupale/nupale_session.dart';

abstract class NupaleSessionRepository {

  Future<String> insert(NupaleSession session);
  Future<bool> remove(String sessionId);
  Future<Map<String, NupaleSession>> retrieveFromList(List<String> sessionIds);
  Future<NupaleSession> retrieveSession(String orderId);
  Future<Map<String, NupaleSession>> fetchAll({String? itemId, bool skipTest = true, int limit = 200});
  Future<Map<String, NupaleSession>> fetchByReaderEmail(String email, {bool skipTest = true});

}
