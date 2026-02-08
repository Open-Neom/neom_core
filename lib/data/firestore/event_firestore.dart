import 'package:cloud_firestore/cloud_firestore.dart';

import '../../app_config.dart';
import '../../domain/model/app_profile.dart';
import '../../domain/model/app_request.dart';
import '../../domain/model/band_fulfillment.dart';
import '../../domain/model/event.dart';
import '../../domain/model/instrument_fulfillment.dart';
import '../../domain/repository/event_repository.dart';
import '../../utils/constants/core_constants.dart';
import '../../utils/enums/event_action.dart';
import 'activity_feed_firestore.dart';
import 'band_firestore.dart';
import 'constants/app_firestore_collection_constants.dart';
import 'constants/app_firestore_constants.dart';
import 'post_firestore.dart';
import 'profile_firestore.dart';
import 'request_firestore.dart';

class EventFirestore implements EventRepository {
  
  final eventsReference = FirebaseFirestore.instance.collection(AppFirestoreCollectionConstants.events);


  @override
  Future<Event> retrieve(String eventId) async {
    AppConfig.logger.t("Retrieving Event by ID: $eventId");
    Event event = Event();

    try {
      DocumentSnapshot documentSnapshot = await eventsReference.doc(eventId).get();
      if (documentSnapshot.exists && documentSnapshot.data() != null) {
        AppConfig.logger.t("Snapshot is not empty");
        event = Event.fromJSON(documentSnapshot.data() as Map<String, dynamic>);
        event.id = documentSnapshot.id;
        AppConfig.logger.t(event.toString());
      }
    } catch (e) {
      AppConfig.logger.e(e.toString());
    }


    return event;
  }

  @override
  Future<List<Event>> retrieveEvents() async {
    AppConfig.logger.d("Retrieving Events");
    List<Event> events = [];
    QuerySnapshot querySnapshot = await eventsReference.get();

    try {
      if (querySnapshot.docs.isNotEmpty) {
        AppConfig.logger.d("Snapshot is not empty");
        for (var postSnapshot in querySnapshot.docs) {
          final data = postSnapshot.data();
          if (data == null) continue;
          Event event = Event.fromJSON(data as Map<String, dynamic>);
          event.id = postSnapshot.id;
          AppConfig.logger.d(event.toString());
          events.add(event);
        }
        AppConfig.logger.d("${events.length} events found");
        return events;
      }
    } catch (e) {
      AppConfig.logger.e(e.toString());
    }

    AppConfig.logger.d("No Events Found");
    return events;
  }

  @override
  Future<String> insert(Event event,{String eventId = ""}) async {
    AppConfig.logger.t("insert");
    try {
      DocumentReference documentReference;
      if(eventId.isEmpty) {
        documentReference = await eventsReference.add(event.toJSON());
        eventId = documentReference.id;
      } else {
        await eventsReference.doc(eventId).set(event.toJSON());
      }

      if(await ProfileFirestore().addEvent(event.ownerId, eventId, EventAction.organize)){
        AppConfig.logger.d("Event added to Profile");
      }
    } catch (e) {
      AppConfig.logger.e(e.toString());
    }

    return eventId;
  }


  @override
  Future<bool> remove(Event event) async {
    AppConfig.logger.t("Remove from firestore");
    bool wasDeleted = false;
    try {
      await eventsReference.doc(event.id).delete();
      wasDeleted = await ProfileFirestore().removeEvent(event.ownerId, event.id, EventAction.organize);
      await PostFirestore().removeEventPost(event.ownerId, event.id);
      await ActivityFeedFirestore().removeEventActivity(event.id);
      await RequestFirestore().removeEventRequests(event.id);
      if(event.bandsFulfillment?.isNotEmpty ?? false) {
        for (var bandFulfillment in event.bandsFulfillment!) {
          if(bandFulfillment.hasAccepted) {
            await BandFirestore().removePlayingEvent(bandFulfillment.bandId, event.id);
          }
        }
      }
    } catch (e) {
      AppConfig.logger.e(e.toString());
    }

    return wasDeleted;
  }


  @override
  Future<Map<String, Event>> getEvents() async {
    AppConfig.logger.t("getEvents");
    Map<String, Event> events = {};

    try {
      QuerySnapshot snapshot = await eventsReference
          .orderBy(AppFirestoreConstants.createdTime, descending: true)
          .limit(CoreConstants.eventsLimit)
          .get();

      for (var documentSnapshot in snapshot.docs) {
        final data = documentSnapshot.data();
        if (data == null) continue;
        Event event = Event.fromJSON(data as Map<String, dynamic>);
        event.id = documentSnapshot.id;
        events[event.id] = event;
      }


      AppConfig.logger.d("${events.length} Events Found");
    } catch (e) {
      AppConfig.logger.e(e.toString());
    }

    return events;
  }

  @override
  Future<Map<String, Event>> getEventsById(List<String> eventIds) async {
    AppConfig.logger.t("Retrieving ${eventIds.length} events By id from firestore");
    Map<String, Event> events = {};

    try {
      QuerySnapshot querySnapshot = await eventsReference.get();

      if (querySnapshot.docs.isNotEmpty) {
        for (var documentSnapshot in querySnapshot.docs) {
          if(eventIds.contains(documentSnapshot.id)){
            final data = documentSnapshot.data();
            if (data == null) continue;
            Event event = Event.fromJSON(data as Map<String, dynamic>);
            event.id = documentSnapshot.id;
            AppConfig.logger.t('Event ${event.name} retrieved');
            events[event.id] = event;
          }
        }
      }
    } catch (e) {
      AppConfig.logger.e(e.toString());
    }


    AppConfig.logger.t("${events.length} events found");
    return events;
  }


  @override
  Future<bool> fulfillInstrument(AppRequest appRequest, AppProfile mate, Event event) async {
    AppConfig.logger.d("Fulfilling instrument ${appRequest.instrument?.name ?? ""} for event ${event.id}");

    try {

      InstrumentFulfillment previousInstrumentFulfillment = InstrumentFulfillment(
          id: appRequest.positionRequestedId, instrument: appRequest.instrument!
      );
      for (var fulfillment in event.instrumentsFulfillment ?? []) {
        if(appRequest.instrument!.name == fulfillment.instrument.name
            && previousInstrumentFulfillment.id == appRequest.positionRequestedId) {
          previousInstrumentFulfillment = fulfillment;
        }
      }

      InstrumentFulfillment instrumentFulfillment = InstrumentFulfillment(
          id: appRequest.positionRequestedId,
          instrument: appRequest.instrument!,
          profileId: mate.id,
          profileImgUrl: mate.photoUrl,
          profileName: mate.name,
          isFulfilled: true);

      // OPTIMIZED: Use direct update instead of get().then()
      final docRef = eventsReference.doc(event.id);
      await docRef.update({
        AppFirestoreConstants.instrumentsFulfillment:
            FieldValue.arrayRemove([previousInstrumentFulfillment.toJSON()])
      });
      await docRef.update({
        AppFirestoreConstants.instrumentsFulfillment:
            FieldValue.arrayUnion([instrumentFulfillment.toJSON()])
      });

      AppConfig.logger.i("Instrument ${appRequest.instrument?.name ?? ""} has been fulfilled");
    } catch (e) {
      AppConfig.logger.e.toString();
      return false;
    }

    return true;
  }


  @override
  Future<bool> unfulfillInstrument(AppRequest appRequest, AppProfile mate, Event event) async {
    AppConfig.logger.d("Unfulfilling instrument ${appRequest.instrument?.name ?? ""} for event ${event.id}");

    try {

      InstrumentFulfillment alreadyFulfilledInstrument = InstrumentFulfillment(
          id: appRequest.positionRequestedId,
          instrument: appRequest.instrument!
      );
      for (var fulfillment in event.instrumentsFulfillment ?? []) {
        if(appRequest.instrument!.name == fulfillment.instrument.name) {
          alreadyFulfilledInstrument = fulfillment;
        }
      }

      InstrumentFulfillment instrumentFulfillment = InstrumentFulfillment(
          id: appRequest.positionRequestedId,
          instrument: appRequest.instrument!,
          profileId: "",
          profileImgUrl: "",
          profileName: "",
          isFulfilled: false);

      // OPTIMIZED: Use direct update instead of get().then()
      final docRef = eventsReference.doc(event.id);
      await docRef.update({
        AppFirestoreConstants.instrumentsFulfillment:
            FieldValue.arrayRemove([alreadyFulfilledInstrument.toJSON()])
      });
      await docRef.update({
        AppFirestoreConstants.instrumentsFulfillment:
            FieldValue.arrayUnion([instrumentFulfillment.toJSON()])
      });

      AppConfig.logger.i("Instrument ${appRequest.instrument?.name ?? ""} has been unfulfilled");
    } catch (e) {
      AppConfig.logger.e.toString();
      return false;
    }

    return true;
  }


  @override
  Future<List<Event>> retrievePlayingEvents(String profileId) async {
    AppConfig.logger.d("Retrieving PlayingEvents");

    List<Event> events = <Event>[];
    bool isPlaying = false;

    try {
      QuerySnapshot querySnapshot = await eventsReference.get();

      if (querySnapshot.docs.isNotEmpty) {
        AppConfig.logger.d("Snapshot is not empty");
        for (var documentSnapshot in querySnapshot.docs) {
          final data = documentSnapshot.data();
          if (data == null) continue;
          Event event = Event.fromJSON(data as Map<String, dynamic>);
          event.id = documentSnapshot.id;
          AppConfig.logger.d(event.toString());

          if(event.ownerId == profileId) {
            isPlaying = true;
          }

          for (var instrumentFulfillment in event.instrumentsFulfillment ?? []) {
            if(instrumentFulfillment.profileId == profileId) {
              isPlaying = true;
            }
          }

          if(isPlaying) events.add(event);

        }
      }
    } catch (e) {
      AppConfig.logger.e(e.toString());
    }

    AppConfig.logger.d("${events.length} events found");
    return events;
  }


  @override
  Future<bool> fulfilled(String eventId) async {
    AppConfig.logger.d("Event $eventId fulfilled");

    try {

      // OPTIMIZED: Use direct update instead of get().then()
      await eventsReference.doc(eventId).update({
        AppFirestoreConstants.isFulfilled: true
      });

      //TODO Create Band Algorithm
      //BandFirestore().insert(band)

      AppConfig.logger.i("Event $eventId has been fulfilled");
    } catch (e) {
      AppConfig.logger.e.toString();
      return false;
    }

    return true;
  }


  @override
  Future<bool> unFulfilled(String eventId) async {
    AppConfig.logger.d("Event $eventId unfulfilled");

    try {

      // OPTIMIZED: Use direct update instead of get().then()
      await eventsReference.doc(eventId).update({
        AppFirestoreConstants.isFulfilled: false
      });

      AppConfig.logger.i("Event $eventId has been unfulfilled");
    } catch (e) {
      AppConfig.logger.e.toString();
      return false;
    }

    return true;
  }


  @override
  Future<bool> addGoingProfile({required String eventId, required String profileId}) async {
    AppConfig.logger.t("$profileId would be added as going to Event $eventId");

    try {

      // OPTIMIZED: Use direct update instead of iterating all events
      await eventsReference.doc(eventId).update({
        AppFirestoreConstants.goingProfiles: FieldValue.arrayUnion([profileId])
      });

      AppConfig.logger.d("Profile $profileId has been added as going to event $eventId");
      return true;
    } catch (e) {
      AppConfig.logger.e(e.toString());
    }
    return false;
  }


  @override
  Future<bool> removeGoingProfile({required String eventId, required String profileId}) async {
    AppConfig.logger.d("$profileId would be removed from going to Event $eventId");

    try {

      // OPTIMIZED: Use direct update instead of iterating all events
      await eventsReference.doc(eventId).update({
        AppFirestoreConstants.goingProfiles: FieldValue.arrayRemove([profileId])
      });

      AppConfig.logger.d("Profile $profileId has been removed from going to event $eventId");
      return true;
    } catch (e) {
      AppConfig.logger.e(e.toString());
    }
    return false;
  }


  @override
  Future<bool> update(Event event) async {
    AppConfig.logger.t("Updating event ${event.id}");
    try {
      await eventsReference.doc(event.id).update(event.toJSON());
      AppConfig.logger.d("Event ${event.id} updated successfully");
      return true;
    } catch (e) {
      AppConfig.logger.e(e.toString());
      return false;
    }
  }

  /// Updates specific fields of an event
  Future<bool> updateFields(String eventId, Map<String, dynamic> fields) async {
    AppConfig.logger.t("Updating event $eventId fields: ${fields.keys}");
    try {
      await eventsReference.doc(eventId).update(fields);
      AppConfig.logger.d("Event $eventId fields updated successfully");
      return true;
    } catch (e) {
      AppConfig.logger.e(e.toString());
      return false;
    }
  }

  @override
  Future<bool> fulfillBand(String bandId, AppProfile itemmate, Event event) async {
  AppConfig.logger.d("Fulfilling band $bandId for event ${event.id}");

  try {

    BandFulfillment previousBandFulfillment = BandFulfillment(bandId: bandId);
    for (var fulfillment in event.bandsFulfillment ?? []) {
      if(bandId == fulfillment.bandId) {
        previousBandFulfillment = fulfillment;
      }
    }

    BandFulfillment bandFulfillment = BandFulfillment(
      bandName: previousBandFulfillment.bandName,
      bandImgUrl: previousBandFulfillment.bandImgUrl,
      bandId: previousBandFulfillment.bandId,
      hasAccepted: true
    );

    // OPTIMIZED: Use direct update instead of get().then()
    final docRef = eventsReference.doc(event.id);
    await docRef.update({
      AppFirestoreConstants.bandsFulfillment:
          FieldValue.arrayRemove([previousBandFulfillment.toJSON()])
    });
    await docRef.update({
      AppFirestoreConstants.bandsFulfillment:
          FieldValue.arrayUnion([bandFulfillment.toJSON()])
    });

    AppConfig.logger.i("Band ${bandFulfillment.bandName} has been fulfilled");
  } catch (e) {
    AppConfig.logger.e.toString();
    return false;
  }

  return true;
  }

}
