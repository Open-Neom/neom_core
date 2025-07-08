import '../../utils/enums/product_type.dart';
import '../model/app_product.dart';

abstract class ProductRepository {

  Future<String> insert(AppProduct product);
  Future<bool> remove(AppProduct product);
  Future<List<AppProduct>> retrieveProductsByType({required ProductType type});

}
