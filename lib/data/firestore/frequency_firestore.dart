import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../app_config.dart';
import '../../domain/model/neom/neom_frequency.dart';
import '../../domain/repository/frequency_repository.dart';
import '../../utils/neom_error_logger.dart';
import 'constants/app_firestore_collection_constants.dart';
import 'constants/app_firestore_constants.dart';
import 'profile_document_locator.dart';

class FrequencyFirestore implements FrequencyRepository {

  final _profileLocator = ProfileDocumentLocator();

  /// `profiles/{profileId}/frequencies`, or null when the profile is unknown.
  Future<CollectionReference?> _frequenciesOf(String profileId) =>
      _profileLocator.subcollection(
          profileId, AppFirestoreCollectionConstants.frequencies);

  @override
  Future<Map<String, NeomFrequency>> retrieveFrequencies(profileId) async {
    AppConfig.logger.d("Retrieving NeomFrequency by Profile $profileId");

    Map<String, NeomFrequency> frequencies = {};

    try {
      final frequenciesReference = await _frequenciesOf(profileId);
      if (frequenciesReference == null) return frequencies;

      final qSnapshot = await frequenciesReference.get();
      for (var queryDocumentSnapshot in qSnapshot.docs) {
        NeomFrequency freq = NeomFrequency.fromJSON(
            queryDocumentSnapshot.data() as Map<String, dynamic>);
        frequencies[freq.id] = freq;
      }
    } catch (e, st) {
      NeomErrorLogger.recordError(e, st, module: 'neom_core', operation: 'FrequencyFirestore.retrieveFrequencies');
    }

    AppConfig.logger.d("${frequencies.length} frequencies found");
    return frequencies;
  }

  @override
  Future<bool> removeFrequency({required String profileId, required String frequencyId}) async {
    AppConfig.logger.d("Removing $frequencyId for by $profileId");
    try {
      final frequenciesReference = await _frequenciesOf(profileId);
      if (frequenciesReference == null) return false;

      await frequenciesReference.doc(frequencyId).delete();

      AppConfig.logger.d("NeomFrequency $frequencyId removed");
      return true;
    } catch (e, st) {
      NeomErrorLogger.recordError(e, st, module: 'neom_core', operation: 'FrequencyFirestore.removeFrequency');
      return false;
    }
  }

  @override
  Future<bool> addFrequency({required String profileId, required NeomFrequency frequency}) async {
    AppConfig.logger.d("Adding ${frequency.name} for by $profileId");

    try {
      final frequenciesReference = await _frequenciesOf(profileId);
      if (frequenciesReference == null) return false;

      await frequenciesReference.doc(frequency.id).set(frequency.toJSON());

      AppConfig.logger.d("NeomFrequency ${frequency.id} added");
      return true;
    } catch (e, st) {
      NeomErrorLogger.recordError(e, st, module: 'neom_core', operation: 'FrequencyFirestore.addFrequency');
      return false;
    }
  }

  @override
  Future<bool> updateMainFrequency({required String profileId,
      required String frequencyId, required String prevInstrId}) async {

    AppConfig.logger.d("Updating $frequencyId as main for $profileId");

    try {
      final profileDocument = await _profileLocator.locate(profileId);
      if (profileDocument == null) return false;

      final frequenciesReference = profileDocument
          .collection(AppFirestoreCollectionConstants.frequencies);

      AppConfig.logger.i("NeomFrequency $frequencyId as main frequency at frequencies collection");
      await frequenciesReference.doc(frequencyId)
          .update({AppFirestoreConstants.isMain: true});

      AppConfig.logger.d("NeomFrequency $frequencyId as main frequency at profile level");
      await profileDocument.update({
        AppFirestoreConstants.mainFrequency: frequencyId
      });

      if(prevInstrId.isNotEmpty) {
        AppConfig.logger.d("NeomFrequency $prevInstrId unset from main frequency");
        await frequenciesReference.doc(prevInstrId)
            .update({AppFirestoreConstants.isMain: false});
      }

      return true;
    } catch (e, st) {
      NeomErrorLogger.recordError(e, st, module: 'neom_core', operation: 'FrequencyFirestore.updateMainFrequency');
      return false;
    }
  }
}
