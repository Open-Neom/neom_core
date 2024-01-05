import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/model/place.dart';
import '../../domain/repository/place_repository.dart';
import '../../utils/app_utilities.dart';
import '../../utils/enums/place_type.dart';
import 'constants/app_firestore_collection_constants.dart';
import 'constants/app_firestore_constants.dart';

class PlaceFirestore implements PlaceRepository {

  var logger = AppUtilities.logger;
  final profileReference = FirebaseFirestore.instance.collectionGroup(AppFirestoreCollectionConstants.profiles);


  @override
  Future<Map<String,Place>> retrievePlaces(profileId) async {
    logger.d("Retrieving Place by Profile $profileId");

    Map<String, Place> places = {};

    try {
      QuerySnapshot querySnapshot = await profileReference.get();
      for (var document in querySnapshot.docs) {
        if(document.id == profileId) {
          QuerySnapshot qSnapshot = await document.reference
              .collection(AppFirestoreCollectionConstants.places).get();

          for (var queryDocumentSnapshot in qSnapshot.docs) {
            Place place = Place.fromJSON(queryDocumentSnapshot.data());
            place.id = queryDocumentSnapshot.id;
            places[place.name] = place;
          }
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
    logger.d("Removing $placeId for by $profileId");
    try {
      await profileReference.get()
          .then((querySnapshot) async {
        for (var document in querySnapshot.docs) {
          if (document.id == profileId) {
            await document.reference
                .collection(AppFirestoreCollectionConstants.places)
                .doc(placeId)
                .delete();
          }
        }
      });

    logger.d("Place $placeId removed");
    return true;
    } catch (e) {
      logger.e(e.toString());
      return false;
    }
  }

  @override
  Future<bool> addPlace({required String profileId, required PlaceType placeType}) async {
    logger.d("Adding $placeType for by $profileId");

    Place placeBasic = Place.addBasic(placeType);
    try {
      await profileReference.get()
          .then((querySnapshot) async {
        for (var document in querySnapshot.docs) {
          if (document.id == profileId) {
            await document.reference
                .collection(AppFirestoreCollectionConstants.places)
                .add(placeBasic.toJSON());
          }
        }
      });

      logger.d("Place $placeType added");
      return true;
    } catch (e) {
      logger.e(e.toString());
      return false;
    }
  }

  @override
  Future<bool> updateMainPlace({required String profileId,
      required String placeId, required String prevPlaceId}) async {

    logger.d("Updating $placeId as main for $profileId");

    try {
      await profileReference.get()
          .then((querySnapshot) async {
        for (var document in querySnapshot.docs) {
          if (document.id == profileId) {
            logger.i("Place $placeId as main place at places collection");
            await document.reference
                .collection(AppFirestoreCollectionConstants.places)
                .doc(placeId)
                .update({AppFirestoreConstants.isMain: true});

            logger.d("Place $placeId as main place at profile level");

            //TODO Add to model
            //document.reference.update({GigFirestoreConstants.mainPlace: placeId});

            if(prevPlaceId.isNotEmpty) {
              logger.d("Instrument $prevPlaceId unset from main instrument");
              await document.reference
                  .collection(AppFirestoreCollectionConstants.places)
                  .doc(prevPlaceId)
                  .update({AppFirestoreConstants.isMain: false});
            }
          }
        }
      });

      return true;
    } catch (e) {
      logger.e(e.toString());
      return false;
    }
  }
}
