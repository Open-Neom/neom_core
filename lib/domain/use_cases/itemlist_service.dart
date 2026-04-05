import 'package:flutter/cupertino.dart';

import '../../utils/enums/app_item_state.dart';
import '../model/app_media_item.dart';
import '../model/item_list.dart';

abstract class ItemlistService {

  Future<void> restart();
  Future<void> createItemlist();
  Future<void> updateItemlist(String itemlistId, Itemlist itemlist);
  Future<void> deleteItemlist(Itemlist itemlist);
  void clearNewItemlist();
  Future<void> setPrivacyOption();

  List<Itemlist> getItemlists();
  void setAppMediaItem(AppMediaItem item);
  Future<Itemlist> createBasicItemlist();
  void setSelectedItemlist(String selectedItemlist);
  String getSelectedItemlist();
  void setAppItemState(AppItemState newState);
  int getItemState();
  Future<void> addItemlistItem(BuildContext context, {int fanItemState = 0});

  bool checkIsLoading();

  TextEditingController get newItemlistNameController;
  set newItemlistNameController(TextEditingController newItemlistNameController);

  TextEditingController get newItemlistDescController;
  set newItemlistDescController(TextEditingController newItemlistDescController);

  bool get isPublicNewItemlist;
  set isPublicNewItemlist(bool isPublic);

}
