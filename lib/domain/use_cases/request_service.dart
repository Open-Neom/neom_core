
import '../model/app_request.dart';
import '../model/band.dart';
import '../model/event.dart';

abstract class RequestService {

  Future<void> loadGeneralRequests();
  Future<void> loadSentRequests();
  Future<void> getRequestsFromEvent(String eventId);
  void gotoRequestDetails(AppRequest req, {Event? ev, Band? b});
  Future<void> acceptRequest();
  Future<void> declineRequest();
  Future<void> moveRequestToPending();

}
