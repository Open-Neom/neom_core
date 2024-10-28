import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/model/instrument.dart';
import '../../domain/repository/instrument_repository.dart';
import '../../utils/app_utilities.dart';
import 'constants/app_firestore_collection_constants.dart';
import 'constants/app_firestore_constants.dart';

class InstrumentFirestore implements InstrumentRepository {

  var logger = AppUtilities.logger;
  final profileReference = FirebaseFirestore.instance.collectionGroup(AppFirestoreCollectionConstants.profiles);


  @override
  Future<Map<String,Instrument>> retrieveInstruments(profileId) async {
    logger.t("Retrieving Instrument by Profile $profileId");

    Map<String, Instrument> instruments = {};

    try {
      QuerySnapshot querySnapshot = await profileReference.get();
      for (var document in querySnapshot.docs) {
        if(document.id == profileId) {
          QuerySnapshot qSnapshot = await document.reference
              .collection(AppFirestoreCollectionConstants.instruments).get();

          for (var queryDocumentSnapshot in qSnapshot.docs) {
            Instrument instr = Instrument.fromJSON(queryDocumentSnapshot.data());
            instruments[instr.name] = instr;
          }
        }
      }
    } catch (e) {
      logger.e("No instruments found");
    }

    logger.d("${instruments.length} instruments found for Profile: $profileId");
    return instruments;
  }

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
          Instrument instr = Instrument.fromJSON(instrumentDoc.data());
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
      await profileReference.get()
          .then((querySnapshot) async {
        for (var document in querySnapshot.docs) {
          if (document.id == profileId) {
            await document.reference
                .collection(AppFirestoreCollectionConstants.instruments)
                .doc(instrumentId)
                .delete();
          }
        }
      });

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
      await profileReference.get()
          .then((querySnapshot) async {
        for (var document in querySnapshot.docs) {
          if (document.id == profileId) {
            await document.reference
                .collection(AppFirestoreCollectionConstants.instruments)
                .doc(instrumentId)
                .set(instrumentBasic.toJSON());
          }
        }
      });

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
      await profileReference.get()
          .then((querySnapshot) async {
        for (var document in querySnapshot.docs) {
          if (document.id == profileId) {
            logger.i("Instrument $instrumentId as main instrument at instruments collection");
            await document.reference
                .collection(AppFirestoreCollectionConstants.instruments)
                .doc(instrumentId)
                .update({AppFirestoreConstants.isMain: true});

            logger.d("Instrument $instrumentId as main instrument at profile level");

            await document.reference.update({
              AppFirestoreConstants.mainFeature: instrumentId
            });

            if(prevInstrId.isNotEmpty) {
              logger.d("Instrument $prevInstrId unset from main instrument");
              await document.reference
                  .collection(AppFirestoreCollectionConstants.instruments)
                  .doc(prevInstrId)
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
