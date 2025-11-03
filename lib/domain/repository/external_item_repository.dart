import 'dart:async';
import '../model/external_item.dart';

abstract class ExternalItemRepository {

  Future<ExternalItem> retrieve(String itemId);
  Future<Map<String, ExternalItem>> retrieveFromList(List<String> itemIds);
  Future<Map<String, ExternalItem>> fetchAll();
  Future<bool> exists(String itemId);
  Future<void> existsOrInsert(ExternalItem item);

  Future<void> insert(ExternalItem item);
  Future<bool> remove(ExternalItem item);

  Future<bool> removeItemFromList(String profileId, String itemlistId, ExternalItem externalItem);
}
