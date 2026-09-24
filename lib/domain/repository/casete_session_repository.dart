import '../model/casete/casete_session.dart';

abstract class CaseteSessionRepository {

  /// Stores [session] in the collection of its [CaseteSession.audience]:
  /// members, authors or free tier. Only the member collection funds
  /// royalties.
  Future<String> insert(CaseteSession session);
  Future<bool> remove(String sessionId);
  Future<Map<String, CaseteSession>> retrieveFromList(List<String> sessionIds);
  Future<CaseteSession> retrieveSession(String orderId);
  Future<Map<String, CaseteSession>> fetchAll({String? itemId, bool skipTest = true, int limit = 200});

}
