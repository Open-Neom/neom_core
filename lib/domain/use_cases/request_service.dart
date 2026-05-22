
import '../model/app_request.dart';
import '../model/collective.dart';
import '../model/event.dart';

abstract class RequestService {

  Future<void> loadGeneralRequests();
  Future<void> loadSentRequests();
  Future<void> getRequestsFromEvent(String eventId);
  void gotoRequestDetails(AppRequest req, {Event? ev, Collective? b});
  Future<void> acceptRequest();
  Future<void> declineRequest();
  Future<void> moveRequestToPending();

}
