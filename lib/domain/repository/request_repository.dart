import '../model/app_request.dart';


abstract class RequestRepository {

  Future<List<AppRequest>> retrieveRequests(String profileId);
  Future<List<AppRequest>> retrieveSentRequests(String profileId);
  Future<List<AppRequest>> retrieveInvitationRequests(String profileId);

  Future<void> insert(AppRequest request);
  Future<bool> remove(AppRequest request);
}
