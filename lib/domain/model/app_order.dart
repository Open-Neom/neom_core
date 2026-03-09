import 'package:enum_to_string/enum_to_string.dart';

import '../../utils/enums/profile_type.dart';
import '../../utils/platform/core_purchase_details.dart';
import 'app_product.dart';
import 'subscription_plan.dart';

class AppOrder {

  String id;
  String description;
  String url;
  int createdTime;
  String customerEmail;
  ProfileType customerType;
  String couponId;
  List<String>? invoiceIds;
  AppProduct? product;
  SubscriptionPlan? subscriptionPlan;

  dynamic googlePlayPurchaseDetails;
  dynamic appStorePurchaseDetails;

  AppOrder({
    this.id = "",
    this.description = "",
    this.url = '',
    this.createdTime = 0,
    this.customerEmail = '',
    this.customerType = ProfileType.general,
    this.couponId = '',
    this.invoiceIds,
    this.product,
    this.subscriptionPlan,
    this.googlePlayPurchaseDetails,
    this.appStorePurchaseDetails,
  });

  Map<String, dynamic> toJSON() {
    return <String, dynamic>{
      'id': id,
      'description': description,
      'url': url,
      'createdTime': createdTime,
      'customerEmail': customerEmail,
      'customerType': customerType.name,
      'couponId': couponId,
      'invoiceIds': invoiceIds,
      'product': product?.toJSON(),
      'subscriptionPlan': subscriptionPlan?.toJSON(),
      'googlePlayPurchaseDetails': googlePlayPurchaseDetails != null ? googlePlayPurchaseDetailsToJSON(googlePlayPurchaseDetails) : {},
      'appStorePurchaseDetails': appStorePurchaseDetails != null ? appStorePurchaseDetailsToJSON(appStorePurchaseDetails) : {},
    };
  }

  AppOrder.fromJSON(dynamic data) :
    id = data["id"] ?? "",
    description = data["description"] ?? "",
    url = data["url"] ?? "",
    createdTime = data["createdTime"] ?? 0,
    customerEmail = data["customerEmail"] ?? "",
    customerType = EnumToString.fromString(ProfileType.values, data["type"] ?? ProfileType.general.value) ?? ProfileType.general,
    couponId = data["couponId"] ?? "",
    invoiceIds = data["invoiceIds"]?.cast<String>() ?? [],
    product = AppProduct.fromJSON(data["product"] ?? {}),
    subscriptionPlan = SubscriptionPlan.fromJSON(data["subscriptionPlan"] ?? {}),
    googlePlayPurchaseDetails = googlePlayPurchaseDetailsFromJSON(Map<dynamic, dynamic>.from(data["googlePlayPurchaseDetails"] ?? {})),
    appStorePurchaseDetails = appStorePurchaseDetailsFromJSON(Map<dynamic, dynamic>.from(data["appStorePurchaseDetails"] ?? {}));

}
