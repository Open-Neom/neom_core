import '../model/collective.dart';
import '../model/collective_member.dart';

abstract class CollectiveRepository {

  Future<String> insert(Collective collective);
  Future<Collective> retrieve(String collectiveId);
  Future<bool> remove(Collective collective);

  Future<Map<String, Collective>> getCollectives();
  Future<Map<String, Collective>> getCollectivesFromList(List<String> collectiveIds);

  Future<bool> fulfillCollectiveMember(String collectiveId, CollectiveMember collectiveMember);
  Future<bool> unfulfillCollectiveMember(String collectiveId, CollectiveMember collectiveMember);

  Future<bool> isAvailableName(String collectiveName);

  Future<bool> addPlayingEvent(String collectiveId, String eventId);
  Future<bool> addPlayingEventToCollectives(List<String> collectiveIds, String eventId);


  Future<bool> removePlayingEvent(String collectiveId, String eventId);
  Future<bool> removeCollectiveMember(String collectiveId, CollectiveMember collectiveMember);

}
