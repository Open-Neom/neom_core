import 'package:cloud_firestore/cloud_firestore.dart';

import '../../app_config.dart';
import '../../domain/model/app_profile.dart';
import '../../domain/model/app_request.dart';
import '../../domain/model/collective_fulfillment.dart';
import '../../domain/model/event.dart';
import '../../domain/model/instrument_fulfillment.dart';
import '../../domain/model/ticket.dart';
import '../../domain/repository/event_repository.dart';
import '../../utils/enums/event_action.dart';
import '../../utils/neom_error_logger.dart';
import '../api/app_platform_api.dart';
import 'activity_feed_firestore.dart';
import 'collective_firestore.dart';
import 'constants/app_firestore_collection_constants.dart';
import 'constants/app_firestore_constants.dart';
import 'post_firestore.dart';
import 'profile_firestore.dart';
import 'request_firestore.dart';

class EventFirestore implements EventRepository {
  final FirebaseFirestore? _injectedFirestore;

  EventFirestore({FirebaseFirestore? firestore})
    : _injectedFirestore = firestore;

  CollectionReference<Map<String, dynamic>> get _eventsReference =>
      (_injectedFirestore ?? FirebaseFirestore.instance).collection(
        AppFirestoreCollectionConstants.events,
      );

  static final Map<String, Event> _cachedEvents = {};
  static DateTime? _lastEventsFetchTime;
  static bool _fullEventsCacheReady = false;
  static Future<Map<String, Event>>? _getEventsInFlight;
  static const Duration _cacheTtl = Duration(minutes: 5);
  static const int _eventsListLimit = 60;

  /// Events are an authenticated-only surface on Firestore. On Gigmeout's
  /// autonomous platform API, public event reads are served with `private: false`
  /// while all mutations remain authenticated.
  bool get _hasAuthenticatedUser => AppConfig.instance.canPersistUserActivity;

  static void invalidateCache() {
    _cachedEvents.clear();
    _lastEventsFetchTime = null;
    _fullEventsCacheReady = false;
  }

  Map<String, dynamic> _asMap(dynamic res) {
    if (res is Map) {
      final inner = res['value'];
      if (inner is Map) return Map<String, dynamic>.from(inner);
      return Map<String, dynamic>.from(res);
    }
    return <String, dynamic>{};
  }

  List<Event> _parsePlatformItems(dynamic res) {
    if (res is! Map) return <Event>[];
    final raw = res['items'];
    if (raw is! List) return <Event>[];
    return raw.whereType<Map>().map((m) {
      final map = Map<String, dynamic>.from(m);
      final ev = Event.fromJSON(map);
      if (ev.id.isEmpty && map['id'] != null) {
        ev.id = map['id'].toString();
      }
      return ev;
    }).toList();
  }

  /// Registers attendance to a free event on Gigmeout's autonomous server
  /// and returns an HMAC-signed QR [Ticket] (`gmo://ticket/v1/...`).
  Future<Ticket?> assistFreeEvent(
    String eventId, {
    String buyerName = '',
  }) async {
    if (!_hasAuthenticatedUser || eventId.isEmpty) return null;
    if (!AppPlatformApi.isEnabled) return null;
    try {
      final res = await AppPlatformApi.client('events').mutate(
        'assistFreeEvent',
        <String, Object?>{
          'eventId': eventId,
          if (buyerName.isNotEmpty) 'buyerName': buyerName,
        },
        durable: false,
      );
      _cachedEvents.remove(eventId);
      final map = _asMap(res);
      if (map.isNotEmpty && (map['id'] != null || map['qrToken'] != null)) {
        return Ticket.fromJSON(map);
      }
    } catch (e, st) {
      NeomErrorLogger.recordError(
        e,
        st,
        module: 'neom_core',
        operation: 'EventFirestore.assistFreeEvent',
      );
      rethrow;
    }
    return null;
  }

  @override
  Future<Event> retrieve(String eventId) async {
    if (eventId.isEmpty) return Event();
    if (!AppPlatformApi.isEnabled && !_hasAuthenticatedUser) return Event();
    AppConfig.logger.t("Retrieving Event by ID: $eventId");
    if (_cachedEvents.containsKey(eventId)) {
      return _cachedEvents[eventId]!;
    }
    if (AppPlatformApi.isEnabled) {
      try {
        final res = await AppPlatformApi.client('events').read(
          'getEvent',
          <String, Object?>{'eventId': eventId},
          private: false,
        );
        final list = _parsePlatformItems(res);
        if (list.isNotEmpty) {
          final ev = list.first;
          _cachedEvents[ev.id] = ev;
          return ev;
        }
      } catch (e, st) {
        NeomErrorLogger.recordError(
          e,
          st,
          module: 'neom_core',
          operation: 'EventFirestore.retrieve.platform',
        );
      }
      return Event();
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
    if (!AppPlatformApi.isEnabled && !_hasAuthenticatedUser) return [];
    final cachedEvents = _cachedEvents.values.toList();
    final cacheIsFresh =
        _cachedEvents.isNotEmpty &&
        _lastEventsFetchTime != null &&
        DateTime.now().difference(_lastEventsFetchTime!) < _cacheTtl;
    final cacheCovers =
        (limit == null && _fullEventsCacheReady) ||
        (limit != null && cachedEvents.length >= limit);

    if (!forceRefresh && cacheIsFresh && cacheCovers) {
      AppConfig.logger.d(
        "Retrieving Events from in-memory cache: ${_cachedEvents.length} events",
      );
      return limit == null ? cachedEvents : cachedEvents.take(limit).toList();
    }

    if (AppPlatformApi.isEnabled) {
      try {
        final res = await AppPlatformApi.client('events').read(
          'retrieveEvents',
          const <String, Object?>{},
          private: false,
        );
        final list = _parsePlatformItems(res)
          ..sort((a, b) => b.createdTime.compareTo(a.createdTime));
        for (final ev in list) {
          _cachedEvents[ev.id] = ev;
        }
        _lastEventsFetchTime = DateTime.now();
        _fullEventsCacheReady = true;
        return limit == null ? list : list.take(limit).toList();
      } catch (e, st) {
        NeomErrorLogger.recordError(
          e,
          st,
          module: 'neom_core',
          operation: 'EventFirestore.retrieveEvents.platform',
        );
        return <Event>[];
      }
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
          try {
            Event event = Event.fromJSON(data as Map<String, dynamic>);
            event.id = postSnapshot.id;
            events.add(event);
            _cachedEvents[event.id] = event;
          } catch (e, st) {
            NeomErrorLogger.recordError(
              e,
              st,
              module: 'neom_core',
              operation: 'EventFirestore.retrieveEvents.parse:${postSnapshot.id}',
            );
          }
        }
        _lastEventsFetchTime = DateTime.now();
        if (limit == null) _fullEventsCacheReady = true;
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
    if (!AppPlatformApi.isEnabled && !_hasAuthenticatedUser) return [];
    final now = DateTime.now().millisecondsSinceEpoch;
    AppConfig.logger.d(
      "Retrieving upcoming events"
      "${limit != null ? ' (limit: $limit)' : ''}",
    );

    if (AppPlatformApi.isEnabled) {
      try {
        final res = await AppPlatformApi.client('events').read(
          'retrieveEvents',
          const <String, Object?>{},
          private: false,
        );
        final list = _parsePlatformItems(res);
        for (final ev in list) {
          _cachedEvents[ev.id] = ev;
        }
        _lastEventsFetchTime = DateTime.now();
        final upcoming = list
            .where((ev) => ev.isRecurring || ev.eventDate >= now)
            .toList()
          ..sort((a, b) => a.eventDate.compareTo(b.eventDate));
        return limit == null ? upcoming : upcoming.take(limit).toList();
      } catch (e, st) {
        NeomErrorLogger.recordError(
          e,
          st,
          module: 'neom_core',
          operation: 'EventFirestore.retrieveUpcomingEvents.platform',
        );
        return <Event>[];
      }
    }

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
    if (!AppPlatformApi.isEnabled && !_hasAuthenticatedUser) return null;
    if (slug.isEmpty) return null;
    if (AppPlatformApi.isEnabled) {
      try {
        final res = await AppPlatformApi.client('events').read(
          'getEvent',
          <String, Object?>{'eventId': slug},
          private: false,
        );
        final list = _parsePlatformItems(res);
        if (list.isNotEmpty) {
          final ev = list.first;
          _cachedEvents[ev.id] = ev;
          return ev;
        }
      } catch (e, st) {
        NeomErrorLogger.recordError(
          e,
          st,
          module: 'neom_core',
          operation: 'EventFirestore.getBySlug.platform',
        );
      }
      return null;
    }

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

      if (AppPlatformApi.isEnabled) {
        final payload = event.toJSON();
        if (eventId.isNotEmpty) {
          payload['id'] = eventId;
        }
        final res = await AppPlatformApi.client('events').mutate(
          'insert',
          <String, Object?>{'event': payload},
          durable: false,
        );
        final savedId = res is Map
            ? (res['value'] ?? res['id'] ?? eventId).toString()
            : (res ?? eventId).toString();
        event.id = savedId;
        invalidateCache();
        return savedId;
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
    if (AppPlatformApi.isEnabled) {
      try {
        await AppPlatformApi.client('events').mutate(
          'remove',
          <String, Object?>{'eventId': event.id},
          durable: false,
        );
        invalidateCache();
        return true;
      } catch (e, st) {
        NeomErrorLogger.recordError(
          e,
          st,
          module: 'neom_core',
          operation: 'EventFirestore.remove.platform',
        );
        return false;
      }
    }

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
    if (!AppPlatformApi.isEnabled && !_hasAuthenticatedUser) return {};
    if (!forceRefresh &&
        _fullEventsCacheReady &&
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
      return (AppPlatformApi.isEnabled || _hasAuthenticatedUser)
          ? Map<String, Event>.from(events)
          : <String, Event>{};
    }

    final fetch = _fetchEvents();
    if (!forceRefresh) _getEventsInFlight = fetch;

    try {
      final events = await fetch;
      return (AppPlatformApi.isEnabled || _hasAuthenticatedUser)
          ? Map<String, Event>.from(events)
          : <String, Event>{};
    } finally {
      if (identical(_getEventsInFlight, fetch)) {
        _getEventsInFlight = null;
      }
    }
  }

  Future<Map<String, Event>> _fetchEvents() async {
    if (AppPlatformApi.isEnabled) {
      final Map<String, Event> events = {};
      try {
        final res = await AppPlatformApi.client('events').read(
          'retrieveEvents',
          const <String, Object?>{},
          private: false,
        );
        final list = _parsePlatformItems(res);
        for (final ev in list) {
          events[ev.id] = ev;
          _cachedEvents[ev.id] = ev;
        }
        _lastEventsFetchTime = DateTime.now();
        _fullEventsCacheReady = true;
      } catch (e, st) {
        NeomErrorLogger.recordError(
          e,
          st,
          module: 'neom_core',
          operation: 'EventFirestore._fetchEvents.platform',
        );
      }
      return events;
    }

    AppConfig.logger.t("getEvents from Firestore");
    Map<String, Event> events = {};

    try {
      QuerySnapshot snapshot = await _eventsReference
          .orderBy(AppFirestoreConstants.createdTime, descending: true)
          .limit(_eventsListLimit)
          .get();
      if (!_hasAuthenticatedUser) return {};

      for (var documentSnapshot in snapshot.docs) {
        final data = documentSnapshot.data();
        if (data == null) continue;
        try {
          Event event = Event.fromJSON(data as Map<String, dynamic>);
          event.id = documentSnapshot.id;
          events[event.id] = event;
          _cachedEvents[event.id] = event;
        } catch (e, st) {
          NeomErrorLogger.recordError(
            e,
            st,
            module: 'neom_core',
            operation: 'EventFirestore.getEvents.parse:${documentSnapshot.id}',
          );
        }
      }

      _lastEventsFetchTime = DateTime.now();
      _fullEventsCacheReady = true;
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
    if (!AppPlatformApi.isEnabled && !_hasAuthenticatedUser) return {};
    if (eventIds.isEmpty) return {};
    if (AppPlatformApi.isEnabled) {
      final all = await getEvents();
      final Map<String, Event> matched = {};
      for (final id in eventIds) {
        if (all.containsKey(id)) {
          matched[id] = all[id]!;
        }
      }
      return matched;
    }

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

      if (AppPlatformApi.isEnabled) {
        final updated = <Map<String, dynamic>>[];
        bool replaced = false;
        for (final f in event.instrumentsFulfillment ?? <InstrumentFulfillment>[]) {
          if (!replaced &&
              f.id == previousInstrumentFulfillment.id &&
              f.instrument.name == appRequest.instrument!.name) {
            updated.add(instrumentFulfillment.toJSON());
            replaced = true;
          } else {
            updated.add(f.toJSON());
          }
        }
        if (!replaced) updated.add(instrumentFulfillment.toJSON());
        await AppPlatformApi.client('events').mutate(
          'setFulfillment',
          <String, Object?>{
            'eventId': event.id,
            'instrumentsFulfillment': updated,
          },
          durable: false,
        );
        _cachedEvents.remove(event.id);
        return true;
      }

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

      if (AppPlatformApi.isEnabled) {
        final updated = <Map<String, dynamic>>[];
        for (final f in event.instrumentsFulfillment ?? <InstrumentFulfillment>[]) {
          if (f.instrument.name == appRequest.instrument!.name &&
              (f.id == alreadyFulfilledInstrument.id || f.profileId == mate.id)) {
            updated.add(instrumentFulfillment.toJSON());
          } else {
            updated.add(f.toJSON());
          }
        }
        await AppPlatformApi.client('events').mutate(
          'setFulfillment',
          <String, Object?>{
            'eventId': event.id,
            'instrumentsFulfillment': updated,
          },
          durable: false,
        );
        _cachedEvents.remove(event.id);
        return true;
      }

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
    if (!AppPlatformApi.isEnabled && !_hasAuthenticatedUser) return [];
    AppConfig.logger.d("Retrieving PlayingEvents");

    if (AppPlatformApi.isEnabled) {
      final all = await retrieveEvents();
      return all.where((event) {
        if (event.ownerId == profileId) return true;
        for (final instr in event.instrumentsFulfillment ?? <InstrumentFulfillment>[]) {
          if (instr.profileId == profileId) return true;
        }
        return false;
      }).toList();
    }

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
      if (AppPlatformApi.isEnabled) {
        await AppPlatformApi.client('events').mutate(
          'setFulfillment',
          <String, Object?>{'eventId': eventId, 'isFulfilled': true},
          durable: false,
        );
        _cachedEvents.remove(eventId);
        return true;
      }

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
      if (AppPlatformApi.isEnabled) {
        await AppPlatformApi.client('events').mutate(
          'setFulfillment',
          <String, Object?>{'eventId': eventId, 'isFulfilled': false},
          durable: false,
        );
        _cachedEvents.remove(eventId);
        return true;
      }

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
      if (AppPlatformApi.isEnabled) {
        await AppPlatformApi.client('events').mutate(
          'addGoingProfile',
          <String, Object?>{
            'eventId': eventId,
            if (profileId.isNotEmpty) 'profileId': profileId,
          },
          durable: false,
        );
        _cachedEvents.remove(eventId);
        return true;
      }

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
      if (AppPlatformApi.isEnabled) {
        await AppPlatformApi.client('events').mutate(
          'leaveEvent',
          <String, Object?>{
            'eventId': eventId,
            if (profileId.isNotEmpty) 'profileId': profileId,
          },
          durable: false,
        );
        _cachedEvents.remove(eventId);
        return true;
      }

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
      if (AppPlatformApi.isEnabled) {
        await AppPlatformApi.client('events').mutate(
          'update',
          <String, Object?>{
            'eventId': event.id,
            'fields': event.toJSON(),
          },
          durable: false,
        );
        invalidateCache();
        return true;
      }

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
      if (AppPlatformApi.isEnabled) {
        await AppPlatformApi.client('events').mutate(
          'update',
          <String, Object?>{
            'eventId': eventId,
            'fields': fields,
          },
          durable: false,
        );
        invalidateCache();
        return true;
      }

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

      if (AppPlatformApi.isEnabled) {
        final updated = <Map<String, dynamic>>[];
        bool replaced = false;
        for (final f in event.collectivesFulfillment ?? <CollectiveFulfillment>[]) {
          if (f.collectiveId == collectiveId) {
            updated.add(collectiveFulfillment.toJSON());
            replaced = true;
          } else {
            updated.add(f.toJSON());
          }
        }
        if (!replaced) updated.add(collectiveFulfillment.toJSON());
        await AppPlatformApi.client('events').mutate(
          'setFulfillment',
          <String, Object?>{
            'eventId': event.id,
            'collectivesFulfillment': updated,
          },
          durable: false,
        );
        _cachedEvents.remove(event.id);
        return true;
      }

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
