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
  /// Acquisition source/attribution: which agent or campaign generated this
  /// coupon (e.g. 'agent:serzen', 'campaign:feria2026'). Lets the CRM measure
  /// the funnel per agent/channel once the lead redeems it.
  String source;
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
    this.source = '',
    this.usedBy,
    this.productIds,
    this.excludedProductIds,
    this.allowedEmails,
    this.excludedEmails
  });

  bool get isExpired => expiresAt > 0 && DateTime.now().millisecondsSinceEpoch > expiresAt;
  bool get isUsedUp => usageLimit < 0 || (usageLimit > 0 && (usedBy?.length ?? 0) >= usageLimit);
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
      'source': source,
      'usedBy': usedBy,
      'productIds': productIds,
      'excludedProductIds': excludedProductIds,
      'allowedEmails': allowedEmails,
      'excludedEmails': excludedEmails
    };
  }

  static double _parseDouble(dynamic value, {double fallback = 0.0}) {
    if (value is num) {
      final d = value.toDouble();
      return d.isFinite ? d : fallback;
    }
    if (value is String) {
      final d = double.tryParse(value.trim());
      if (d != null && d.isFinite) return d;
    }
    return fallback;
  }

  static int _parseInt(dynamic value, {int fallback = 0}) {
    if (value is num) {
      if (!value.isFinite) return fallback;
      return value is int ? value : value.toInt();
    }
    if (value is String) {
      final i = int.tryParse(value.trim());
      if (i != null) return i;
      final d = double.tryParse(value.trim());
      if (d != null && d.isFinite) return d.toInt();
    }
    return fallback;
  }

  static List<String> _parseStringList(dynamic value) {
    if (value is List) {
      return value.map((e) => e.toString()).toList();
    }
    return <String>[];
  }

  factory AppCoupon.fromJSON(dynamic data) {
    if (data is! Map) return AppCoupon();
    return AppCoupon(
      id: data["id"]?.toString() ?? "",
      code: data["code"]?.toString() ?? "",
      amount: _parseDouble(data["amount"]),
      ownerEmail: data["ownerEmail"]?.toString() ?? "",
      ownerAmount: _parseDouble(data["ownerAmount"]),
      description: data["description"]?.toString() ?? "",
      type: EnumToString.fromString(
            CouponType.values,
            data["type"]?.toString() ?? "",
          ) ??
          CouponType.oneMonthFree,
      planId: data["planId"]?.toString() ?? '',
      usageLimit: _parseInt(data["usageLimit"], fallback: 25),
      durationMonths: _parseInt(data["durationMonths"], fallback: 1),
      expiresAt: _parseInt(data["expiresAt"], fallback: 0),
      createdAt: _parseInt(data["createdAt"], fallback: 0),
      source: data["source"]?.toString() ?? '',
      usedBy: _parseStringList(data["usedBy"]),
      productIds: _parseStringList(data["productIds"]),
      excludedProductIds: _parseStringList(data["excludedProductIds"]),
      allowedEmails: _parseStringList(data["allowedEmails"]),
      excludedEmails: _parseStringList(data["excludedEmails"]),
    );
  }

}
