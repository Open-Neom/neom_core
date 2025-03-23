import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/model/facility.dart';
import '../../domain/repository/facility_repository.dart';
import '../../utils/app_utilities.dart';
import '../../utils/enums/facilitator_type.dart';
import 'constants/app_firestore_collection_constants.dart';
import 'constants/app_firestore_constants.dart';

class FacilityFirestore implements FacilityRepository {
  
  final profileReference = FirebaseFirestore.instance.collectionGroup(AppFirestoreCollectionConstants.profiles);

  @override
  Future<Map<String,Facility>> retrieveFacilities(profileId) async {
    AppUtilities.logger.d("Retrieving Facility by Profile $profileId");

    Map<String, Facility> facilities = {};

    try {

      QuerySnapshot querySnapshot = await profileReference.get();
      for (var document in querySnapshot.docs) {
        if(document.id == profileId) {
          QuerySnapshot qSnapshot = await document.reference
              .collection(AppFirestoreCollectionConstants.facilities).get();

          for (var queryDocumentSnapshot in qSnapshot.docs) {
            Facility facility = Facility.fromQueryDocumentSnapshot(queryDocumentSnapshot: queryDocumentSnapshot);
            facilities[facility.name] = facility;
          }
        }
      }
    } catch (e) {
      AppUtilities.logger.e("No facilities found");
    }

    AppUtilities.logger.d("${facilities.length} facilities found");
    return facilities;
  }

  @override
  Future<bool> removeFacility({required String profileId, required String facilityId}) async {
    AppUtilities.logger.d("Removing $facilityId for by $profileId");
    try {
      await profileReference.get()
          .then((querySnapshot) async {
        for (var document in querySnapshot.docs) {
          if (document.id == profileId) {
            await document.reference
                .collection(AppFirestoreCollectionConstants.facilities)
                .doc(facilityId)
                .delete();
          }
        }
      });

    AppUtilities.logger.d("Facility $facilityId removed");
    return true;
    } catch (e) {
      AppUtilities.logger.e(e.toString());
      return false;
    }
  }

  @override
  Future<bool> addFacility({required String profileId, required FacilityType facilityType}) async {
    AppUtilities.logger.d("Adding $facilityType for by $profileId");

    Facility facilityBasic = Facility.addBasic(facilityType);
    try {
      await profileReference.get()
          .then((querySnapshot) async {
        for (var document in querySnapshot.docs) {
          if (document.id == profileId) {
            await document.reference
                .collection(AppFirestoreCollectionConstants.facilities)
                .add(facilityBasic.toJSON());
          }
        }
      });

      AppUtilities.logger.d("Facility $facilityType added");
      return true;
    } catch (e) {
      AppUtilities.logger.e(e.toString());
      return false;
    }
  }

  @override
  Future<bool> updateMainFacility({required String profileId,
      required String facilityId, required String prevFacilityId}) async {

    AppUtilities.logger.d("Updating $facilityId as main for $profileId");

    try {
      await profileReference.get()
          .then((querySnapshot) {
        for (var document in querySnapshot.docs) {
          if (document.id == profileId) {
            AppUtilities.logger.i("Facility $facilityId as main facility at facilities collection");
            document.reference
                .collection(AppFirestoreCollectionConstants.facilities)
                .doc(facilityId)
                .update({AppFirestoreConstants.isMain: true});

            AppUtilities.logger.d("Facility $facilityId as main facility at profile level");
            //TODO Add to model
            //document.reference.update({GigFirestoreConstants.mainFacility: facilityId});

            if(prevFacilityId.isNotEmpty) {
              AppUtilities.logger.d("Facility $prevFacilityId unset from main facility");
              document.reference
                  .collection(AppFirestoreCollectionConstants.facilities)
                  .doc(prevFacilityId)
                  .update({AppFirestoreConstants.isMain: false});
            }
          }
        }
      });

      return true;
    } catch (e) {
      AppUtilities.logger.e(e.toString());
      return false;
    }
  }

}
