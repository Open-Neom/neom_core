import 'dart:async';
import '../model/instrument.dart';

abstract class InstrumentRepository {

  Future<Map<String?,Instrument>> retrieveInstruments(String profileId);
  Future<bool> removeInstrument({required String profileId, required String instrumentId});
  Future<bool> addInstrument({required String profileId, required String instrumentId});
  Future<bool> updateMainInstrument({required String profileId,
    required String instrumentId, required String prevInstrId});

}
