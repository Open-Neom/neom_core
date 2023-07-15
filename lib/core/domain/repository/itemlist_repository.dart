import 'dart:async';
import '../model/app_item.dart';
import '../model/app_release_item.dart';
import '../model/item_list.dart';
import '../model/neom/chamber_preset.dart';


abstract class ItemlistRepository {

  Future<bool> addAppItem(String profileId, AppItem appItem, String itemlistId);
  Future<bool> removeItem(String profileId, AppItem appItem, String itemlistId);
  Future<bool> updateItem(String profileId, String itemlistId, AppItem item);

  Future<String> insert(String profileId, Itemlist itemlist);
  Future<bool> remove(String profileId, String itemlistId);

  Future<bool> update(String profileId, Itemlist itemlist);
  Future<bool> setAsFavorite(String profileId, Itemlist itemlist);
  Future<bool> unsetOfFavorite(String profileId, Itemlist itemlist);


  Future<Map<String, Itemlist>> retrieveItemlists(String profileId);

  Future<bool> addReleaseItem({required String profileId, required String itemlistId,
    required AppReleaseItem releaseItem});

  Future<bool> removeReleaseItem({required String profileId, required String itemlistId,
    required AppReleaseItem releaseItem});

  Future<bool> addPreset({required String profileId,required String chamberId,required ChamberPreset preset});
  Future<bool> removePreset(String profileId, ChamberPreset preset, String chamberId);
  Future<bool> updatePreset(String profileId, String chamberId, ChamberPreset preset);


}
