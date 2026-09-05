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
  final CollectionReference<Map<String, dynamic>> _eventsReference;

  EventFirestore({FirebaseFirestore? firestore})
    : _eventsReference = (firestore ?? FirebaseFirestore.instance).collection(
        AppFirestoreCollectionConstants.events,
      );

  static final Map<String, Event> _cachedEvents = {};
  static DateTime? _lastEventsFetchTime;
  static Future<Map<String, Event>>? _getEventsInFlight;
  static const Duration _cacheTtl = Duration(minutes: 5);

  /// Events are an authenticated-only surface. Keep this repository guarded
  /// as defense in depth because deep links and background controllers can
  /// reach it without passing through the UI's [AuthGuard].
  bool get _hasAuthenticatedUser => AppConfig.instance.canPersistUserActivity;

  static void invalidateCache() {
    _cachedEvents.clear();
    _lastEventsFetchTime = null;
  }

  @override
  Future<Event> retrieve(String eventId) async {
    if (!_hasAuthenticatedUser) return Event();
    AppConfig.logger.t("Retrieving Event by ID: $eventId");
    if (_cachedEvents.containsKey(eventId)) {
      return _cachedEvents[eventId]!;
    }
    Event event = Event();

    try {
      DocumentSnapshot documentSnapshot = await _eventsReference
          .doc(eventId)
          .get();
      if (!_hasAuthenticatedUser) return Event();
      if (documentSnapshot.exists && documentSnapshot.data() != null) {
        AppConfig.logger.t("Snapshot is not empty");
        event = Event.fromJSON(documentSnapshot.data() as Map<String, dynamic>);
        event.id = documentSnapshot.id;
        _cachedEvents[event.id] = event;
        AppConfig.logger.t(event.toString());
      }
    } catch (e, st) {
      NeomErrorLogger.recordError(
        e,
        st,
        module: 'neom_core',
        operation: 'EventFirestore.retrieve',
      );
    }

    return event;
  }

  /// Retrieves events, newest first.
  ///
  /// [limit] bounds the read: callers that only render a shelf or an upcoming
  /// strip should pass one, otherwise this downloads every event ever created
  /// on a cold cache. A limited call is served from the in-memory cache only
  /// when the cache already holds at least that many events.
  @override
  Future<List<Event>> retrieveEvents({
    bool forceRefresh = false,
    int? limit,
  }) async {
    if (!_hasAuthenticatedUser) return [];
    final cachedEvents = _cachedEvents.values.toList();
    final cacheIsFresh =
        _cachedEvents.isNotEmpty &&
        _lastEventsFetchTime != null &&
        DateTime.now().difference(_lastEventsFetchTime!) < _cacheTtl;
    final cacheCovers = limit == null || cachedEvents.length >= limit;

    if (!forceRefresh && cacheIsFresh && cacheCovers) {
      AppConfig.logger.d(
        "Retrieving Events from in-memory cache: ${_cachedEvents.length} events",
      );
      return limit == null ? cachedEvents : cachedEvents.take(limit).toList();
    }

    AppConfig.logger.d(
      "Retrieving Events from Firestore${limit != null ? ' (limit: $limit)' : ''}",
    );
    List<Event> events = [];

    try {
      Query query = _eventsReference.orderBy(
        AppFirestoreConstants.createdTime,
        descending: true,
      );
      if (limit != null) query = query.limit(limit);
      QuerySnapshot querySnapshot = await query.get();
      if (!_hasAuthenticatedUser) return [];
      if (querySnapshot.docs.isNotEmpty) {
        for (var postSnapshot in querySnapshot.docs) {
          final data = postSnapshot.data();
          if (data == null) continue;
          Event event = Event.fromJSON(data as Map<String, dynamic>);
          event.id = postSnapshot.id;
          events.add(event);
          _cachedEvents[event.id] = event;
        }
        _lastEventsFetchTime = DateTime.now();
        AppConfig.logger.d("${events.length} events found");
        return events;
      }
    } catch (e, st) {
      NeomErrorLogger.recordError(
        e,
        st,
        module: 'neom_core',
        operation: 'EventFirestore.retrieveEvents',
      );
    }

    AppConfig.logger.d("No Events Found");
    return events;
  }

  /// Events whose date has not passed, soonest first.
  ///
  /// The range filter and the ordering are both on `eventDate`, so this is
  /// served by Firestore's automatic single-field index — no composite index
  /// is required. Replaces downloading the whole collection and discarding
  /// past events on the client.
  ///
  /// Events stored without a date (`eventDate == 0`) are legacy rows and are
  /// excluded, matching the previous client-side filter.
  Future<List<Event>> retrieveUpcomingEvents({int? limit}) async {
    if (!_hasAuthenticatedUser) return [];
    final now = DateTime.now().millisecondsSinceEpoch;
    AppConfig.logger.d(
      "Retrieving upcoming events"
      "${limit != null ? ' (limit: $limit)' : ''}",
    );

    final List<Event> events = [];

    try {
      Query<Map<String, dynamic>> query = _eventsReference
          .where(AppFirestoreConstants.eventDate, isGreaterThanOrEqualTo: now)
          .orderBy(AppFirestoreConstants.eventDate);
      if (limit != null) query = query.limit(limit);

      final querySnapshot = await query.get();
      if (!_hasAuthenticatedUser) return [];
      for (final snapshot in querySnapshot.docs) {
        final event = Event.fromJSON(snapshot.data());
        event.id = snapshot.id;
        _cachedEvents[event.id] = event;
        events.add(event);
      }

      AppConfig.logger.d("${events.length} upcoming events found");
    } catch (e, st) {
      NeomErrorLogger.recordError(
        e,
        st,
        module: 'neom_core',
        operation: 'EventFirestore.retrieveUpcomingEvents',
      );
    }

    return events;
  }

  Future<Event?> getBySlug(String slug) async {
    if (!_hasAuthenticatedUser) return null;
    if (slug.isEmpty) return null;
    try {
      final querySnapshot = await _eventsReference
          .where('slug', isEqualTo: slug)
          .limit(1)
          .get();
      if (!_hasAuthenticatedUser) return null;
      if (querySnapshot.docs.isNotEmpty) {
        final doc = querySnapshot.docs.first;
        final event = Event.fromJSON(doc.data());
        event.id = doc.id;
        return event;
      }
    } catch (e, st) {
      NeomErrorLogger.recordError(
        e,
        st,
        module: 'neom_core',
        operation: 'EventFirestore.getBySlug',
      );
    }
    return null;
  }

  @override
  Future<String> insert(Event event, {String eventId = ""}) async {
    if (!_hasAuthenticatedUser) return '';
    AppConfig.logger.t("insert");
    try {
      // Auto-generate slug if empty
      if (event.slug.isEmpty && event.name.isNotEmpty) {
        final titleSlug = Event.generateSlug(event.name);
        final existing = await getBySlug(titleSlug);
        event.slug = existing == null
            ? titleSlug
            : Event.generateSlug('${event.ownerName} ${event.name}');
      }

      DocumentReference documentReference;
      if (eventId.isEmpty) {
        documentReference = await _eventsReference.add(event.toJSON());
        eventId = documentReference.id;
      } else {
        await _eventsReference.doc(eventId).set(event.toJSON());
      }

      if (await ProfileFirestore().addEvent(
        event.ownerId,
        eventId,
        EventAction.organize,
      )) {
        AppConfig.logger.d("Event added to Profile");
      }
      invalidateCache();
    } catch (e, st) {
      NeomErrorLogger.recordError(
        e,
        st,
        module: 'neom_core',
        operation: 'EventFirestore.insert',
      );
    }

    return eventId;
  }

  @override
  Future<bool> remove(Event event) async {
    if (!_hasAuthenticatedUser) return false;
    AppConfig.logger.t("Remove from firestore");
    bool wasDeleted = false;
    try {
      await _eventsReference.doc(event.id).delete();
      wasDeleted = await ProfileFirestore().removeEvent(
        event.ownerId,
        event.id,
        EventAction.organize,
      );
      await PostFirestore().removeEventPost(event.ownerId, event.id);
      await ActivityFeedFirestore().removeEventActivity(event.id);
      await RequestFirestore().removeEventRequests(event.id);
      if (event.collectivesFulfillment?.isNotEmpty ?? false) {
        for (var collectiveFulfillment in event.collectivesFulfillment!) {
          if (collectiveFulfillment.hasAccepted) {
            await CollectiveFirestore().removePlayingEvent(
              collectiveFulfillment.collectiveId,
              event.id,
            );
          }
        }
      }
      if (wasDeleted) invalidateCache();
    } catch (e, st) {
      NeomErrorLogger.recordError(
        e,
        st,
        module: 'neom_core',
        operation: 'EventFirestore.remove',
      );
    }

    return wasDeleted;
  }

  @override
  Future<Map<String, Event>> getEvents({bool forceRefresh = false}) async {
    if (!_hasAuthenticatedUser) return {};
    if (!forceRefresh &&
        _cachedEvents.isNotEmpty &&
        _lastEventsFetchTime != null &&
        DateTime.now().difference(_lastEventsFetchTime!) < _cacheTtl) {
      AppConfig.logger.d(
        "getEvents returned from in-memory cache: ${_cachedEvents.length} events",
      );
      return Map<String, Event>.from(_cachedEvents);
    }

    // EventController and the web sidebar mount in the same frame. Without a
    // shared in-flight Future they both observe an empty cache and issue the
    // exact same Firestore query. Coalesce that cold-start stampede.
    if (!forceRefresh && _getEventsInFlight != null) {
      AppConfig.logger.d('getEvents awaiting in-flight Firestore query');
      final events = await _getEventsInFlight!;
      return _hasAuthenticatedUser
          ? Map<String, Event>.from(events)
          : <String, Event>{};
    }

    final fetch = _fetchEvents();
    if (!forceRefresh) _getEventsInFlight = fetch;

    try {
      final events = await fetch;
      return _hasAuthenticatedUser
          ? Map<String, Event>.from(events)
          : <String, Event>{};
    } finally {
      if (identical(_getEventsInFlight, fetch)) {
        _getEventsInFlight = null;
      }
    }
  }

  Future<Map<String, Event>> _fetchEvents() async {
    AppConfig.logger.t("getEvents from Firestore");
    Map<String, Event> events = {};

    try {
      QuerySnapshot snapshot = await _eventsReference
          .orderBy(AppFirestoreConstants.createdTime, descending: true)
          .limit(CoreConstants.eventsLimit)
          .get();
      if (!_hasAuthenticatedUser) return {};

      for (var documentSnapshot in snapshot.docs) {
        final data = documentSnapshot.data();
        if (data == null) continue;
        Event event = Event.fromJSON(data as Map<String, dynamic>);
        event.id = documentSnapshot.id;
        events[event.id] = event;
        _cachedEvents[event.id] = event;
      }

      _lastEventsFetchTime = DateTime.now();
      AppConfig.logger.d("${events.length} Events Found");
    } catch (e, st) {
      NeomErrorLogger.recordError(
        e,
        st,
        module: 'neom_core',
        operation: 'EventFirestore.getEvents',
      );
    }

    return events;
  }

  @override
  Future<Map<String, Event>> getEventsById(List<String> eventIds) async {
    if (!_hasAuthenticatedUser) return {};
    AppConfig.logger.t(
      "Retrieving ${eventIds.length} events By id from firestore",
    );
    Map<String, Event> events = {};

    try {
      QuerySnapshot querySnapshot = await _eventsReference.get();
      if (!_hasAuthenticatedUser) return {};

      if (querySnapshot.docs.isNotEmpty) {
        for (var documentSnapshot in querySnapshot.docs) {
          if (eventIds.contains(documentSnapshot.id)) {
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
      NeomErrorLogger.recordError(
        e,
        st,
        module: 'neom_core',
        operation: 'EventFirestore.getEventsById',
      );
    }

    AppConfig.logger.t("${events.length} events found");
    return events;
  }

  @override
  Future<bool> fulfillInstrument(
    AppRequest appRequest,
    AppProfile mate,
    Event event,
  ) async {
    if (!_hasAuthenticatedUser) return false;
    AppConfig.logger.d(
      "Fulfilling instrument ${appRequest.instrument?.name ?? ""} for event ${event.id}",
    );

    try {
      InstrumentFulfillment previousInstrumentFulfillment =
          InstrumentFulfillment(
            id: appRequest.positionRequestedId,
            instrument: appRequest.instrument!,
          );
      for (var fulfillment in event.instrumentsFulfillment ?? []) {
        if (appRequest.instrument!.name == fulfillment.instrument.name &&
            previousInstrumentFulfillment.id ==
                appRequest.positionRequestedId) {
          previousInstrumentFulfillment = fulfillment;
        }
      }

      InstrumentFulfillment instrumentFulfillment = InstrumentFulfillment(
        id: appRequest.positionRequestedId,
        instrument: appRequest.instrument!,
        profileId: mate.id,
        profileImgUrl: mate.photoUrl,
        profileName: mate.name,
        isFulfilled: true,
      );

      // OPTIMIZED: Use direct update instead of get().then()
      final docRef = _eventsReference.doc(event.id);
      await docRef.update({
        AppFirestoreConstants.instrumentsFulfillment: FieldValue.arrayRemove([
          previousInstrumentFulfillment.toJSON(),
        ]),
      });
      await docRef.update({
        AppFirestoreConstants.instrumentsFulfillment: FieldValue.arrayUnion([
          instrumentFulfillment.toJSON(),
        ]),
      });

      AppConfig.logger.i(
        "Instrument ${appRequest.instrument?.name ?? ""} has been fulfilled",
      );
    } catch (e, st) {
      NeomErrorLogger.recordError(
        e,
        st,
        module: 'neom_core',
        operation: 'EventFirestore.fulfillInstrument',
      );
      return false;
    }

    return true;
  }

  @override
  Future<bool> unfulfillInstrument(
    AppRequest appRequest,
    AppProfile mate,
    Event event,
  ) async {
    if (!_hasAuthenticatedUser) return false;
    AppConfig.logger.d(
      "Unfulfilling instrument ${appRequest.instrument?.name ?? ""} for event ${event.id}",
    );

    try {
      InstrumentFulfillment alreadyFulfilledInstrument = InstrumentFulfillment(
        id: appRequest.positionRequestedId,
        instrument: appRequest.instrument!,
      );
      for (var fulfillment in event.instrumentsFulfillment ?? []) {
        if (appRequest.instrument!.name == fulfillment.instrument.name) {
          alreadyFulfilledInstrument = fulfillment;
        }
      }

      InstrumentFulfillment instrumentFulfillment = InstrumentFulfillment(
        id: appRequest.positionRequestedId,
        instrument: appRequest.instrument!,
        profileId: "",
        profileImgUrl: "",
        profileName: "",
        isFulfilled: false,
      );

      // OPTIMIZED: Use direct update instead of get().then()
      final docRef = _eventsReference.doc(event.id);
      await docRef.update({
        AppFirestoreConstants.instrumentsFulfillment: FieldValue.arrayRemove([
          alreadyFulfilledInstrument.toJSON(),
        ]),
      });
      await docRef.update({
        AppFirestoreConstants.instrumentsFulfillment: FieldValue.arrayUnion([
          instrumentFulfillment.toJSON(),
        ]),
      });

      AppConfig.logger.i(
        "Instrument ${appRequest.instrument?.name ?? ""} has been unfulfilled",
      );
    } catch (e, st) {
      NeomErrorLogger.recordError(
        e,
        st,
        module: 'neom_core',
        operation: 'EventFirestore.unfulfillInstrument',
      );
      return false;
    }

    return true;
  }

  @override
  Future<List<Event>> retrievePlayingEvents(String profileId) async {
    if (!_hasAuthenticatedUser) return [];
    AppConfig.logger.d("Retrieving PlayingEvents");

    List<Event> events = <Event>[];
    try {
      QuerySnapshot querySnapshot = await _eventsReference.get();
      if (!_hasAuthenticatedUser) return [];

      if (querySnapshot.docs.isNotEmpty) {
        AppConfig.logger.d("Snapshot is not empty");
        for (var documentSnapshot in querySnapshot.docs) {
          final data = documentSnapshot.data();
          if (data == null) continue;
          Event event = Event.fromJSON(data as Map<String, dynamic>);
          event.id = documentSnapshot.id;
          AppConfig.logger.d(event.toString());
          bool isPlaying = false;

          if (event.ownerId == profileId) {
            isPlaying = true;
          }

          for (var instrumentFulfillment
              in event.instrumentsFulfillment ?? []) {
            if (instrumentFulfillment.profileId == profileId) {
              isPlaying = true;
            }
          }

          if (isPlaying) events.add(event);
        }
      }
    } catch (e, st) {
      NeomErrorLogger.recordError(
        e,
        st,
        module: 'neom_core',
        operation: 'EventFirestore.retrievePlayingEvents',
      );
    }

    AppConfig.logger.d("${events.length} events found");
    return events;
  }

  @override
  Future<bool> fulfilled(String eventId) async {
    if (!_hasAuthenticatedUser) return false;
    AppConfig.logger.d("Event $eventId fulfilled");

    try {
      // OPTIMIZED: Use direct update instead of get().then()
      await _eventsReference.doc(eventId).update({
        AppFirestoreConstants.isFulfilled: true,
      });

      //TODO Create Collective Algorithm
      //CollectiveFirestore().insert(collective)

      AppConfig.logger.i("Event $eventId has been fulfilled");
    } catch (e, st) {
      NeomErrorLogger.recordError(
        e,
        st,
        module: 'neom_core',
        operation: 'EventFirestore.fulfilled',
      );
      return false;
    }

    return true;
  }

  @override
  Future<bool> unFulfilled(String eventId) async {
    if (!_hasAuthenticatedUser) return false;
    AppConfig.logger.d("Event $eventId unfulfilled");

    try {
      // OPTIMIZED: Use direct update instead of get().then()
      await _eventsReference.doc(eventId).update({
        AppFirestoreConstants.isFulfilled: false,
      });

      AppConfig.logger.i("Event $eventId has been unfulfilled");
    } catch (e, st) {
      NeomErrorLogger.recordError(
        e,
        st,
        module: 'neom_core',
        operation: 'EventFirestore.unFulfilled',
      );
      return false;
    }

    return true;
  }

  @override
  Future<bool> addGoingProfile({
    required String eventId,
    required String profileId,
  }) async {
    if (!_hasAuthenticatedUser) return false;
    AppConfig.logger.t("$profileId would be added as going to Event $eventId");

    try {
      // OPTIMIZED: Use direct update instead of iterating all events
      await _eventsReference.doc(eventId).update({
        AppFirestoreConstants.goingProfiles: FieldValue.arrayUnion([profileId]),
      });

      AppConfig.logger.d(
        "Profile $profileId has been added as going to event $eventId",
      );
      return true;
    } catch (e, st) {
      NeomErrorLogger.recordError(
        e,
        st,
        module: 'neom_core',
        operation: 'EventFirestore.addGoingProfile',
      );
    }
    return false;
  }

  @override
  Future<bool> removeGoingProfile({
    required String eventId,
    required String profileId,
  }) async {
    if (!_hasAuthenticatedUser) return false;
    AppConfig.logger.d(
      "$profileId would be removed from going to Event $eventId",
    );

    try {
      // OPTIMIZED: Use direct update instead of iterating all events
      await _eventsReference.doc(eventId).update({
        AppFirestoreConstants.goingProfiles: FieldValue.arrayRemove([
          profileId,
        ]),
      });

      AppConfig.logger.d(
        "Profile $profileId has been removed from going to event $eventId",
      );
      return true;
    } catch (e, st) {
      NeomErrorLogger.recordError(
        e,
        st,
        module: 'neom_core',
        operation: 'EventFirestore.removeGoingProfile',
      );
    }
    return false;
  }

  @override
  Future<bool> update(Event event) async {
    if (!_hasAuthenticatedUser) return false;
    AppConfig.logger.t("Updating event ${event.id}");
    try {
      await _eventsReference.doc(event.id).update(event.toJSON());
      AppConfig.logger.d("Event ${event.id} updated successfully");
      invalidateCache();
      return true;
    } catch (e, st) {
      NeomErrorLogger.recordError(
        e,
        st,
        module: 'neom_core',
        operation: 'EventFirestore.update',
      );
      return false;
    }
  }

  /// Updates specific fields of an event
  Future<bool> updateFields(String eventId, Map<String, dynamic> fields) async {
    if (!_hasAuthenticatedUser) return false;
    AppConfig.logger.t("Updating event $eventId fields: ${fields.keys}");
    try {
      await _eventsReference.doc(eventId).update(fields);
      AppConfig.logger.d("Event $eventId fields updated successfully");
      return true;
    } catch (e, st) {
      NeomErrorLogger.recordError(
        e,
        st,
        module: 'neom_core',
        operation: 'EventFirestore.updateFields',
      );
      return false;
    }
  }

  @override
  Future<bool> fulfillCollective(
    String collectiveId,
    AppProfile itemmate,
    Event event,
  ) async {
    if (!_hasAuthenticatedUser) return false;
    AppConfig.logger.d(
      "Fulfilling collective $collectiveId for event ${event.id}",
    );

    try {
      CollectiveFulfillment previousCollectiveFulfillment =
          CollectiveFulfillment(collectiveId: collectiveId);
      for (var fulfillment in event.collectivesFulfillment ?? []) {
        if (collectiveId == fulfillment.collectiveId) {
          previousCollectiveFulfillment = fulfillment;
        }
      }

      CollectiveFulfillment collectiveFulfillment = CollectiveFulfillment(
        collectiveName: previousCollectiveFulfillment.collectiveName,
        collectiveImgUrl: previousCollectiveFulfillment.collectiveImgUrl,
        collectiveId: previousCollectiveFulfillment.collectiveId,
        hasAccepted: true,
      );

      // OPTIMIZED: Use direct update instead of get().then()
      final docRef = _eventsReference.doc(event.id);
      await docRef.update({
        AppFirestoreConstants.collectivesFulfillment: FieldValue.arrayRemove([
          previousCollectiveFulfillment.toJSON(),
        ]),
      });
      await docRef.update({
        AppFirestoreConstants.collectivesFulfillment: FieldValue.arrayUnion([
          collectiveFulfillment.toJSON(),
        ]),
      });

      AppConfig.logger.i(
        "Collective ${collectiveFulfillment.collectiveName} has been fulfilled",
      );
    } catch (e, st) {
      NeomErrorLogger.recordError(
        e,
        st,
        module: 'neom_core',
        operation: 'EventFirestore.fulfillCollective',
      );
      return false;
    }

    return true;
  }
}
