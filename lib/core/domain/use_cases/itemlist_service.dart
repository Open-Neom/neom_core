import '../model/item_list.dart';

abstract class ItemlistService {

  Future<void> createItemlist();
  Future<void> deleteItemlist(Itemlist itemlist);
  Future<void> setAsFavorite(Itemlist itemlist);
  Future<void> updateItemlist(String itemlistId, Itemlist itemlist);

}
