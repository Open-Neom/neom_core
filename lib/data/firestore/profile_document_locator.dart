import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../../app_config.dart';
import 'constants/app_firestore_collection_constants.dart';
import 'constants/app_firestore_constants.dart';

/// Resolves a profile id to its Firestore document reference.
///
/// Profiles live at `users/{userId}/profiles/{profileId}`, so a lookup that
/// only knows the profile id has to go through the `profiles` collection group.
/// Every profile document stores its own id (see `ProfileFirestore.insert`),
/// which makes an indexed `where('id')` query possible — without it the only
/// way to match by document id is to download the whole collection group, i.e.
/// one read per profile in the app on every call.
///
/// Resolved references are memoized for the process lifetime: a profile's
/// document path never changes, and these lookups sit in front of very chatty
/// operations (genres, instruments, frequencies, mates, places, facilities).
class ProfileDocumentLocator {

  // Lazy: the shared instance is only built when a repository first resolves a
  // profile, so importing this file does not require an initialized Firebase.
  static final ProfileDocumentLocator _instance =
      ProfileDocumentLocator._internal(FirebaseFirestore.instance);
  factory ProfileDocumentLocator() => _instance;
  ProfileDocumentLocator._internal(this._firestore);

  /// Standalone locator over an injected Firestore, for tests.
  @visibleForTesting
  factory ProfileDocumentLocator.forTesting(FirebaseFirestore firestore) =>
      ProfileDocumentLocator._internal(firestore);

  final FirebaseFirestore _firestore;
  final Map<String, DocumentReference> _cache = {};

  Query get _profileReference =>
      _firestore.collectionGroup(AppFirestoreCollectionConstants.profiles);

  /// How many profile ids currently have a memoized reference.
  @visibleForTesting
  int get cachedCount => _cache.length;

  /// The profile document for [profileId], or null when no profile matches.
  Future<DocumentReference?> locate(String profileId) async {
    if (profileId.isEmpty) return null;

    final cached = _cache[profileId];
    if (cached != null) return cached;

    try {
      final snapshot = await _profileReference
          .where(AppFirestoreConstants.id, isEqualTo: profileId)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        final reference = snapshot.docs.first.reference;
        _cache[profileId] = reference;
        return reference;
      }

      // Legacy fallback: profiles written before `id` was persisted can only be
      // matched by document id, which the collection group cannot query. This
      // costs one read per profile in the app, so it runs at most once per id —
      // the result is memoized either way.
      AppConfig.logger.w('Profile $profileId not found by id field, '
          'falling back to document id scan');
      final allProfiles = await _profileReference.get();
      for (final doc in allProfiles.docs) {
        if (doc.id == profileId) {
          _cache[profileId] = doc.reference;
          return doc.reference;
        }
      }

      AppConfig.logger.w('Profile $profileId not found');
    } catch (e, st) {
      AppConfig.logger.e('Error locating profile $profileId: $e\n$st');
    }

    return null;
  }

  /// The `profiles/{id}/{subcollection}` reference, or null if the profile is
  /// unknown.
  Future<CollectionReference?> subcollection(
      String profileId, String subcollection) async {
    final reference = await locate(profileId);
    return reference?.collection(subcollection);
  }

  /// Forgets a memoized reference (profile deleted or moved).
  void invalidate(String profileId) => _cache.remove(profileId);

  /// Forgets every memoized reference (sign-out).
  void clear() => _cache.clear();
}
