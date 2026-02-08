import 'dart:async';
import '../../utils/enums/product_type.dart';
import '../model/app_release_item.dart';

abstract class WooGatewayService {

  /// Creates a WooCommerce product from an AppReleaseItem
  /// Returns the permalink URL for web access, or null if creation failed
  Future<String?> createProductFromReleaseItem(
    AppReleaseItem releaseItem, {
    bool fromFunctions = false,
    String? coverImageUrl,
    String? downloadFileUrl,
  });

  Future<AppReleaseItem?> getProductAsReleaseItem(String productId, {bool fromFunctions = false});
  Future<Map<ProductType, Map<int, AppReleaseItem>>> getProductsAsReleaseItems({int perPage = 25, int page = 1, List<String> categoryIds = const [], bool fromFunctions = false});

}
