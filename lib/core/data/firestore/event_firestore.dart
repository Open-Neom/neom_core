import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/model/app_profile.dart';
import '../../domain/model/app_request.dart';
import '../../domain/model/band_fulfillment.dart';
import '../../domain/model/event.dart';
import '../../domain/model/instrument_fulfillment.dart';
import '../../domain/repository/event_repository.dart';
import '../../utils/app_utilities.dart';
import '../../utils/constants/app_constants.dart';
import '../../utils/enums/event_action.dart';
import 'activity_feed_firestore.dart';
import 'band_firestore.dart';
import 'constants/app_firestore_collection_constants.dart';
import 'constants/app_firestore_constants.dart';
import 'post_firestore.dart';
import 'profile_firestore.dart';
import 'request_firestore.dart';

class EventFirestore implements EventRepository {

  var logger = AppUtilities.logger;
  final eventsReference = FirebaseFirestore.instance.collection(AppFirestoreCollectionConstants.events);


  @override
  Future<Event> retrieve(String eventId) async {
    logger.d("Retrieving Events");
    Event event = Event();

    try {
      DocumentSnapshot documentSnapshot = await eventsReference.doc(eventId).get();
      if (documentSnapshot.exists) {
        logger.d("Snapshot is not empty");
        event = Event.fromJSON(documentSnapshot.data());
        event.id = documentSnapshot.id;
        logger.d(event.toString());
      }
    } catch (e) {
      logger.e(e.toString());
    }


    return event;
  }

  @override
  Future<List<Event>> retrieveEvents() async {
    logger.d("Retrieving Events");
    List<Event> events = [];
    QuerySnapshot querySnapshot = await eventsReference.get();

    try {
      if (querySnapshot.docs.isNotEmpty) {
        logger.d("Snapshot is not empty");
        for (var postSnapshot in querySnapshot.docs) {
          Event event = Event.fromJSON(postSnapshot.data());
          event.id = postSnapshot.id;
          logger.d(event.toString());
          events.add(event);
        }
        logger.d("${events.length} events found");
        return events;
      }
    } catch (e) {
      logger.e(e.toString());
    }

    logger.d("No Events Found");
    return events;
  }

  @override
  Future<String> insert(Event event) async {
    logger.d("");
    String eventId = "";
    try {
      DocumentReference documentReference = await eventsReference.add(event.toJSON());
      eventId = documentReference.id;
      if(await ProfileFirestore().addEvent(event.owner!.id, eventId, EventAction.organize)){
        logger.d("Event added to Profile");
      }
    } catch (e) {
      logger.e(e.toString());
    }

    return eventId;
  }


  @override
  Future<bool> remove(Event event) async {
    logger.d("");
    bool wasDeleted = false;
    try {
      await eventsReference.doc(event.id).delete();
      wasDeleted = await ProfileFirestore().removeEvent(event.owner!.id, event.id, EventAction.organize);
      await PostFirestore().removeEventPost(event.owner!.id, event.id);
      await ActivityFeedFirestore().removeEventActivity(event.id);
      await RequestFirestore().removeEventRequests(event.id);
      if(event.bandFulfillments.isNotEmpty) {
        for (var bandFulfillment in event.bandFulfillments) {
          if(bandFulfillment.hasAccepted) {
            await BandFirestore().removePlayingEvent(bandFulfillment.bandId, event.id);
          }
        }
      }
    } catch (e) {
      logger.e(e.toString());
    }

    return wasDeleted;
  }


  @override
  Future<Map<String, Event>> getEvents() async {
    logger.d("");
    Map<String, Event> events = {};

    try {
      QuerySnapshot snapshot = await eventsReference
          .orderBy(AppFirestoreConstants.createdTime, descending: true)
          .limit(AppConstants.eventsLimit)
          .get();

      logger.d("${snapshot.docs.length} Events Found as Snapshot");
      for (var documentSnapshot in snapshot.docs) {
        Event event = Event.fromJSON(documentSnapshot.data());
        event.id = documentSnapshot.id;
        events[event.id] = event;
      }


      logger.d("${events.length} Events Found");
    } catch (e) {
      logger.e(e.toString());
    }

    return events;
  }

  @override
  Future<Map<String, Event>> getEventsById(List<String> eventIds) async {

    logger.d("Retrieving Events By Id");
    Map<String, Event> events = {};

    try {
      QuerySnapshot querySnapshot = await eventsReference.get();

      if (querySnapshot.docs.isNotEmpty) {
        logger.d("Snapshot is not empty");
        for (var documentSnapshot in querySnapshot.docs) {
          if(eventIds.contains(documentSnapshot.id)){
            Event event = Event.fromJSON(documentSnapshot.data());
            event.id = documentSnapshot.id;
            logger.d(event.toString());
            events[event.id] = event;
          }
        }
      }
    } catch (e) {
      logger.e(e.toString());
    }


    logger.d("${events.length} events found");
    return events;
  }


  @override
  Future<bool> fulfillInstrument(AppRequest appRequest, AppProfile mate, Event event) async {
    logger.d("Fulfilling instrument ${appRequest.instrument?.name ?? ""} for event ${event.id}");

    try {

      InstrumentFulfillment previousInstrumentFulfillment = InstrumentFulfillment(
          id: appRequest.positionRequestedId, instrument: appRequest.instrument!
      );
      for (var fulfillment in event.instrumentFulfillments) {
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

      await eventsReference.doc(event.id).get()
          .then((querySnapshot) async {
        await querySnapshot.reference
            .update({
              AppFirestoreConstants.instrumentFulfillments:
              FieldValue.arrayRemove([previousInstrumentFulfillment.toJSON()])
            });

        await querySnapshot.reference
            .update({
              AppFirestoreConstants.instrumentFulfillments:
              FieldValue.arrayUnion([instrumentFulfillment.toJSON()])
            });
        }
      );

      logger.i("Instrument ${appRequest.instrument?.name ?? ""} has been fulfilled");
    } catch (e) {
      logger.e.toString();
      return false;
    }

    return true;
  }


  @override
  Future<bool> unfulfillInstrument(AppRequest appRequest, AppProfile mate, Event event) async {
    logger.d("Unfulfilling instrument ${appRequest.instrument?.name ?? ""} for event ${event.id}");

    try {

      InstrumentFulfillment alreadyFulfilledInstrument = InstrumentFulfillment(
          id: appRequest.positionRequestedId,
          instrument: appRequest.instrument!
      );
      for (var fulfillment in event.instrumentFulfillments) {
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

      await eventsReference.doc(event.id).get()
          .then((querySnapshot) async {

        await querySnapshot.reference
            .update({
              AppFirestoreConstants.instrumentFulfillments:
              FieldValue.arrayRemove([alreadyFulfilledInstrument.toJSON()])
            });

        await querySnapshot.reference
            .update({
          AppFirestoreConstants.instrumentFulfillments:
          FieldValue.arrayUnion([instrumentFulfillment.toJSON()])}
        );
      }
      );

      logger.i("Instrument ${appRequest.instrument?.name ?? ""} has been unfulfilled");
    } catch (e) {
      logger.e.toString();
      return false;
    }

    return true;
  }


  @override
  Future<List<Event>> retrievePlayingEvents(String profileId) async {
    logger.d("Retrieving PlayingEvents");

    List<Event> events = <Event>[];
    bool isPlaying = false;

    try {
      QuerySnapshot querySnapshot = await eventsReference.get();

      if (querySnapshot.docs.isNotEmpty) {
        logger.d("Snapshot is not empty");
        for (var documentSnapshot in querySnapshot.docs) {
          Event event = Event.fromJSON(documentSnapshot.data());
          event.id = documentSnapshot.id;
          logger.d(event.toString());

          if(event.owner!.id == profileId) {
            isPlaying = true;
          }

          for (var instrumentFulfillment in event.instrumentFulfillments) {
            if(instrumentFulfillment.profileId == profileId) {
              isPlaying = true;
            }
          }

          if(isPlaying) events.add(event);

        }
      }
    } catch (e) {
      logger.e(e.toString());
    }

    logger.d("${events.length} events found");
    return events;
  }


  @override
  Future<bool> fulfilled(String eventId) async {
    logger.d("Event $eventId fulfilled");

    try {

      await eventsReference.doc(eventId).get()
          .then((querySnapshot) {
            querySnapshot.reference
            .update({AppFirestoreConstants.isFulfilled: true});
          });

      //TODO Create Band Algorithm
      //BandFirestore().insert(band)

      logger.i("Event $eventId has been fulfilled");
    } catch (e) {
      logger.e.toString();
      return false;
    }

    return true;
  }


  @override
  Future<bool> unFulfilled(String eventId) async {
    logger.d("Event $eventId unfulfilled");

    try {

      await eventsReference.doc(eventId).get()
          .then((querySnapshot) {
        querySnapshot.reference.update({
          AppFirestoreConstants.isFulfilled: false
        });
      });

      logger.i("Event $eventId has been unfulfilled");
    } catch (e) {
      logger.e.toString();
      return false;
    }

    return true;
  }


  @override
  Future<bool> addGoingProfile({required String eventId, required String profileId}) async {
    logger.d("$profileId would be added as going to Event $eventId");

    try {

      await eventsReference.get()
          .then((querySnapshot) async {
        for (var document in querySnapshot.docs) {
          if(document.id == eventId) {
            await document.reference.update({
              AppFirestoreConstants.goingProfiles: FieldValue.arrayUnion([profileId])
            });
          }
        }
      });

      logger.d("Profile $profileId has been added as going to event $eventId");
      return true;
    } catch (e) {
      logger.e(e.toString());
    }
    return false;
  }


  @override
  Future<bool> removeGoingProfile({required String eventId, required String profileId}) async {
    logger.d("$profileId would be removed from going to Event $eventId");

    try {

      await eventsReference.get()
          .then((querySnapshot) async {
        for (var document in querySnapshot.docs) {
          if(document.id == eventId) {
            await document.reference.update({
              AppFirestoreConstants.goingProfiles: FieldValue.arrayRemove([profileId])
            });
          }
        }
      });

      logger.d("Profile $profileId has been removed from going to event $eventId");
      return true;
    } catch (e) {
      logger.e(e.toString());
    }
    return false;
  }


  @override
  Future<bool> fulfillBand(String bandId, AppProfile itemmate, Event event) async {
  logger.d("Fulfilling band $bandId for event ${event.id}");

  try {

    BandFulfillment previousBandFulfillment = BandFulfillment(bandId: bandId);
    for (var fulfillment in event.bandFulfillments) {
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

    await eventsReference.doc(event.id).get()
        .then((querySnapshot) async {
      await querySnapshot.reference
          .update({
        AppFirestoreConstants.bandFulfillments:
        FieldValue.arrayRemove([previousBandFulfillment.toJSON()])
      });

      await querySnapshot.reference
          .update({
        AppFirestoreConstants.bandFulfillments:
        FieldValue.arrayUnion([bandFulfillment.toJSON()])
      });
    }
    );

    logger.i("Band ${bandFulfillment.bandName} has been fulfilled");
  } catch (e) {
    logger.e.toString();
    return false;
  }

  return true;
  }

}
