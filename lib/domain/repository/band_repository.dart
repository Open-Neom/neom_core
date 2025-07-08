import '../model/band.dart';
import '../model/band_member.dart';

abstract class BandRepository {

  Future<String> insert(Band band);
  Future<Band> retrieve(String bandId);
  Future<bool> remove(Band band);

  Future<Map<String, Band>> getBands();
  Future<Map<String, Band>> getBandsFromList(List<String> bandIds);

  Future<bool> fulfillBandMember(String bandId, BandMember bandMember);
  Future<bool> unfulfillBandMember(String bandId, BandMember bandMember);

  Future<bool> isAvailableName(String bandName);

  Future<bool> addPlayingEvent(String bandId, String eventId);
  Future<bool> addPlayingEventToBands(List<String> bandIds, String eventId);


  Future<bool> removePlayingEvent(String bandId, String eventId);
  Future<bool> removeBandMember(String bandId, BandMember bandMember);

}
