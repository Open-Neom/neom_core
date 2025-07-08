import 'dart:async';
import '../model/app_media_item.dart';

abstract class AppMediaItemRepository {

  Future<AppMediaItem> retrieve(String itemId);
  Future<Map<String, AppMediaItem>> retrieveFromList(List<String> itemIds);
  Future<Map<String, AppMediaItem>> fetchAll();
  Future<bool> exists(String itemId);
  Future<void> existsOrInsert(AppMediaItem item);

  Future<void> insert(AppMediaItem item);
  Future<bool> remove(AppMediaItem item);

  Future<bool> removeItemFromList(String profileId, String itemlistId, AppMediaItem appItem);
}
