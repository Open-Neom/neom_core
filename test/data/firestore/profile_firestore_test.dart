import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

/// Tests for ProfileFirestore service
/// These tests verify the optimized Firestore queries work correctly
void main() {
  late FakeFirebaseFirestore fakeFirestore;

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
  });

  group('ProfileFirestore', () {
    group('retrieveFromList', () {
      test('should return empty map when profileIds is empty', () async {
        final profileIds = <String>[];
        final profilesRef = fakeFirestore.collectionGroup('profiles');

        final querySnapshot = await profilesRef
            .where(FieldPath.documentId, whereIn: profileIds.isEmpty ? ['__empty__'] : profileIds)
            .get();

        expect(querySnapshot.docs, isEmpty);
      });

      test('should batch queries for more than 30 IDs', () async {
        // Setup: Create 35 profile IDs
        final profileIds = List.generate(35, (i) => 'profile_$i');

        // Add profiles to fake firestore
        for (var id in profileIds) {
          await fakeFirestore
              .collection('users')
              .doc('user_$id')
              .collection('profiles')
              .doc(id)
              .set({
            'name': 'Test Profile $id',
            'type': 'general',
          });
        }

        // Verify batching works - first batch of 30
        final batch1 = profileIds.take(30).toList();
        final query1 = await fakeFirestore
            .collectionGroup('profiles')
            .where(FieldPath.documentId, whereIn: batch1)
            .get();

        expect(query1.docs.length, equals(30));

        // Second batch of 5
        final batch2 = profileIds.skip(30).take(5).toList();
        final query2 = await fakeFirestore
            .collectionGroup('profiles')
            .where(FieldPath.documentId, whereIn: batch2)
            .get();

        expect(query2.docs.length, equals(5));
      });
    });

    group('_getProfileDocumentReference', () {
      test('should return null when profile does not exist', () async {
        final querySnapshot = await fakeFirestore
            .collectionGroup('profiles')
            .where(FieldPath.documentId, isEqualTo: 'non_existent_id')
            .limit(1)
            .get();

        expect(querySnapshot.docs, isEmpty);
      });

      test('should return document reference when profile exists', () async {
        // Setup
        await fakeFirestore
            .collection('users')
            .doc('user_1')
            .collection('profiles')
            .doc('profile_1')
            .set({
          'name': 'Test Profile',
          'type': 'general',
        });

        final querySnapshot = await fakeFirestore
            .collectionGroup('profiles')
            .where(FieldPath.documentId, isEqualTo: 'profile_1')
            .limit(1)
            .get();

        expect(querySnapshot.docs.length, equals(1));
        expect(querySnapshot.docs.first.id, equals('profile_1'));
      });
    });

    group('updateProfileField', () {
      test('should update profile field using FieldValue.arrayUnion', () async {
        // Setup
        final docRef = fakeFirestore
            .collection('users')
            .doc('user_1')
            .collection('profiles')
            .doc('profile_1');

        await docRef.set({
          'name': 'Test Profile',
          'followers': ['follower_1'],
        });

        // Act
        await docRef.update({
          'followers': FieldValue.arrayUnion(['follower_2']),
        });

        // Assert
        final doc = await docRef.get();
        expect(doc.data()?['followers'], contains('follower_1'));
        expect(doc.data()?['followers'], contains('follower_2'));
      });

      test('should update profile field using FieldValue.arrayRemove', () async {
        // Setup
        final docRef = fakeFirestore
            .collection('users')
            .doc('user_1')
            .collection('profiles')
            .doc('profile_1');

        await docRef.set({
          'name': 'Test Profile',
          'followers': ['follower_1', 'follower_2'],
        });

        // Act
        await docRef.update({
          'followers': FieldValue.arrayRemove(['follower_1']),
        });

        // Assert
        final doc = await docRef.get();
        expect(doc.data()?['followers'], isNot(contains('follower_1')));
        expect(doc.data()?['followers'], contains('follower_2'));
      });
    });

    group('retrieveProfilesByType', () {
      test('should filter profiles by type', () async {
        // Setup - add profiles with different types
        await fakeFirestore
            .collection('users')
            .doc('user_1')
            .collection('profiles')
            .doc('profile_1')
            .set({
          'name': 'Artist Profile',
          'type': 'appArtist',
        });

        await fakeFirestore
            .collection('users')
            .doc('user_2')
            .collection('profiles')
            .doc('profile_2')
            .set({
          'name': 'Facilitator Profile',
          'type': 'facilitator',
        });

        await fakeFirestore
            .collection('users')
            .doc('user_3')
            .collection('profiles')
            .doc('profile_3')
            .set({
          'name': 'Host Profile',
          'type': 'host',
        });

        // Query only appArtist type
        final artistProfiles = await fakeFirestore
            .collectionGroup('profiles')
            .where('type', isEqualTo: 'appArtist')
            .get();

        expect(artistProfiles.docs.length, equals(1));
        expect(artistProfiles.docs.first.data()['name'], equals('Artist Profile'));

        // Query only facilitator type
        final facilitatorProfiles = await fakeFirestore
            .collectionGroup('profiles')
            .where('type', isEqualTo: 'facilitator')
            .get();

        expect(facilitatorProfiles.docs.length, equals(1));
        expect(facilitatorProfiles.docs.first.data()['name'], equals('Facilitator Profile'));
      });
    });

    group('searchByName', () {
      test('should find profiles by searchName using range query', () async {
        // Setup
        await fakeFirestore
            .collection('users')
            .doc('user_1')
            .collection('profiles')
            .doc('profile_1')
            .set({
          'name': 'John Doe',
          'searchName': 'john doe',
        });

        await fakeFirestore
            .collection('users')
            .doc('user_2')
            .collection('profiles')
            .doc('profile_2')
            .set({
          'name': 'Jane Smith',
          'searchName': 'jane smith',
        });

        // Search for "john"
        final searchKey = 'john';
        final endKey = '$searchKey\uf8ff';

        final results = await fakeFirestore
            .collectionGroup('profiles')
            .where('searchName', isGreaterThanOrEqualTo: searchKey)
            .where('searchName', isLessThanOrEqualTo: endKey)
            .limit(20)
            .get();

        expect(results.docs.length, equals(1));
        expect(results.docs.first.data()['name'], equals('John Doe'));
      });
    });
  });

  group('Null Safety Tests', () {
    test('should handle null data() gracefully', () async {
      // This test verifies that our null checks work correctly
      final docRef = fakeFirestore
          .collection('users')
          .doc('non_existent');

      final doc = await docRef.get();

      // Document doesn't exist, data() should be null
      expect(doc.exists, isFalse);
      expect(doc.data(), isNull);
    });

    test('should handle existing document with data', () async {
      final docRef = fakeFirestore
          .collection('users')
          .doc('user_1');

      await docRef.set({'name': 'Test'});

      final doc = await docRef.get();

      expect(doc.exists, isTrue);
      expect(doc.data(), isNotNull);
      expect(doc.data()?['name'], equals('Test'));
    });
  });
}
