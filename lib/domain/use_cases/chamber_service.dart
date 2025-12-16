import '../model/neom/neom_chamber.dart';

abstract class ChamberService {

  Future<void> createChamber();
  Future<void> updateChamber(String chamberId, NeomChamber chamber);
  Future<void> deleteChamber(NeomChamber chamber);
  void clearNewChamber();
  Future<void> gotoChamberPresets(NeomChamber chamber);
  Future<void> setPrivacyOption();

}
