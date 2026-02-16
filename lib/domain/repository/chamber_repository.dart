import 'dart:async';
import '../model/neom/neom_chamber.dart';
import '../model/neom/neom_chamber_preset.dart';


abstract class ChamberRepository {

  Future<String> insert(NeomChamber chamber);
  Future<NeomChamber> retrieve(String chamberId);
  Future<bool> update(NeomChamber chamber);
  Future<bool> delete(String chamberId);

  Future<Map<String, NeomChamber>> fetchAll({bool onlyPublic = false, bool excludeMyFavorites = true, int minItems = 0, int maxLength = 100, String ownerId = ''});

  Future<bool> addPreset(String chamberId, NeomChamberPreset preset);
  Future<bool> deletePreset(String chamberId, NeomChamberPreset preset);
  Future<bool> updatePreset(String chamberId, NeomChamberPreset preset);

}
