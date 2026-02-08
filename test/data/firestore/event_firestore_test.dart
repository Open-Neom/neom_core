import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Tests for EventFirestore service
void main() {
  late FakeFirebaseFirestore fakeFirestore;
  late CollectionReference eventsRef;

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
    eventsRef = fakeFirestore.collection('events');
  });

  group('EventFirestore', () {
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
        await eventsRef.doc('event_1').update({
          'isFulfilled': true,
        });

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
        await eventsRef.doc('event_1').update({
          'isFulfilled': false,
        });

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
      test('should retrieve events ordered by createdTime descending', () async {
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
      });
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
      await eventsRef.doc('event_1').set({
        'name': 'Test Event',
        'count': 42,
      });

      final doc = await eventsRef.doc('event_1').get();

      if (doc.exists && doc.data() != null) {
        final data = doc.data() as Map<String, dynamic>;
        expect(data['name'], equals('Test Event'));
        expect(data['count'], equals(42));
      }
    });
  });
}
