import '../model/chamber.dart';

abstract class ChamberService {

  Future<void> createChamber();
  Future<void> updateChamber(String chamberId, Chamber chamber);
  Future<void> deleteChamber(Chamber chamber);
  void clearNewChamber();
  Future<void> gotoChamberPresets(Chamber chamber);
  Future<void> setPrivacyOption();

}
