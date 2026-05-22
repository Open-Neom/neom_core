// Tests for `ItemFoundInList` — value class trivial.

import 'package:flutter_test/flutter_test.dart';
import 'package:neom_core/domain/model/item_found_in_list.dart';

void main() {
  group('ItemFoundInList — constructor', () {
    test('todos los required positivos', () {
      final i = ItemFoundInList(
        listId: 'l1',
        listName: 'Mi lista',
        itemId: 'i1',
        itemName: 'Item 1',
        itemState: 3,
        itemImgUrl: 'https://x',
      );
      expect(i.listId, 'l1');
      expect(i.listName, 'Mi lista');
      expect(i.itemId, 'i1');
      expect(i.itemName, 'Item 1');
      expect(i.itemState, 3);
      expect(i.itemImgUrl, 'https://x');
      expect(i.listImgUrl, isNull);
    });

    test('listImgUrl opcional', () {
      final i = ItemFoundInList(
        listId: 'l1', listName: 'L', itemId: 'i1', itemName: 'X',
        itemState: 0, itemImgUrl: '',
        listImgUrl: 'https://list.png',
      );
      expect(i.listImgUrl, 'https://list.png');
    });
  });

  group('ItemFoundInList.toString', () {
    test('contiene todos los campos clave', () {
      final i = ItemFoundInList(
        listId: 'l1', listName: 'Mi lista',
        itemId: 'i1', itemName: 'Item',
        itemState: 5, itemImgUrl: 'https://x',
      );
      final s = i.toString();
      expect(s, contains('l1'));
      expect(s, contains('Mi lista'));
      expect(s, contains('i1'));
      expect(s, contains('Item'));
      expect(s, contains('5'));
    });
  });
}
