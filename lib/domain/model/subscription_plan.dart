import 'package:enum_to_string/enum_to_string.dart';

import '../../utils/enums/subscription_level.dart';
import 'price.dart';

class SubscriptionPlan {

  String id;
  String name;
  String imgUrl;
  String href;

  String productId; ///Stripe Product Id
  String priceId; ///Stripe Price Id

  SubscriptionLevel? level;
  bool isActive;

  Price? price;
  double? discount;
  DateTime? lastUpdated;  // Tracks when the plan was last updated

  SubscriptionPlan({
    this.id = '',
    this.name = '',
    this.imgUrl = '',
    this.href = '',
    this.productId = '',
    this.priceId = '',
    this.level,
    this.price,
    this.isActive = true,
    this.discount = 0.0,
    this.lastUpdated,
  });

  Map<String, dynamic> toJSON() {
    return <String, dynamic> {
      'id': id,
      'name': name,
      'imgUrl': imgUrl,
      'href': href,
      'productId': productId,
      'priceId': priceId,
      'level': level?.name,
      'price': price?.toJSON(),
      'isActive': isActive,
      'discount': discount,
      'lastUpdated': lastUpdated?.toIso8601String(),
    };
  }


  @override
  String toString() {
    return 'SubscriptionPlan{id: $id, name: $name, imgUrl: $imgUrl, href: $href, productId: $productId, priceId: $priceId, level: $level, isActive: $isActive, price: $price, discount: $discount, lastUpdated: $lastUpdated}';
  }

  SubscriptionPlan.fromJSON(dynamic data)
      : id = data['id'] ?? '',
        name = data['name'] ?? '',
        imgUrl = data['imgUrl'] ?? '',
        href = data['href'] ?? '',
        productId = data['productId'] ?? '',
        priceId = data['priceId'] ?? '',
        level = EnumToString.fromString(SubscriptionLevel.values, data['level'] ?? SubscriptionLevel.basic.name) ?? SubscriptionLevel.basic,
        price = data['price'] != null ? Price.fromJSON(data['price']) : null,
        isActive = data['isActive'] ?? true,
        discount = data['discount'] != null ? double.parse(data['discount'].toString()) : 0.0,
        lastUpdated = data['lastUpdated'] != null ? DateTime.parse(data['lastUpdated']) : null;
}
