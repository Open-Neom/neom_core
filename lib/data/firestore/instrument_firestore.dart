import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../app_config.dart';
import '../../domain/model/instrument.dart';
import '../../domain/repository/instrument_repository.dart';
import 'constants/app_firestore_collection_constants.dart';
import 'constants/app_firestore_constants.dart';
import 'profile_document_locator.dart';

class InstrumentFirestore implements InstrumentRepository {

  var logger = AppConfig.logger;
  final _profileLocator = ProfileDocumentLocator();
  final profileReference = FirebaseFirestore.instance
      .collectionGroup(AppFirestoreCollectionConstants.profiles);

  /// `profiles/{profileId}/instruments`, or null when the profile is unknown.
  Future<CollectionReference?> _instrumentsOf(String profileId) =>
      _profileLocator.subcollection(
          profileId, AppFirestoreCollectionConstants.instruments);

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

  /// Fan-out read across every profile in the app. Intentionally unbounded —
  /// it backs admin/analytics tooling, not any per-user screen.
  Future<Map<String, List<Instrument>>> retrieveAllInstruments() async {
    logger.t("Retrieving all Instruments for all Profiles");

    Map<String, List<Instrument>> profileInstruments = {};

    try {
      // Obtener todos los documentos de perfiles
      QuerySnapshot profileSnapshot = await profileReference.get();

      // Para cada perfil, obtener su colección de instrumentos
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

        // Asociar los instrumentos con el ID del perfil
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
    logger.d("Removing $instrumentId for by $profileId");
    try {
      final instrumentsReference = await _instrumentsOf(profileId);
      if (instrumentsReference == null) return false;

      await instrumentsReference.doc(instrumentId).delete();

      logger.d("Instrument $instrumentId removed");
      return true;
    } catch (e) {
      logger.e(e.toString());
      return false;
    }
  }

  @override
  Future<bool> addInstrument({required String profileId, required String instrumentId}) async {
    logger.d("Adding $instrumentId for by $profileId");

    Instrument instrumentBasic = Instrument.addBasic(instrumentId);
    try {
      final instrumentsReference = await _instrumentsOf(profileId);
      if (instrumentsReference == null) return false;

      await instrumentsReference.doc(instrumentId).set(instrumentBasic.toJSON());

      logger.d("Instrument $instrumentId added");
      return true;
    } catch (e) {
      logger.e(e.toString());
      return false;
    }
  }

  @override
  Future<bool> updateMainInstrument({required String profileId,
      required String instrumentId, required String prevInstrId}) async {

    logger.d("Updating $instrumentId as main for $profileId");

    try {
      final profileDocument = await _profileLocator.locate(profileId);
      if (profileDocument == null) return false;

      final instrumentsReference = profileDocument
          .collection(AppFirestoreCollectionConstants.instruments);

      logger.i("Instrument $instrumentId as main instrument at instruments collection");
      await instrumentsReference.doc(instrumentId)
          .update({AppFirestoreConstants.isMain: true});

      logger.d("Instrument $instrumentId as main instrument at profile level");
      await profileDocument.update({
        AppFirestoreConstants.mainFeature: instrumentId
      });

      if(prevInstrId.isNotEmpty) {
        logger.d("Instrument $prevInstrId unset from main instrument");
        await instrumentsReference.doc(prevInstrId)
            .update({AppFirestoreConstants.isMain: false});
      }

      return true;
    } catch (e) {
      logger.e(e.toString());
      return false;
    }
  }
}
