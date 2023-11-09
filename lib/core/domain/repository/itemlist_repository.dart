import 'dart:async';
import '../model/app_media_item.dart';
import '../model/app_release_item.dart';
import '../model/item_list.dart';
import '../model/neom/chamber_preset.dart';


abstract class ItemlistRepository {

  Future<bool> addAppMediaItem(AppMediaItem appMediaItem, String itemlistId);
  Future<bool> deleteItem(AppMediaItem appMediaItem, String itemlistId);
  Future<bool> updateItem(String itemlistId, AppMediaItem appMediaItem);

  Future<String> insert(Itemlist itemlist);
  Future<bool> delete(itemlistId);

  Future<bool> update(Itemlist itemlist);

  Future<Map<String, Itemlist>> fetchAll({bool onlyPublic = false, bool excludeMyFavorites = true, int minItems = 0, int maxLength = 100, String profileId = ''});

  Future<bool> addReleaseItem(String itemlistId, AppReleaseItem releaseItem);
  Future<bool> deleteReleaseItem(String itemlistId, AppReleaseItem releaseItem);

  Future<bool> addPreset(String chamberId, ChamberPreset preset);
  Future<bool> deletePreset(ChamberPreset preset, String chamberId);
  Future<bool> updatePreset(String chamberId, ChamberPreset preset);

}
