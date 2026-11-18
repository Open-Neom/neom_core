import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../app_config.dart';
import '../../domain/model/app_profile.dart';
import '../../domain/repository/mate_repository.dart';
import '../../utils/enums/profile_type.dart';
import 'constants/app_firestore_collection_constants.dart';
import 'constants/app_firestore_constants.dart';
import 'core_firestore_guard.dart';
import 'profile_document_locator.dart';
import 'facility_firestore.dart';
import 'genre_firestore.dart';
import 'instrument_firestore.dart';
import 'place_firestore.dart';

class MateFirestore implements MateRepository {

  var logger = AppConfig.logger;
  CollectionReference<Map<String, dynamic>> get usersReference =>
      FirebaseFirestore.instance.collection(AppFirestoreCollectionConstants.users);
  Query<Map<String, dynamic>> get profileReference =>
      FirebaseFirestore.instance.collectionGroup(AppFirestoreCollectionConstants.profiles);
  final _profileLocator = ProfileDocumentLocator();

  /// Profile document for [profileId]. Delegates to the shared locator so the
  /// indexed lookup and its memoization are not duplicated per repository.
  Future<DocumentReference?> _getProfileDocumentReference(String profileId) =>
      _profileLocator.locate(profileId);

  /// OPTIMIZED: Helper to update a profile field
  Future<bool> _updateProfileField(String profileId, Map<String, dynamic> data) async {
    final cleanId = profileId.trim();
    if (!CoreFirestoreGuard.isSafeDocId(cleanId)) return false;
    try {
      final docRef = await _getProfileDocumentReference(cleanId);
      if (docRef != null) {
        await docRef.update(data);
        return true;
      }
      logger.w('Profile $cleanId not found for update');
    } catch (e) {
      logger.e('Error updating profile: $e');
    }
    return false;
  }

  @override
  Future<AppProfile>? getMateSimple(String mateId) async {
    logger.d("Retrieving Itemmate Simple $mateId");
    AppProfile mate = AppProfile();

    final cleanMateId = mateId.trim();
    if (!CoreFirestoreGuard.isSafeDocId(cleanMateId)) {
      logger.w('Cannot get mate: mateId is invalid');
      return mate;
    }

    try {
      // First try: Query by 'id' field
      final querySnapshot = await profileReference
          .where('id', isEqualTo: cleanMateId)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        final document = querySnapshot.docs.first;
        mate = AppProfile.fromJSON(document.data());
        mate.id = document.id;
      } else {
        // Legacy profiles without an `id` field: the shared locator owns that
        // scan and memoizes the result, so it is not repeated per mate.
        final reference = await _profileLocator.locate(cleanMateId);
        if (reference != null) {
          final document = await reference.get();
          final data = document.data();
          if (data != null) {
            mate = AppProfile.fromJSON(data as Map<String, dynamic>);
            mate.id = document.id;
          }
        }
      }

      logger.t("Itemmate ${mate.toString()}");
    } catch (e) {
      logger.e(e.toString());
    }

    return mate;
  }


  @override
  Future<bool> addMate(String profileId, String mateId) async {
    final cleanProfileId = profileId.trim();
    final cleanMateId = mateId.trim();
    if (!CoreFirestoreGuard.isSafeDocId(cleanProfileId) ||
        !CoreFirestoreGuard.isSafeDocId(cleanMateId) ||
        cleanProfileId == cleanMateId) {
      return false;
    }
    logger.d("$cleanProfileId would be itemmate with $cleanMateId");

    try {
      // OPTIMIZED: Update both profiles in parallel using targeted queries
      final results = await Future.wait([
        _updateProfileField(cleanProfileId, {
          AppFirestoreConstants.itemmates: FieldValue.arrayUnion([cleanMateId])
        }),
        _updateProfileField(cleanMateId, {
          AppFirestoreConstants.itemmates: FieldValue.arrayUnion([cleanProfileId])
        }),
      ]);

      if (results.every((success) => success)) {
        logger.d("$cleanProfileId and $cleanMateId are itemmates now");
        return true;
      }
    } catch (e) {
      logger.e(e.toString());
    }

    return false;
  }


  @override
  Future<bool> removeMate(String profileId, String mateId) async {
    final cleanProfileId = profileId.trim();
    final cleanMateId = mateId.trim();
    if (!CoreFirestoreGuard.isSafeDocId(cleanProfileId) ||
        !CoreFirestoreGuard.isSafeDocId(cleanMateId)) {
      return false;
    }
    logger.d("$cleanProfileId would not be itemmate with $cleanMateId");

    try {
      // OPTIMIZED: Update both profiles in parallel using targeted queries
      final results = await Future.wait([
        _updateProfileField(cleanProfileId, {
          AppFirestoreConstants.itemmates: FieldValue.arrayRemove([cleanMateId])
        }),
        _updateProfileField(cleanMateId, {
          AppFirestoreConstants.itemmates: FieldValue.arrayRemove([cleanProfileId])
        }),
      ]);

      if (results.every((success) => success)) {
        logger.d("$cleanProfileId and $cleanMateId are not mates now");
        return true;
      }
    } catch (e) {
      logger.e(e.toString());
    }

    return false;
  }

  @override
  void sendMateRequest(){

  }


  @override
  Future<Map<String, AppProfile>> getMatesFromList(List<String> mateIds) async {
    logger.d("Entering method getMates from List");

    Map<String, AppProfile> itemmates = {};
    if(mateIds.isEmpty) return itemmates;

    final chunks = CoreFirestoreGuard.chunkValidIds(mateIds);
    if (chunks.isEmpty) return itemmates;

    try {
      // OPTIMIZED: Query by 'id' field using whereIn
      // (collectionGroup queries don't support FieldPath.documentId with simple IDs)
      for (final batch in chunks) {
        final querySnapshot = await profileReference
            .where('id', whereIn: batch)
            .get();

        for (var documentSnapshot in querySnapshot.docs) {
          AppProfile mate = AppProfile.fromJSON(documentSnapshot.data());
          mate.id = documentSnapshot.id;
          logger.t("Mate ${mate.id} was retrieved");
          itemmates[mate.id] = mate;
        }
      }
      logger.t("${itemmates.length} Mates found");
    } catch (e) {
      logger.e(e.toString());
    }

    return itemmates;
  }


  Future<AppProfile> getDetailedProfile(AppProfile profile) async {
    try {
      switch(profile.type) {
        case(ProfileType.appArtist):
          profile.instruments = await InstrumentFirestore().retrieveInstruments(profile.id);
          break;
        case(ProfileType.facilitator):
          profile.facilities = await FacilityFirestore().retrieveFacilities(profile.id);
          break;
        case(ProfileType.host):
          profile.places = await PlaceFirestore().retrievePlaces(profile.id);
          break;
        case(ProfileType.general):
          profile.genres = await GenreFirestore().retrieveGenres(profile.id);
          break;
        default:
          break;
      }
    } catch (e) {
      logger.e(e.toString());
    }

    return profile;
  }

}
