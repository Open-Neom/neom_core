import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../core/app_flavour.dart';
import '../../../core/utils/app_utilities.dart';
import '../../domain/woo_product.dart';
import '../../domain/woo_product_attribute.dart';
import '../../utils/constants/woocommerce_constants.dart';
import '../../utils/enums/woo_product_status.dart';

class WooProductsApi {

  static Future<List<WooProduct>> getProducts({perPage = 25, page = 1, WooProductStatus status = WooProductStatus.publish}) async {
    AppUtilities.startStopwatch(reference: 'getProducts');

    String url = '${AppFlavour.getWooCommerceUrl()}/products?page=$page&per_page=$perPage&status=${status.name}';
    String credentials = base64Encode(utf8.encode('${AppFlavour.getWooCommerceClientKey()}:${AppFlavour.getWooCommerceClientSecret()}'));
    List<WooProduct> products = [];

    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Basic $credentials'
        },
      );

      if (response.statusCode == 200) {
        List<dynamic> data = jsonDecode(response.body);
        for(var item in data.asMap().values) {
          WooProduct product = WooProduct.fromJSON(item);
          AppUtilities.logger.i('Product ${product.id} with name ${product.name}');
          products.add(product);
        }

        // List<Product> products = data.map((item) => Product.fromJson(item)).toList();
        AppUtilities.logger.i(products.isNotEmpty);
      } else {
        AppUtilities.logger.i(response.body.toString());
        jsonDecode(response.body);
        throw Exception('Error al cargar productos');
      }
    } catch (e) {
      AppUtilities.logger.e(e.toString());
    }

    AppUtilities.stopStopwatch();
    return products;
  }

  static Future<void> createProduct(WooProduct product) async {

    String url = '${AppFlavour.getWooCommerceUrl()}/products';
    String credentials = base64Encode(utf8.encode('${AppFlavour.getWooCommerceClientKey()}:${AppFlavour.getWooCommerceClientSecret()}'));

    final response = await http.post(
      Uri.parse(url),
      headers: {
        'Authorization': 'Basic $credentials',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(product.toJSON()),
    );

    if (response.statusCode == 201) {
      AppUtilities.logger.i('Producto creado correctamente');
    } else {
      AppUtilities.logger.i('Error al crear el producto: ${response.body}');
    }
  }

  static Future<void> addAttributesToProduct(String productId, List<WooProductAttribute> attributes, {bool isNew = false}) async {

    String url = '${AppFlavour.getWooCommerceUrl()}/products';
    String credentials = base64Encode(utf8.encode('${AppFlavour.getWooCommerceClientKey()}:${AppFlavour.getWooCommerceClientSecret()}'));
    int position = 0;
    try {
      List<WooProductAttribute> totalAttributes = [];
      if(!isNew) {
        WooProduct? currentProduct = await getProductAttributes(productId);
        if(currentProduct?.attributes?.isNotEmpty ?? false) {
          for(var attribute in attributes) {
            if(currentProduct!.attributes!. containsKey(attribute.name)) {
              currentProduct.attributes![attribute.name] = attribute;
              attribute.position = position;
              totalAttributes.add(attribute);
              position++;
            }
          }
          totalAttributes.addAll(currentProduct!.attributes!.values);
          for(var attribute in totalAttributes) {
            attributes.removeWhere((atr) => atr.name == attribute.name);
          }

          position = currentProduct.attributes?.length ?? 0;
        }

      }

      for(var attribute in attributes) {
        attribute.position = position;
        totalAttributes.add(attribute);
        position++;
      }
      final response = await http.put(
        Uri.parse('$url/$productId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Basic $credentials',
        },
        body: jsonEncode({
          WooCommerceConstants.attributes: totalAttributes.map((attribute) => attribute.toJSON()).toList(),
        }),
      );

      if (response.statusCode == 200) {
        AppUtilities.logger.i('Atributos agregados exitosamente');
      } else {
        AppUtilities.logger.i('Error al agregar atributos: ${response.statusCode}');
      }
    } catch (e) {
      AppUtilities.logger.e(e.toString());
    }
  }

  static Future<WooProduct?> getProductAttributes(String productId) async {

    String url = '${AppFlavour.getWooCommerceUrl()}/products';
    String credentials = base64Encode(utf8.encode('${AppFlavour.getWooCommerceClientKey()}:${AppFlavour.getWooCommerceClientSecret()}'));

    WooProduct? product;
    try {
      final response = await http.get(
        Uri.parse('$url/$productId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Basic $credentials',
        },
      );

      if (response.statusCode == 200) {
        product = WooProduct.fromJSON(jsonDecode(response.body));
      } else {
        AppUtilities.logger.i('Error al obtener atributos: ${response.statusCode}');
      }
    } catch (e) {
      AppUtilities.logger.e(e.toString());
    }

    return product;
  }

}
