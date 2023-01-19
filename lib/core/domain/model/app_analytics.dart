import '../../utils/enums/coupon_type.dart';

class AppAnalytics {

  String id = "";
  String code = "";
  double amount = 1000.00;
  String ownerId = "";
  String description = "";
  CouponType type = CouponType.coinAddition;

  int usageCount = 0;
  int usageLimit = 100;

  bool freeShipping = false;

  List<String> productIds = [];
  List<String> excludedProductIds = [];

  List<String> usedBy = [];
  List<String> allowedEmails = [];
  List<String> excludedEmails = [];

  AppAnalytics({
    this.id = "",
    this.code = "",
    this.amount = 1000,
    this.ownerId = "",
    this.description = "",
    this.type = CouponType.coinAddition,
    this.usageCount = 0,
    this.usageLimit = 100,
    this.freeShipping = false,
    this.productIds = const [],
    this.excludedProductIds = const [],
    this.usedBy = const [],
    this.allowedEmails = const [],
    this.excludedEmails = const []
  });


  @override
  String toString() {
    return 'Coupon{id: $id, code: $code, amount: $amount, ownerId: $ownerId, description: $description, type: $type, usageCount: $usageCount, usageLimit: $usageLimit, freeShipping: $freeShipping, productIds: $productIds, excludedProductIds: $excludedProductIds, usedBy: $usedBy, allowedEmails: $allowedEmails, excludedEmails: $excludedEmails}';
  }


  Map<String, dynamic> toJSON() {
    return <String, dynamic> {
      'id': id,
      'code': code,
      'amount': amount,
      'ownerId': ownerId,
      'description': description,
      'type': type.name,
      'usageCount': usageCount,
      'usageLimit': usageLimit,
      'freeShipping': freeShipping,
      'productIds': productIds,
      'excludedProductIds': excludedProductIds,
      'usedBy': usedBy,
      'allowedEmails': allowedEmails,
      'excludedEmails': excludedEmails
    };
  }

}
