import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../app_config.dart';
import '../../domain/model/facility.dart';
import '../../domain/repository/facility_repository.dart';
import '../../utils/enums/facilitator_type.dart';
import '../../utils/neom_error_logger.dart';
import 'constants/app_firestore_collection_constants.dart';
import 'constants/app_firestore_constants.dart';
import 'core_firestore_guard.dart';
import 'profile_document_locator.dart';

class FacilityFirestore implements FacilityRepository {

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
    } catch (e, st) {
      NeomErrorLogger.recordError(e, st, module: 'neom_core', operation: 'FacilityFirestore.retrieveFacilities');
    }

    AppConfig.logger.d("${facilities.length} facilities found");
    return facilities;
  }

  @override
  Future<bool> removeFacility({required String profileId, required String facilityId}) async {
    final cleanFacilityId = facilityId.trim();
    if (!CoreFirestoreGuard.isSafeDocId(cleanFacilityId)) return false;
    AppConfig.logger.d("Removing $cleanFacilityId for by $profileId");
    try {
      // OPTIMIZED: Query only the specific profile
      final docRef = await _getProfileDocumentReference(profileId);
      if (docRef != null) {
        await docRef
            .collection(AppFirestoreCollectionConstants.facilities)
            .doc(cleanFacilityId)
            .delete();
        AppConfig.logger.d("Facility $cleanFacilityId removed");
        return true;
      }
    } catch (e, st) {
      NeomErrorLogger.recordError(e, st, module: 'neom_core', operation: 'FacilityFirestore.removeFacility');
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
    } catch (e, st) {
      NeomErrorLogger.recordError(e, st, module: 'neom_core', operation: 'FacilityFirestore.addFacility');
    }
    return false;
  }

  @override
  Future<bool> updateMainFacility({required String profileId,
      required String facilityId, required String prevFacilityId}) async {
    final cleanFacilityId = facilityId.trim();
    if (!CoreFirestoreGuard.isSafeDocId(cleanFacilityId)) return false;

    AppConfig.logger.d("Updating $cleanFacilityId as main for $profileId");

    try {
      // OPTIMIZED: Query only the specific profile
      final docRef = await _getProfileDocumentReference(profileId);
      if (docRef != null) {
        AppConfig.logger.i("Facility $cleanFacilityId as main facility at facilities collection");
        await docRef
            .collection(AppFirestoreCollectionConstants.facilities)
            .doc(cleanFacilityId)
            .update({AppFirestoreConstants.isMain: true});

        AppConfig.logger.d("Facility $cleanFacilityId as main facility at profile level");

        final cleanPrevId = prevFacilityId.trim();
        if (CoreFirestoreGuard.isSafeDocId(cleanPrevId) &&
            cleanPrevId != cleanFacilityId) {
          AppConfig.logger.d("Facility $cleanPrevId unset from main facility");
          await docRef
              .collection(AppFirestoreCollectionConstants.facilities)
              .doc(cleanPrevId)
              .update({AppFirestoreConstants.isMain: false});
        }
        return true;
      }
    } catch (e, st) {
      NeomErrorLogger.recordError(e, st, module: 'neom_core', operation: 'FacilityFirestore.updateMainFacility');
    }
    return false;
  }

}
