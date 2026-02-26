import '../model/app_release_item.dart';

abstract class ShopCartService {

  int get itemCount;
  double get subtotal;
  bool get isEmpty;

  void addItem(AppReleaseItem item, {int qty = 1});
  void removeItem(String productId);
  void updateQuantity(String productId, int qty);
  void clear();

}
