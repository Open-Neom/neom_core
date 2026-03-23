import 'package:enum_to_string/enum_to_string.dart';
import '../../utils/enums/coupon_type.dart';

class AppCoupon {

  String id;
  String code;
  double amount;
  String ownerEmail;
  double ownerAmount;
  String description;
  CouponType type;
  String planId;

  int usageLimit;
  int durationMonths; // How many months the benefit lasts (1, 3, 6, 12)
  int expiresAt;      // Coupon expiration timestamp (ms). 0 = no expiration
  int createdAt;      // When the coupon was created (ms)
  List<String>? usedBy;

  List<String>? productIds;
  List<String>? excludedProductIds;

  List<String>? allowedEmails;
  List<String>? excludedEmails;

  AppCoupon({
    this.id = "",
    this.code = "",
    this.amount = 0,
    this.ownerEmail = "",
    this.ownerAmount = 1,
    this.description = "",
    this.type = CouponType.oneMonthFree,
    this.planId = '',
    this.usageLimit = 100,
    this.durationMonths = 1,
    this.expiresAt = 0,
    this.createdAt = 0,
    this.usedBy,
    this.productIds,
    this.excludedProductIds,
    this.allowedEmails,
    this.excludedEmails
  });

  bool get isExpired => expiresAt > 0 && DateTime.now().millisecondsSinceEpoch > expiresAt;
  bool get isUsedUp => (usedBy?.length ?? 0) >= usageLimit;
  bool get isValid => !isExpired && !isUsedUp;

  @override
  String toString() {
    return 'AppCoupon{id: $id, code: $code, amount: $amount, ownerEmail: $ownerEmail, description: $description, type: $type, usageLimit: $usageLimit, usedBy: $usedBy, productIds: $productIds, excludedProductIds: $excludedProductIds, allowedEmails: $allowedEmails, excludedEmails: $excludedEmails}';
  }

  Map<String, dynamic> toJSON() {
    return <String, dynamic> {
      'id': id,
      'code': code,
      'amount': amount,
      'ownerEmail': ownerEmail,
      'ownerAmount': ownerAmount,
      'description': description,
      'type': type.name,
      'planId': planId,
      'usageLimit': usageLimit,
      'durationMonths': durationMonths,
      'expiresAt': expiresAt,
      'createdAt': createdAt,
      'usedBy': usedBy,
      'productIds': productIds,
      'excludedProductIds': excludedProductIds,
      'allowedEmails': allowedEmails,
      'excludedEmails': excludedEmails
    };
  }

  AppCoupon.fromJSON(dynamic data) :
    id = data["id"] ?? "",
    code = data["code"] ?? "",
    amount = data["amount"] ?? 0,
    ownerEmail = data["ownerEmail"] ?? "",
    ownerAmount = data["ownerAmount"] ?? 0,
    description = data["description"] ?? "",
    type = EnumToString.fromString(CouponType.values, data["type"]) ?? CouponType.oneMonthFree,
    planId = data["planId"] ?? '',
    usageLimit = data["usageLimit"] ?? 25,
    durationMonths = data["durationMonths"] ?? 1,
    expiresAt = data["expiresAt"] ?? 0,
    createdAt = data["createdAt"] ?? 0,
    usedBy = data["usedBy"]?.cast<String>() ?? [],
    productIds = data["productIds"]?.cast<String>() ?? [],
    excludedProductIds = data["excludedProductIds"]?.cast<String>() ?? [],
    allowedEmails = data["allowedEmails"]?.cast<String>() ?? [],
    excludedEmails = data["excludedEmails"]?.cast<String>() ?? [];

}
