import 'package:enum_to_string/enum_to_string.dart';

import '../../utils/enums/subscription_level.dart';
import 'price.dart';

class SubscriptionPlan {

  String id;
  String name;
  String imgUrl;
  String href;

  String productId; ///Stripe Product Id
  String priceId; ///Stripe Price Id (monthly by convention)
  String priceIdYearly; ///Stripe Price Id for yearly billing (optional)

  SubscriptionLevel? level;
  bool isActive;
  bool isLive;

  Price? price;           ///Monthly price (resolved from Stripe)
  Price? priceYearly;     ///Yearly price (resolved from Stripe, optional)
  double? discount;
  DateTime? lastUpdated;  // Tracks when the plan was last updated

  /// Founder program (optional). When `founderTier` is non-empty, the UI shows
  /// a "remaining seats" counter and the plan is marketed as lifetime.
  /// Values: 'obsidiana' | 'cuarzo' | 'amatista' | 'turquesa' | 'jade'.
  String founderTier;
  int founderSeatsTotal;
  int founderSeatsRemaining;

  SubscriptionPlan({
    this.id = '',
    this.name = '',
    this.imgUrl = '',
    this.href = '',
    this.productId = '',
    this.priceId = '',
    this.priceIdYearly = '',
    this.level,
    this.price,
    this.priceYearly,
    this.isActive = true,
    this.isLive = true,
    this.discount = 0.0,
    this.lastUpdated,
    this.founderTier = '',
    this.founderSeatsTotal = 0,
    this.founderSeatsRemaining = 0,
  });

  bool get isFounderPlan => founderTier.isNotEmpty;

  Map<String, dynamic> toJSON() {
    return <String, dynamic> {
      'id': id,
      'name': name,
      'imgUrl': imgUrl,
      'href': href,
      'productId': productId,
      'priceId': priceId,
      'priceIdYearly': priceIdYearly,
      'level': level?.name,
      'price': price?.toJSON(),
      'priceYearly': priceYearly?.toJSON(),
      'isActive': isActive,
      'isLive': isLive,
      'discount': discount,
      'lastUpdated': lastUpdated?.toIso8601String(),
      'founderTier': founderTier,
      'founderSeatsTotal': founderSeatsTotal,
      'founderSeatsRemaining': founderSeatsRemaining,
    };
  }


  @override
  String toString() {
    return 'SubscriptionPlan{id: $id, name: $name, imgUrl: $imgUrl, href: $href, productId: $productId, priceId: $priceId, level: $level, isActive: $isActive, isLive: $isLive, price: $price, discount: $discount, lastUpdated: $lastUpdated}';
  }

  SubscriptionPlan.fromJSON(dynamic data)
      : id = data['id'] ?? '',
        name = data['name'] ?? '',
        imgUrl = data['imgUrl'] ?? '',
        href = data['href'] ?? '',
        productId = data['productId'] ?? '',
        priceId = data['priceId'] ?? '',
        priceIdYearly = data['priceIdYearly'] ?? '',
        level = EnumToString.fromString(SubscriptionLevel.values, data['level'] ?? SubscriptionLevel.basic.name) ?? SubscriptionLevel.basic,
        price = data['price'] != null ? Price.fromJSON(data['price']) : null,
        priceYearly = data['priceYearly'] != null ? Price.fromJSON(data['priceYearly']) : null,
        isActive = data['isActive'] ?? true,
        isLive = data['isLive'] ?? true,
        discount = data['discount'] != null ? double.parse(data['discount'].toString()) : 0.0,
        lastUpdated = data['lastUpdated'] != null ? DateTime.parse(data['lastUpdated']) : null,
        founderTier = data['founderTier'] ?? '',
        founderSeatsTotal = data['founderSeatsTotal'] is int
            ? data['founderSeatsTotal'] as int
            : int.tryParse(data['founderSeatsTotal']?.toString() ?? '') ?? 0,
        founderSeatsRemaining = data['founderSeatsRemaining'] is int
            ? data['founderSeatsRemaining'] as int
            : int.tryParse(data['founderSeatsRemaining']?.toString() ?? '') ?? 0;
}
