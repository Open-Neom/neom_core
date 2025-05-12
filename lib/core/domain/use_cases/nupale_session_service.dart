import '../model/nupale/nupale_session.dart';

abstract class NupaleSessionService {

  Future<String> insert(NupaleSession session);
  Future<bool> remove(String sessionId);
  Future<Map<String, NupaleSession>> retrieveFromList(List<String> sessionIds);
  Future<NupaleSession> retrieveSession(String orderId);

}
