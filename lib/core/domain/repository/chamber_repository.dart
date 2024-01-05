import 'dart:async';
import '../model/chamber.dart';
import '../model/neom/chamber_preset.dart';


abstract class ChamberRepository {

  Future<String> insert(Chamber chamber);
  Future<Chamber> retrieve(String chamberId);
  Future<bool> update(Chamber chamber);
  Future<bool> delete(chamberId);

  Future<Map<String, Chamber>> fetchAll({bool onlyPublic = false, bool excludeMyFavorites = true, int minItems = 0, int maxLength = 100, String ownerId = ''});

  Future<bool> addPreset(String chamberId, ChamberPreset preset);
  Future<bool> deletePreset(String chamberId, ChamberPreset preset);
  Future<bool> updatePreset(String chamberId, ChamberPreset preset);

}
