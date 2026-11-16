import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../app_config.dart';
import '../../domain/model/place.dart';
import '../../domain/repository/place_repository.dart';
import '../../utils/enums/place_type.dart';
import 'constants/app_firestore_collection_constants.dart';
import 'constants/app_firestore_constants.dart';
import 'core_firestore_guard.dart';
import 'profile_document_locator.dart';

class PlaceFirestore implements PlaceRepository {

  final logger = AppConfig.logger;
  Query<Map<String, dynamic>> get profileReference =>
      FirebaseFirestore.instance.collectionGroup(AppFirestoreCollectionConstants.profiles);
  final _profileLocator = ProfileDocumentLocator();

  /// Profile document for [profileId]. Delegates to the shared locator so the
  /// indexed lookup and its memoization are not duplicated per repository.
  Future<DocumentReference?> _getProfileDocumentReference(String profileId) {
    final cleanId = profileId.trim();
    if (!CoreFirestoreGuard.isSafeDocId(cleanId)) {
      return Future<DocumentReference?>.value(null);
    }
    return _profileLocator.locate(cleanId);
  }

  @override
  Future<Map<String,Place>> retrievePlaces(profileId) async {
    logger.d("Retrieving Place by Profile $profileId");

    Map<String, Place> places = {};

    try {
      // OPTIMIZED: Query only the specific profile instead of all profiles
      final docRef = await _getProfileDocumentReference(profileId);
      if (docRef != null) {
        final qSnapshot = await docRef
            .collection(AppFirestoreCollectionConstants.places)
            .get();

        for (var queryDocumentSnapshot in qSnapshot.docs) {
          Place place = Place.fromJSON(queryDocumentSnapshot.data());
          place.id = queryDocumentSnapshot.id;
          places[place.name] = place;
        }
      }
    } catch (e) {
      logger.t("No Places found");
    }

    logger.t("${places.length} Places found");
    return places;
  }

  @override
  Future<bool> removePlace({required String profileId, required String placeId}) async {
    final cleanPlaceId = placeId.trim();
    if (!CoreFirestoreGuard.isSafeDocId(cleanPlaceId)) return false;
    logger.d("Removing $cleanPlaceId for by $profileId");
    try {
      // OPTIMIZED: Query only the specific profile
      final docRef = await _getProfileDocumentReference(profileId);
      if (docRef != null) {
        await docRef
            .collection(AppFirestoreCollectionConstants.places)
            .doc(cleanPlaceId)
            .delete();
        logger.d("Place $cleanPlaceId removed");
        return true;
      }
    } catch (e) {
      logger.e(e.toString());
    }
    return false;
  }

  @override
  Future<bool> addPlace({required String profileId, required PlaceType placeType}) async {
    logger.d("Adding $placeType for by $profileId");

    Place placeBasic = Place.addBasic(placeType);
    try {
      // OPTIMIZED: Query only the specific profile
      final docRef = await _getProfileDocumentReference(profileId);
      if (docRef != null) {
        await docRef
            .collection(AppFirestoreCollectionConstants.places)
            .add(placeBasic.toJSON());
        logger.d("Place $placeType added");
        return true;
      }
    } catch (e) {
      logger.e(e.toString());
    }
    return false;
  }

  @override
  Future<bool> updateMainPlace({required String profileId,
      required String placeId, required String prevPlaceId}) async {
    final cleanPlaceId = placeId.trim();
    if (!CoreFirestoreGuard.isSafeDocId(cleanPlaceId)) return false;

    logger.d("Updating $cleanPlaceId as main for $profileId");

    try {
      // OPTIMIZED: Query only the specific profile
      final docRef = await _getProfileDocumentReference(profileId);
      if (docRef != null) {
        logger.i("Place $cleanPlaceId as main place at places collection");
        await docRef
            .collection(AppFirestoreCollectionConstants.places)
            .doc(cleanPlaceId)
            .update({AppFirestoreConstants.isMain: true});

        logger.d("Place $cleanPlaceId as main place at profile level");

        final cleanPrevId = prevPlaceId.trim();
        if (CoreFirestoreGuard.isSafeDocId(cleanPrevId) &&
            cleanPrevId != cleanPlaceId) {
          logger.d("Place $cleanPrevId unset from main place");
          await docRef
              .collection(AppFirestoreCollectionConstants.places)
              .doc(cleanPrevId)
              .update({AppFirestoreConstants.isMain: false});
        }
        return true;
      }
    } catch (e) {
      logger.e(e.toString());
    }
    return false;
  }
}
