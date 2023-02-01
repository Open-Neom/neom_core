import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/model/app_profile.dart';
import '../../domain/repository/mate_repository.dart';
import '../../utils/app_utilities.dart';
import '../../utils/enums/profile_type.dart';
import 'constants/app_firestore_collection_constants.dart';
import 'constants/app_firestore_constants.dart';
import 'facility_firestore.dart';
import 'genre_firestore.dart';
import 'instrument_firestore.dart';
import 'place_firestore.dart';

class MateFirestore implements MateRepository {

  var logger = AppUtilities.logger;
  final usersReference = FirebaseFirestore.instance.collection(AppFirestoreCollectionConstants.users);
  final profileReference = FirebaseFirestore.instance.collectionGroup(AppFirestoreCollectionConstants.profiles);

  @override
  Future<AppProfile>? getMateSimple(String mateId) async {
    logger.d("Retrieving Itemmate Simple $mateId");
    AppProfile mate = AppProfile();

    try {
      await profileReference.get().then((querySnapshot) async {
        for (var document in querySnapshot.docs) {
          if (document.id == mateId) {
            mate = AppProfile.fromJSON(document.data());
            mate.id = mateId;
          }
        }
      });

      logger.d("Itemmate ${mate.toString()}");
    } catch (e) {
      logger.e(e.toString());
    }

    return mate;
  }


  @override
  Future<bool> addMate(String profileId, String mateId) async {
    logger.d("$profileId would be itemmate with $mateId");

    try {

      await profileReference.get().then((querySnapshot) async {
        for (var document in querySnapshot.docs) {
          if (document.id == profileId) {
            await document.reference.update({
              AppFirestoreConstants.itemmates: FieldValue.arrayUnion(
                  [mateId])
            });
            logger.d("$profileId is now itemmate of $mateId");
          }

          if (document.id == mateId) {
            await document.reference.update({
              AppFirestoreConstants.itemmates: FieldValue.arrayUnion(
                  [profileId])
            });
            logger.d("$mateId is now itemmate of $profileId");
          }
        }
      });

      logger.d("$profileId and $mateId are itemmates now");
      return true;
    } catch (e) {
      logger.e(e.toString());
    }

    return false;
  }


  @override
  Future<bool> removeMate(String profileId, String mateId) async {
    logger.d("$profileId would not be itemmate with $mateId");

    try {
      await profileReference.get().then((querySnapshot) async {
        for (var document in querySnapshot.docs) {
          if (document.id == profileId) {
            await document.reference.update({
              AppFirestoreConstants.itemmates: FieldValue.arrayRemove(
                  [mateId])
            });
          }

          if (document.id == mateId) {
            await document.reference.update({
              AppFirestoreConstants.itemmates: FieldValue.arrayRemove(
                  [profileId])
            });
          }
        }
      });

      logger.d("$profileId and $mateId are not mates now");
      return true;
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

    try {
      QuerySnapshot querySnapshot = await profileReference.get();
      if (querySnapshot.docs.isNotEmpty) {
        logger.d("QuerySnapshot is not empty");
        for (var documentSnapshot in querySnapshot.docs) {
          if(mateIds.contains(documentSnapshot.id)){
            AppProfile mate = AppProfile.fromJSON(documentSnapshot.data());
            mate.id = documentSnapshot.id;
            logger.d("Mate ${mate.id} was retrieved");
            itemmates[mate.id] = mate;
          }
        }
      }
      logger.d("${itemmates.length} Mates found");
    } catch (e) {
      logger.e(e.toString());
    }

    return itemmates;
  }


  Future<AppProfile> getDetailedProfile(AppProfile profile) async {
    try {
      switch(profile.type) {
        case(ProfileType.instrumentist):
          profile.instruments = await InstrumentFirestore().retrieveInstruments(profile.id);
          break;
        case(ProfileType.facilitator):
          profile.facilities = await FacilityFirestore().retrieveFacilities(profile.id);
          break;
        case(ProfileType.host):
          profile.places = await PlaceFirestore().retrievePlaces(profile.id);
          break;
        case(ProfileType.fan):
          profile.genres = await GenreFirestore().retrieveGenres(profile.id);
          break;
        case(ProfileType.band):
          break;
      }
    } catch (e) {
      logger.e(e.toString());
    }

    return profile;
  }

}
