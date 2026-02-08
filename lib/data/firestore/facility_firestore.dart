import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../app_config.dart';
import '../../domain/model/facility.dart';
import '../../domain/repository/facility_repository.dart';
import '../../utils/enums/facilitator_type.dart';
import 'constants/app_firestore_collection_constants.dart';
import 'constants/app_firestore_constants.dart';

class FacilityFirestore implements FacilityRepository {

  final profileReference = FirebaseFirestore.instance.collectionGroup(AppFirestoreCollectionConstants.profiles);

  /// OPTIMIZED: Helper method to get a profile document reference by ID
  /// Uses the 'id' field stored in the document instead of FieldPath.documentId
  /// (collectionGroup queries don't support FieldPath.documentId with simple IDs)
  Future<DocumentReference?> _getProfileDocumentReference(String profileId) async {
    if (profileId.isEmpty) {
      AppConfig.logger.w('Cannot get profile reference: profileId is empty');
      return null;
    }

    try {
      final querySnapshot = await profileReference
          .where('id', isEqualTo: profileId)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        return querySnapshot.docs.first.reference;
      }
    } catch (e) {
      AppConfig.logger.e('Error getting profile reference: $e');
    }
    return null;
  }

  @override
  Future<Map<String,Facility>> retrieveFacilities(profileId) async {
    AppConfig.logger.d("Retrieving Facility by Profile $profileId");

    Map<String, Facility> facilities = {};

    try {
      // OPTIMIZED: Query only the specific profile instead of all profiles
      final docRef = await _getProfileDocumentReference(profileId);
      if (docRef != null) {
        final qSnapshot = await docRef
            .collection(AppFirestoreCollectionConstants.facilities)
            .get();

        for (var queryDocumentSnapshot in qSnapshot.docs) {
          Facility facility = Facility.fromQueryDocumentSnapshot(queryDocumentSnapshot: queryDocumentSnapshot);
          facilities[facility.name] = facility;
        }
      }
    } catch (e) {
      AppConfig.logger.e("No facilities found");
    }

    AppConfig.logger.d("${facilities.length} facilities found");
    return facilities;
  }

  @override
  Future<bool> removeFacility({required String profileId, required String facilityId}) async {
    AppConfig.logger.d("Removing $facilityId for by $profileId");
    try {
      // OPTIMIZED: Query only the specific profile
      final docRef = await _getProfileDocumentReference(profileId);
      if (docRef != null) {
        await docRef
            .collection(AppFirestoreCollectionConstants.facilities)
            .doc(facilityId)
            .delete();
        AppConfig.logger.d("Facility $facilityId removed");
        return true;
      }
    } catch (e) {
      AppConfig.logger.e(e.toString());
    }
    return false;
  }

  @override
  Future<bool> addFacility({required String profileId, required FacilityType facilityType}) async {
    AppConfig.logger.d("Adding $facilityType for by $profileId");

    Facility facilityBasic = Facility.addBasic(facilityType);
    try {
      // OPTIMIZED: Query only the specific profile
      final docRef = await _getProfileDocumentReference(profileId);
      if (docRef != null) {
        await docRef
            .collection(AppFirestoreCollectionConstants.facilities)
            .add(facilityBasic.toJSON());
        AppConfig.logger.d("Facility $facilityType added");
        return true;
      }
    } catch (e) {
      AppConfig.logger.e(e.toString());
    }
    return false;
  }

  @override
  Future<bool> updateMainFacility({required String profileId,
      required String facilityId, required String prevFacilityId}) async {

    AppConfig.logger.d("Updating $facilityId as main for $profileId");

    try {
      // OPTIMIZED: Query only the specific profile
      final docRef = await _getProfileDocumentReference(profileId);
      if (docRef != null) {
        AppConfig.logger.i("Facility $facilityId as main facility at facilities collection");
        await docRef
            .collection(AppFirestoreCollectionConstants.facilities)
            .doc(facilityId)
            .update({AppFirestoreConstants.isMain: true});

        AppConfig.logger.d("Facility $facilityId as main facility at profile level");

        if (prevFacilityId.isNotEmpty) {
          AppConfig.logger.d("Facility $prevFacilityId unset from main facility");
          await docRef
              .collection(AppFirestoreCollectionConstants.facilities)
              .doc(prevFacilityId)
              .update({AppFirestoreConstants.isMain: false});
        }
        return true;
      }
    } catch (e) {
      AppConfig.logger.e(e.toString());
    }
    return false;
  }

}
