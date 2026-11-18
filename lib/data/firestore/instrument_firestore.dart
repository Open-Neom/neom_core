import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../app_config.dart';
import '../../domain/model/instrument.dart';
import '../../domain/repository/instrument_repository.dart';
import 'constants/app_firestore_collection_constants.dart';
import 'constants/app_firestore_constants.dart';
import 'core_firestore_guard.dart';
import 'profile_document_locator.dart';

class InstrumentFirestore implements InstrumentRepository {

  var logger = AppConfig.logger;
  final _profileLocator = ProfileDocumentLocator();
  Query<Map<String, dynamic>> get profileReference =>
      FirebaseFirestore.instance
          .collectionGroup(AppFirestoreCollectionConstants.profiles);

  /// `profiles/{profileId}/instruments`, or null when the profile is unknown.
  Future<CollectionReference?> _instrumentsOf(String profileId) {
    final cleanId = profileId.trim();
    if (!CoreFirestoreGuard.isSafeDocId(cleanId)) {
      return Future<CollectionReference?>.value(null);
    }
    return _profileLocator.subcollection(
        cleanId, AppFirestoreCollectionConstants.instruments);
  }

  @override
  Future<Map<String,Instrument>> retrieveInstruments(profileId) async {
    logger.t("Retrieving Instrument by Profile $profileId");

    Map<String, Instrument> instruments = {};

    try {
      final instrumentsReference = await _instrumentsOf(profileId);
      if (instrumentsReference == null) return instruments;

      final qSnapshot = await instrumentsReference.get();
      for (var queryDocumentSnapshot in qSnapshot.docs) {
        Instrument instr = Instrument.fromJSON(
            queryDocumentSnapshot.data() as Map<String, dynamic>);
        instruments[instr.name] = instr;
      }
    } catch (e) {
      logger.e("No instruments found");
    }

    logger.d("${instruments.length} instruments found for Profile: $profileId");
    return instruments;
  }

  /// Fan-out read across profiles in the app (bounded to 500 profiles).
  Future<Map<String, List<Instrument>>> retrieveAllInstruments() async {
    logger.t("Retrieving all Instruments for all Profiles");

    Map<String, List<Instrument>> profileInstruments = {};

    try {
      QuerySnapshot profileSnapshot = await profileReference.limit(500).get();

      for (var profileDoc in profileSnapshot.docs) {
        String profileId = profileDoc.id;
        List<Instrument> instruments = [];

        QuerySnapshot instrumentSnapshot = await profileDoc.reference
            .collection(AppFirestoreCollectionConstants.instruments)
            .get();

        for (var instrumentDoc in instrumentSnapshot.docs) {
          Instrument instr = Instrument.fromJSON(
              instrumentDoc.data() as Map<String, dynamic>);
          instruments.add(instr);
        }

        if (instruments.isNotEmpty) {
          profileInstruments[profileId] = instruments;
        }
      }
    } catch (e) {
      logger.e("Error retrieving instruments: $e");
    }

    logger.d("${profileInstruments.length} profiles with instruments found");
    return profileInstruments;
  }

  @override
  Future<bool> removeInstrument({required String profileId, required String instrumentId}) async {
    final cleanInstrumentId = instrumentId.trim();
    if (!CoreFirestoreGuard.isSafeDocId(cleanInstrumentId)) return false;
    logger.d("Removing $cleanInstrumentId for by $profileId");
    try {
      final instrumentsReference = await _instrumentsOf(profileId);
      if (instrumentsReference == null) return false;

      await instrumentsReference.doc(cleanInstrumentId).delete();

      logger.d("Instrument $cleanInstrumentId removed");
      return true;
    } catch (e) {
      logger.e(e.toString());
      return false;
    }
  }

  @override
  Future<bool> addInstrument({required String profileId, required String instrumentId}) async {
    final cleanInstrumentId = instrumentId.trim();
    if (!CoreFirestoreGuard.isSafeDocId(cleanInstrumentId)) return false;
    logger.d("Adding $cleanInstrumentId for by $profileId");

    Instrument instrumentBasic = Instrument.addBasic(cleanInstrumentId);
    try {
      final instrumentsReference = await _instrumentsOf(profileId);
      if (instrumentsReference == null) return false;

      await instrumentsReference.doc(cleanInstrumentId).set(instrumentBasic.toJSON());

      logger.d("Instrument $cleanInstrumentId added");
      return true;
    } catch (e) {
      logger.e(e.toString());
      return false;
    }
  }

  @override
  Future<bool> updateMainInstrument({required String profileId,
      required String instrumentId, required String prevInstrId}) async {
    final cleanProfileId = profileId.trim();
    final cleanInstrumentId = instrumentId.trim();
    if (!CoreFirestoreGuard.isSafeDocId(cleanProfileId) ||
        !CoreFirestoreGuard.isSafeDocId(cleanInstrumentId)) {
      return false;
    }

    logger.d("Updating $cleanInstrumentId as main for $cleanProfileId");

    try {
      final profileDocument = await _profileLocator.locate(cleanProfileId);
      if (profileDocument == null) return false;

      final instrumentsReference = profileDocument
          .collection(AppFirestoreCollectionConstants.instruments);

      logger.i("Instrument $cleanInstrumentId as main instrument at instruments collection");
      await instrumentsReference.doc(cleanInstrumentId)
          .update({AppFirestoreConstants.isMain: true});

      logger.d("Instrument $cleanInstrumentId as main instrument at profile level");
      await profileDocument.update({
        AppFirestoreConstants.mainFeature: cleanInstrumentId
      });

      final cleanPrevId = prevInstrId.trim();
      if (CoreFirestoreGuard.isSafeDocId(cleanPrevId) &&
          cleanPrevId != cleanInstrumentId) {
        logger.d("Instrument $cleanPrevId unset from main instrument");
        await instrumentsReference.doc(cleanPrevId)
            .update({AppFirestoreConstants.isMain: false});
      }

      return true;
    } catch (e) {
      logger.e(e.toString());
      return false;
    }
  }
}
