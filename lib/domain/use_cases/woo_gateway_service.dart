import 'dart:async';
import '../../utils/enums/product_type.dart';
import '../model/app_release_item.dart';

abstract class WooGatewayService {

  Future<void> createProductFromReleaseItem(AppReleaseItem releaseItem, {bool fromFunctions = false});
  Future<AppReleaseItem?> getProductAsReleaseItem(String productId, {bool fromFunctions = false});
  Future<Map<ProductType, Map<int, AppReleaseItem>>> getProductsAsReleaseItems({int perPage = 25, int page = 1, List<String> categoryIds = const [], bool fromFunctions = false});

}
