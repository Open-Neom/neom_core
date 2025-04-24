import '../model/item_list.dart';

abstract class ItemlistService {

  Future<void> createItemlist();
  Future<void> updateItemlist(String itemlistId, Itemlist itemlist);
  Future<void> deleteItemlist(Itemlist itemlist);
  void clearNewItemlist();
  Future<void> gotoItemlistItems(Itemlist itemlist);
  Future<void> setPrivacyOption();
  Future<void> gotoPlaylistSongs(Itemlist itemlist);

}
