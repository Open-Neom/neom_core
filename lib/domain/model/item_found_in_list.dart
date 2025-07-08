class ItemFoundInList {
  final String itemId;
  final String itemName;
  final int itemState;
  final String itemImgUrl;
  final String listId;
  final String listName;
  final String? listImgUrl;



  ItemFoundInList({
    required this.listId,
    required this.listName,
    this.listImgUrl,
    required this.itemId,
    required this.itemName,
    required this.itemState,
    required this.itemImgUrl,
  });

  @override
  String toString() {
    return 'ItemFoundInList{itemId: $itemId, itemName: $itemName, itemState: $itemState, itemImgUrl: $itemImgUrl, listId: $listId, listName: $listName, listImgUrl: $listImgUrl}';
  }

}
