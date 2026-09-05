import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fba;
import 'package:flutter_test/flutter_test.dart';
import 'package:neom_core/app_config.dart';
import 'package:neom_core/data/firestore/event_firestore.dart';
import 'package:neom_core/domain/model/app_user.dart';
import 'package:neom_core/domain/use_cases/login_service.dart';
import 'package:neom_core/domain/use_cases/user_service.dart';
import 'package:neom_core/utils/enums/auth_status.dart';
import 'package:sint/sint.dart';

class _FakeUserService extends Fake implements UserService {
  @override
  final AppUser user;

  _FakeUserService(this.user);
}

class _FakeFirebaseUser extends Fake implements fba.User {}

class _FakeLoginService extends Fake implements LoginService {
  @override
  AuthStatus getAuthStatus() => AuthStatus.loggedIn;

  @override
  fba.User? get fbaUser => _FakeFirebaseUser();
}

/// Tests for EventFirestore service
void main() {
  late FakeFirebaseFirestore fakeFirestore;
  late CollectionReference<Map<String, dynamic>> eventsRef;
  final appConfig = AppConfig.instance;

  setUp(() {
    Sint.reset();
    appConfig.isGuestMode = true;
    EventFirestore.invalidateCache();
    fakeFirestore = FakeFirebaseFirestore();
    eventsRef = fakeFirestore.collection('events');
  });

  tearDown(() {
    Sint.reset();
    appConfig.isGuestMode = true;
    EventFirestore.invalidateCache();
  });

  void authenticate() {
    appConfig.isGuestMode = false;
    Sint.put<LoginService>(_FakeLoginService());
    Sint.put<UserService>(_FakeUserService(AppUser(id: 'registered-user')));
  }

  Future<void> seedEvent(
    String id, {
    required String slug,
    required String ownerId,
    required bool isPublic,
    int createdTime = 10,
  }) => eventsRef.doc(id).set({
    'name': 'Event $id',
    'slug': slug,
    'ownerId': ownerId,
    'public': isPublic,
    'isTest': false,
    'status': 'scheduled',
    'createdTime': createdTime,
    'eventDate': DateTime.now()
        .add(const Duration(days: 1))
        .millisecondsSinceEpoch,
  });

  Future<void> expectEveryReadSurfaceClosed(EventFirestore repository) async {
    expect((await repository.retrieve('private_event')).id, isEmpty);
    expect((await repository.retrieve('public_event')).id, isEmpty);
    expect(await repository.retrieveEvents(), isEmpty);
    expect(
      await repository.retrieveEvents(forceRefresh: true, limit: 1),
      isEmpty,
    );
    expect(await repository.retrieveUpcomingEvents(limit: 1), isEmpty);
    expect(await repository.getBySlug('private-event'), isNull);
    expect(await repository.getBySlug('public-event'), isNull);
    expect(await repository.getEvents(), isEmpty);
    expect(await repository.getEvents(forceRefresh: true), isEmpty);
    expect(
      await repository.getEventsById(const ['private_event', 'public_event']),
      isEmpty,
    );
    expect(await repository.retrievePlayingEvents('profile_1'), isEmpty);
  }

  group('EventFirestore', () {
    group('guest read policy', () {
      setUp(() async {
        await seedEvent(
          'private_event',
          slug: 'private-event',
          ownerId: 'profile_1',
          isPublic: false,
        );
        await seedEvent(
          'public_event',
          slug: 'public-event',
          ownerId: 'profile_2',
          isPublic: true,
          createdTime: 20,
        );
      });

      test(
        'authenticated users can read a private event on every surface',
        () async {
          authenticate();
          final repository = EventFirestore(firestore: fakeFirestore);

          expect(
            (await repository.retrieve('private_event')).id,
            'private_event',
          );
          expect(
            (await repository.getBySlug('private-event'))?.id,
            'private_event',
          );
          expect(
            (await repository.retrieveEvents(
              forceRefresh: true,
            )).map((event) => event.id),
            contains('private_event'),
          );
          expect(
            (await repository.retrieveUpcomingEvents()).map(
              (event) => event.id,
            ),
            contains('private_event'),
          );
          expect(
            await repository.getEvents(forceRefresh: true),
            containsPair('private_event', isNotNull),
          );
          expect(
            await repository.getEventsById(const ['private_event']),
            containsPair('private_event', isNotNull),
          );
          expect(
            (await repository.retrievePlayingEvents(
              'profile_1',
            )).map((event) => event.id),
            contains('private_event'),
          );
        },
      );

      test(
        'guest cannot read public or private events, even from warm cache',
        () async {
          authenticate();
          final repository = EventFirestore(firestore: fakeFirestore);
          expect(
            await repository.getEvents(forceRefresh: true),
            containsPair('private_event', isNotNull),
          );

          appConfig.isGuestMode = true;

          await expectEveryReadSurfaceClosed(repository);
        },
      );

      test(
        'auth loss while reads are in flight cannot publish event data',
        () async {
          authenticate();
          final repository = EventFirestore(firestore: fakeFirestore);

          final byId = repository.retrieve('private_event');
          final all = repository.retrieveEvents(forceRefresh: true);
          final upcoming = repository.retrieveUpcomingEvents();
          final bySlug = repository.getBySlug('private-event');
          final eventMap = repository.getEvents(forceRefresh: true);
          final selected = repository.getEventsById(const ['private_event']);
          final playing = repository.retrievePlayingEvents('profile_1');

          appConfig.isGuestMode = true;

          expect((await byId).id, isEmpty);
          expect(await all, isEmpty);
          expect(await upcoming, isEmpty);
          expect(await bySlug, isNull);
          expect(await eventMap, isEmpty);
          expect(await selected, isEmpty);
          expect(await playing, isEmpty);
        },
      );

      test(
        'fails closed when guest mode ended without a valid session',
        () async {
          appConfig.isGuestMode = false;
          final repository = EventFirestore(firestore: fakeFirestore);

          await expectEveryReadSurfaceClosed(repository);
        },
      );
    });

    group('retrieve', () {
      test('should return event when exists', () async {
        // Setup
        await eventsRef.doc('event_1').set({
          'name': 'Test Event',
          'createdTime': FieldValue.serverTimestamp(),
          'isFulfilled': false,
        });

        // Act
        final doc = await eventsRef.doc('event_1').get();

        // Assert
        expect(doc.exists, isTrue);
        expect(doc.data(), isNotNull);
        final data = doc.data() as Map<String, dynamic>;
        expect(data['name'], equals('Test Event'));
        expect(data['isFulfilled'], isFalse);
      });

      test('should return empty when event does not exist', () async {
        final doc = await eventsRef.doc('non_existent').get();

        expect(doc.exists, isFalse);
        expect(doc.data(), isNull);
      });
    });

    group('fulfilled / unfulfilled', () {
      test('should update isFulfilled to true using direct update', () async {
        // Setup
        await eventsRef.doc('event_1').set({
          'name': 'Test Event',
          'isFulfilled': false,
        });

        // Act - Using optimized direct update
        await eventsRef.doc('event_1').update({'isFulfilled': true});

        // Assert
        final doc = await eventsRef.doc('event_1').get();
        final data = doc.data() as Map<String, dynamic>;
        expect(data['isFulfilled'], isTrue);
      });

      test('should update isFulfilled to false using direct update', () async {
        // Setup
        await eventsRef.doc('event_1').set({
          'name': 'Test Event',
          'isFulfilled': true,
        });

        // Act
        await eventsRef.doc('event_1').update({'isFulfilled': false});

        // Assert
        final doc = await eventsRef.doc('event_1').get();
        final data = doc.data() as Map<String, dynamic>;
        expect(data['isFulfilled'], isFalse);
      });
    });

    group('addGoingProfile / removeGoingProfile', () {
      test('should add profile to goingProfiles array', () async {
        // Setup
        await eventsRef.doc('event_1').set({
          'name': 'Test Event',
          'goingProfiles': ['profile_1'],
        });

        // Act - Using optimized direct update
        await eventsRef.doc('event_1').update({
          'goingProfiles': FieldValue.arrayUnion(['profile_2']),
        });

        // Assert
        final doc = await eventsRef.doc('event_1').get();
        final data = doc.data() as Map<String, dynamic>;
        expect(data['goingProfiles'], contains('profile_1'));
        expect(data['goingProfiles'], contains('profile_2'));
      });

      test('should remove profile from goingProfiles array', () async {
        // Setup
        await eventsRef.doc('event_1').set({
          'name': 'Test Event',
          'goingProfiles': ['profile_1', 'profile_2'],
        });

        // Act
        await eventsRef.doc('event_1').update({
          'goingProfiles': FieldValue.arrayRemove(['profile_1']),
        });

        // Assert
        final doc = await eventsRef.doc('event_1').get();
        final data = doc.data() as Map<String, dynamic>;
        expect(data['goingProfiles'], isNot(contains('profile_1')));
        expect(data['goingProfiles'], contains('profile_2'));
      });
    });

    group('instrumentsFulfillment', () {
      test('should update instrumentsFulfillment array correctly', () async {
        // Setup
        final oldFulfillment = {
          'id': 'pos_1',
          'instrument': {'name': 'Guitar'},
          'profileId': '',
          'isFulfilled': false,
        };

        await eventsRef.doc('event_1').set({
          'name': 'Test Event',
          'instrumentsFulfillment': [oldFulfillment],
        });

        // Act - Remove old and add new (as our optimized code does)
        await eventsRef.doc('event_1').update({
          'instrumentsFulfillment': FieldValue.arrayRemove([oldFulfillment]),
        });

        final newFulfillment = {
          'id': 'pos_1',
          'instrument': {'name': 'Guitar'},
          'profileId': 'profile_123',
          'isFulfilled': true,
        };

        await eventsRef.doc('event_1').update({
          'instrumentsFulfillment': FieldValue.arrayUnion([newFulfillment]),
        });

        // Assert
        final doc = await eventsRef.doc('event_1').get();
        final data = doc.data() as Map<String, dynamic>;
        final fulfillments = data['instrumentsFulfillment'] as List;
        expect(fulfillments.length, equals(1));
        expect(fulfillments.first['isFulfilled'], isTrue);
        expect(fulfillments.first['profileId'], equals('profile_123'));
      });
    });

    group('retrieveEvents with ordering', () {
      test(
        'should retrieve events ordered by createdTime descending',
        () async {
          // Setup - Add events with different timestamps
          await eventsRef.doc('event_1').set({
            'name': 'Old Event',
            'createdTime': Timestamp.fromDate(DateTime(2024, 1, 1)),
          });

          await eventsRef.doc('event_2').set({
            'name': 'New Event',
            'createdTime': Timestamp.fromDate(DateTime(2024, 6, 1)),
          });

          await eventsRef.doc('event_3').set({
            'name': 'Middle Event',
            'createdTime': Timestamp.fromDate(DateTime(2024, 3, 1)),
          });

          // Act
          final query = await eventsRef
              .orderBy('createdTime', descending: true)
              .get();

          // Assert
          expect(query.docs.length, equals(3));
          expect((query.docs[0].data() as Map)['name'], equals('New Event'));
          expect((query.docs[1].data() as Map)['name'], equals('Middle Event'));
          expect((query.docs[2].data() as Map)['name'], equals('Old Event'));
        },
      );
    });
  });

  group('Null Safety', () {
    test('should handle document.data() null check pattern', () async {
      final doc = await eventsRef.doc('non_existent').get();

      // Pattern used in our optimized code
      if (doc.exists && doc.data() != null) {
        fail('Should not reach here for non-existent document');
      }

      expect(doc.exists, isFalse);
    });

    test('should safely cast data to Map<String, dynamic>', () async {
      await eventsRef.doc('event_1').set({'name': 'Test Event', 'count': 42});

      final doc = await eventsRef.doc('event_1').get();

      if (doc.exists && doc.data() != null) {
        final data = doc.data() as Map<String, dynamic>;
        expect(data['name'], equals('Test Event'));
        expect(data['count'], equals(42));
      }
    });

    /// `retrieveEvents` used to read the whole collection on every timeline
    /// load. These pin the bounded, newest-first contract the limit relies on.
    group('bounded retrieveEvents query', () {
      Future<void> seed(int count) async {
        for (int i = 0; i < count; i++) {
          await eventsRef.doc('event_$i').set({
            'name': 'Event $i',
            'createdTime': i,
            'isFulfilled': false,
          });
        }
      }

      test('a limited query reads only that many documents', () async {
        await seed(50);

        final snapshot = await eventsRef
            .orderBy('createdTime', descending: true)
            .limit(20)
            .get();

        expect(snapshot.docs.length, 20);
      });

      test('the limit takes the newest events, not arbitrary ones', () async {
        await seed(50);

        final snapshot = await eventsRef
            .orderBy('createdTime', descending: true)
            .limit(3)
            .get();

        expect(snapshot.docs.map((d) => d.id), [
          'event_49',
          'event_48',
          'event_47',
        ]);
      });

      test('a limit larger than the collection returns everything', () async {
        await seed(5);

        final snapshot = await eventsRef
            .orderBy('createdTime', descending: true)
            .limit(20)
            .get();

        expect(snapshot.docs.length, 5);
      });

      test('an unlimited query still returns the whole collection', () async {
        await seed(30);

        final snapshot = await eventsRef
            .orderBy('createdTime', descending: true)
            .get();

        expect(snapshot.docs.length, 30);
      });
    });
  });
}
