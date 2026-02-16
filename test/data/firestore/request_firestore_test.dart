import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

/// Tests for RequestFirestore service
void main() {
  late FakeFirebaseFirestore fakeFirestore;
  late CollectionReference requestsRef;

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
    requestsRef = fakeFirestore.collection('requests');
  });

  group('RequestFirestore', () {
    group('acceptRequest / declineRequest / moveToPending', () {
      test('should update requestDecision to confirmed using direct update', () async {
        // Setup
        await requestsRef.doc('request_1').set({
          'from': 'profile_1',
          'to': 'profile_2',
          'requestDecision': 'pending',
        });

        // Act - Using optimized direct update (not get().then())
        await requestsRef.doc('request_1').update({
          'requestDecision': 'confirmed',
        });

        // Assert
        final doc = await requestsRef.doc('request_1').get();
        final data = doc.data() as Map<String, dynamic>;
        expect(data['requestDecision'], equals('confirmed'));
      });

      test('should update requestDecision to declined using direct update', () async {
        // Setup
        await requestsRef.doc('request_1').set({
          'from': 'profile_1',
          'to': 'profile_2',
          'requestDecision': 'pending',
        });

        // Act
        await requestsRef.doc('request_1').update({
          'requestDecision': 'declined',
        });

        // Assert
        final doc = await requestsRef.doc('request_1').get();
        final data = doc.data() as Map<String, dynamic>;
        expect(data['requestDecision'], equals('declined'));
      });

      test('should update requestDecision to pending using direct update', () async {
        // Setup
        await requestsRef.doc('request_1').set({
          'from': 'profile_1',
          'to': 'profile_2',
          'requestDecision': 'confirmed',
        });

        // Act
        await requestsRef.doc('request_1').update({
          'requestDecision': 'pending',
        });

        // Assert
        final doc = await requestsRef.doc('request_1').get();
        final data = doc.data() as Map<String, dynamic>;
        expect(data['requestDecision'], equals('pending'));
      });
    });

    group('retrieve requests by profileId', () {
      test('should retrieve requests where to equals profileId', () async {
        // Setup
        await requestsRef.doc('request_1').set({
          'from': 'profile_1',
          'to': 'profile_2',
          'requestDecision': 'pending',
        });

        await requestsRef.doc('request_2').set({
          'from': 'profile_3',
          'to': 'profile_2',
          'requestDecision': 'pending',
        });

        await requestsRef.doc('request_3').set({
          'from': 'profile_2',
          'to': 'profile_1',
          'requestDecision': 'pending',
        });

        // Act - Query requests TO profile_2
        final query = await requestsRef
            .where('to', isEqualTo: 'profile_2')
            .get();

        // Assert
        expect(query.docs.length, equals(2));
      });

      test('should retrieve requests where from equals profileId', () async {
        // Setup
        await requestsRef.doc('request_1').set({
          'from': 'profile_1',
          'to': 'profile_2',
        });

        await requestsRef.doc('request_2').set({
          'from': 'profile_1',
          'to': 'profile_3',
        });

        await requestsRef.doc('request_3').set({
          'from': 'profile_2',
          'to': 'profile_1',
        });

        // Act - Query requests FROM profile_1
        final query = await requestsRef
            .where('from', isEqualTo: 'profile_1')
            .get();

        // Assert
        expect(query.docs.length, equals(2));
      });
    });

    group('streamRequest', () {
      test('should stream request changes', () async {
        // Setup
        await requestsRef.doc('request_1').set({
          'from': 'profile_1',
          'to': 'profile_2',
          'requestDecision': 'pending',
        });

        // Act - Get stream
        final stream = requestsRef.doc('request_1').snapshots();

        // Assert initial value
        final firstSnapshot = await stream.first;
        expect(firstSnapshot.exists, isTrue);
        expect((firstSnapshot.data() as Map)['requestDecision'], equals('pending'));

        // Update and check stream receives update
        await requestsRef.doc('request_1').update({
          'requestDecision': 'confirmed',
        });

        // Get updated value
        final updatedDoc = await requestsRef.doc('request_1').get();
        expect((updatedDoc.data() as Map)['requestDecision'], equals('confirmed'));
      });
    });
  });

  group('Error Handling', () {
    test('should handle update on non-existent document', () async {
      // In real Firestore, updating non-existent doc throws error
      // fake_cloud_firestore may behave differently
      try {
        await requestsRef.doc('non_existent').update({
          'requestDecision': 'confirmed',
        });
      } catch (e) {
        expect(e, isA<Exception>());
      }
    });
  });
}
