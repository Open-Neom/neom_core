import '../model/app_profile.dart';
import '../model/app_request.dart';
import '../model/event.dart';

abstract class EventRepository {

  Future<String> insert(Event event);
  Future<Event> retrieve(String eventId);
  Future<bool> remove(Event event);
  Future<List<Event>> retrieveEvents();

  Future<Map<String, Event>> getEvents();
  Future<Map<String, Event>> getEventsById(List<String> eventIds);
  Future<bool> fulfillInstrument(AppRequest appRequest, AppProfile mate, Event event);
  Future<bool> unfulfillInstrument(AppRequest appRequest, AppProfile mate, Event event);
  Future<List<Event>> retrievePlayingEvents(String profileId);
  Future<bool> fulfilled(String eventId);
  Future<bool> unFulfilled(String eventId);
  Future<bool> addGoingProfile({required String eventId, required String profileId});
  Future<bool> removeGoingProfile({required String eventId, required String profileId});
  Future<bool> fulfillBand(String bandId, AppProfile mate, Event event);

}
