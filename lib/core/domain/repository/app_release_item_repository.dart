import 'dart:async';
import '../model/app_release_item.dart';

abstract class AppReleaseItemRepository {

  Future<AppReleaseItem> retrieve(String releaseItemId);
  Future<Map<String, AppReleaseItem>> retrieveFromList(List<String> releaseItemIds);

  Future<void> insert(AppReleaseItem releaseItem);
  Future<bool> remove(AppReleaseItem releaseItem);
  Future<bool> addBoughtUser({required String releaseItemId, required String userId});
  Future<Map<String, AppReleaseItem>> retrieveAll();
  Future<bool> exists(String releaseItemId);

}
