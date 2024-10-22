import 'package:enum_to_string/enum_to_string.dart';

import '../../utils/enums/subscription_level.dart';
import 'price.dart';

class SubscriptionPlan {

  String productId; ///Stripe Product Id
  SubscriptionLevel? level;
  Price? price;
  bool isActive;
  double? discount;
  DateTime? lastUpdated;  // Tracks when the plan was last updated

  SubscriptionPlan({
    this.productId = '',
    this.level,
    this.price,
    this.isActive = true,
    this.discount = 0.0,
    this.lastUpdated,
  });

  Map<String, dynamic> toJSON() {
    return <String, dynamic>{
      'productId': productId,
      'level': level?.name,
      'price': price?.toJSON(),
      'isActive': isActive,
      'discount': discount,
      'lastUpdated': lastUpdated?.toIso8601String(),
    };
  }

  SubscriptionPlan.fromJSON(Map<String, dynamic> data)
      : productId = data['productId'] ?? '',
        level = EnumToString.fromString(SubscriptionLevel.values, data['level'])!,
        price = Price.fromJSON(data['price']),
        isActive = data['isActive'] ?? true,
        discount = data['discount'] ?? 0.0,
        lastUpdated = data['lastUpdated'] != null ? DateTime.parse(data['lastUpdated']) : null;
}
