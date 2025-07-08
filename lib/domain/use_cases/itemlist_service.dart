import 'package:flutter/cupertino.dart';

import '../../utils/enums/app_item_state.dart';
import '../model/app_media_item.dart';
import '../model/item_list.dart';

abstract class ItemlistService {

  Future<void> createItemlist();
  Future<void> updateItemlist(String itemlistId, Itemlist itemlist);
  Future<void> deleteItemlist(Itemlist itemlist);
  void clearNewItemlist();
  Future<void> gotoItemlistItems(Itemlist itemlist);
  Future<void> setPrivacyOption();
  Future<void> gotoPlaylistSongs(Itemlist itemlist);

  List<Itemlist> getItemlists();
  void setAppMediaItem(AppMediaItem item);
  Future<Itemlist> createBasicItemlist();
  void setSelectedItemlist(String selectedItemlist);
  String getSelectedItemlist();
  void setAppItemState(AppItemState newState);
  int getItemState();
  Future<void> addItemlistItem(BuildContext context, {int fanItemState = 0, bool goHome = true});

  bool checkIsLoading();

}
