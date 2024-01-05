import '../model/item_list.dart';

abstract class ItemlistService {

  Future<void> createItemlist();
  Future<void> updateItemlist(String itemlistId, Itemlist itemlist);
  Future<void> deleteItemlist(Itemlist itemlist);
  ///DEPRECATED Future<void> setAsFavorite(Itemlist itemlist);
  void clearNewItemlist();
  Future<void> gotoItemlistItems(Itemlist itemlist);
  Future<void> synchronizeItemlists();
  Future<void> getSpotifyToken();
  Future<bool> synchronizeItemlist(Itemlist itemlist);
  Future<void> synchronizeSpotifyPlaylists();
  void handlePlaylistList(Itemlist spotifyItemlist);
  Future<void> gotoPlaylistSongs(Itemlist itemlist);
  Future<void> setPrivacyOption();


}
