import 'package:cloud_firestore/cloud_firestore.dart';

import '../../app_config.dart';
import '../../domain/model/app_profile.dart';
import '../../domain/model/app_request.dart';
import '../../domain/model/collective_fulfillment.dart';
import '../../domain/model/event.dart';
import '../../domain/model/instrument_fulfillment.dart';
import '../../domain/repository/event_repository.dart';
import '../../utils/constants/core_constants.dart';
import '../../utils/enums/event_action.dart';
import '../../utils/neom_error_logger.dart';
import 'activity_feed_firestore.dart';
import 'collective_firestore.dart';
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
    } catch (e, st) {
      NeomErrorLogger.recordError(e, st, module: 'neom_core', operation: 'EventFirestore.retrieve');
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
    } catch (e, st) {
      NeomErrorLogger.recordError(e, st, module: 'neom_core', operation: 'EventFirestore.retrieveEvents');
    }

    AppConfig.logger.d("No Events Found");
    return events;
  }

  Future<Event?> getBySlug(String slug) async {
    if (slug.isEmpty) return null;
    try {
      final querySnapshot = await eventsReference
          .where('slug', isEqualTo: slug)
          .limit(1)
          .get();
      if (querySnapshot.docs.isNotEmpty) {
        final doc = querySnapshot.docs.first;
        final event = Event.fromJSON(doc.data());
        event.id = doc.id;
        return event;
      }
    } catch (e, st) {
      NeomErrorLogger.recordError(e, st, module: 'neom_core', operation: 'EventFirestore.getBySlug');
    }
    return null;
  }

  @override
  Future<String> insert(Event event,{String eventId = ""}) async {
    AppConfig.logger.t("insert");
    try {
      // Auto-generate slug if empty
      if (event.slug.isEmpty && event.name.isNotEmpty) {
        final titleSlug = Event.generateSlug(event.name);
        final existing = await getBySlug(titleSlug);
        event.slug = existing == null ? titleSlug : Event.generateSlug('${event.ownerName} ${event.name}');
      }

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
    } catch (e, st) {
      NeomErrorLogger.recordError(e, st, module: 'neom_core', operation: 'EventFirestore.insert');
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
      if(event.collectivesFulfillment?.isNotEmpty ?? false) {
        for (var collectiveFulfillment in event.collectivesFulfillment!) {
          if(collectiveFulfillment.hasAccepted) {
            await CollectiveFirestore().removePlayingEvent(collectiveFulfillment.collectiveId, event.id);
          }
        }
      }
    } catch (e, st) {
      NeomErrorLogger.recordError(e, st, module: 'neom_core', operation: 'EventFirestore.remove');
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
    } catch (e, st) {
      NeomErrorLogger.recordError(e, st, module: 'neom_core', operation: 'EventFirestore.getEvents');
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
    } catch (e, st) {
      NeomErrorLogger.recordError(e, st, module: 'neom_core', operation: 'EventFirestore.getEventsById');
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
    } catch (e, st) {
      NeomErrorLogger.recordError(e, st, module: 'neom_core', operation: 'EventFirestore.fulfillInstrument');
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
    } catch (e, st) {
      NeomErrorLogger.recordError(e, st, module: 'neom_core', operation: 'EventFirestore.unfulfillInstrument');
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
    } catch (e, st) {
      NeomErrorLogger.recordError(e, st, module: 'neom_core', operation: 'EventFirestore.retrievePlayingEvents');
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

      //TODO Create Collective Algorithm
      //CollectiveFirestore().insert(collective)

      AppConfig.logger.i("Event $eventId has been fulfilled");
    } catch (e, st) {
      NeomErrorLogger.recordError(e, st, module: 'neom_core', operation: 'EventFirestore.fulfilled');
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
    } catch (e, st) {
      NeomErrorLogger.recordError(e, st, module: 'neom_core', operation: 'EventFirestore.unFulfilled');
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
    } catch (e, st) {
      NeomErrorLogger.recordError(e, st, module: 'neom_core', operation: 'EventFirestore.addGoingProfile');
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
    } catch (e, st) {
      NeomErrorLogger.recordError(e, st, module: 'neom_core', operation: 'EventFirestore.removeGoingProfile');
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
    } catch (e, st) {
      NeomErrorLogger.recordError(e, st, module: 'neom_core', operation: 'EventFirestore.update');
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
    } catch (e, st) {
      NeomErrorLogger.recordError(e, st, module: 'neom_core', operation: 'EventFirestore.updateFields');
      return false;
    }
  }

  @override
  Future<bool> fulfillCollective(String collectiveId, AppProfile itemmate, Event event) async {
  AppConfig.logger.d("Fulfilling collective $collectiveId for event ${event.id}");

  try {

    CollectiveFulfillment previousCollectiveFulfillment = CollectiveFulfillment(collectiveId: collectiveId);
    for (var fulfillment in event.collectivesFulfillment ?? []) {
      if(collectiveId == fulfillment.collectiveId) {
        previousCollectiveFulfillment = fulfillment;
      }
    }

    CollectiveFulfillment collectiveFulfillment = CollectiveFulfillment(
      collectiveName: previousCollectiveFulfillment.collectiveName,
      collectiveImgUrl: previousCollectiveFulfillment.collectiveImgUrl,
      collectiveId: previousCollectiveFulfillment.collectiveId,
      hasAccepted: true
    );

    // OPTIMIZED: Use direct update instead of get().then()
    final docRef = eventsReference.doc(event.id);
    await docRef.update({
      AppFirestoreConstants.collectivesFulfillment:
          FieldValue.arrayRemove([previousCollectiveFulfillment.toJSON()])
    });
    await docRef.update({
      AppFirestoreConstants.collectivesFulfillment:
          FieldValue.arrayUnion([collectiveFulfillment.toJSON()])
    });

    AppConfig.logger.i("Collective ${collectiveFulfillment.collectiveName} has been fulfilled");
  } catch (e, st) {
    NeomErrorLogger.recordError(e, st, module: 'neom_core', operation: 'EventFirestore.fulfillCollective');
    return false;
  }

  return true;
  }

}
