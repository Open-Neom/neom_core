import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:enum_to_string/enum_to_string.dart';
import '../../utils/enums/coupon_type.dart';

class AppCoupon {

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

  AppCoupon({
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

  AppCoupon.fromDocumentSnapshot(DocumentSnapshot documentSnapshot):
    id = documentSnapshot.id,
    code = documentSnapshot.get("code") ?? "",
    amount = double.parse(documentSnapshot.get("amount").toString()),
    ownerId = documentSnapshot.get("ownerId") ?? "",
    description = documentSnapshot.get("description") ?? "",
    type = EnumToString.fromString(CouponType.values, documentSnapshot.get("type")) ?? CouponType.coinAddition,
    usageCount = documentSnapshot.get("usageCount") ?? 0,
    usageLimit = documentSnapshot.get("usageLimit") ?? 100,
    freeShipping = documentSnapshot.get("freeShipping") ?? false,
    productIds = List.from(documentSnapshot.get("productIds")),
    excludedProductIds = List.from(documentSnapshot.get("excludedProductIds")),
    usedBy = List.from(documentSnapshot.get("usedBy")),
    allowedEmails = List.from(documentSnapshot.get("allowedEmails")),
    excludedEmails = List.from(documentSnapshot.get("excludedEmails"));

}
