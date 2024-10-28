import 'package:enum_to_string/enum_to_string.dart';

import '../../utils/enums/cancellation_reason.dart';
import '../../utils/enums/subscription_level.dart';
import '../../utils/enums/subscription_status.dart';
import 'price.dart';

class UserSubscription {

  String subscriptionId;
  String userId;
  SubscriptionLevel? level;

  Price? price;
  SubscriptionStatus? status;
  int startDate;
  int endDate;
  CancellationReason? endReason; // Reason for cancellation, if applicable
  // bool autoRenew;          // Indicates if the subscription auto-renews
  // DateTime? renewalDate;   // Optional renewal date
  // String? paymentMethodId; // Optional payment method identifier



  UserSubscription({
    this.subscriptionId = '',
    this.userId = '',
    this.level,
    this.price,
    this.status,
    this.startDate = 0,
    this.endDate = 0,
    this.endReason
    // this.renewalDate,
    // this.autoRenew = true,
    // this.paymentMethodId,

  });

  Map<String, dynamic> toJSON() {
    return <String, dynamic>{
      'subscriptionId': subscriptionId,
      'userId': userId,
      'level': level?.name,
      'price': price?.toJSON(),
      'status': status?.name,
      'startDate': startDate,
      'endDate': endDate,
      'endReason': endReason,
      // 'renewalDate': renewalDate?.toIso8601String(),
      // 'autoRenew': autoRenew,
      // 'paymentMethodId': paymentMethodId,
    };
  }

  UserSubscription.fromJSON(Map<String, dynamic> data)
      : subscriptionId = data['subscriptionId'] ?? '',
        userId = data['userId'] ?? '',
        level = data['level'] != null ? EnumToString.fromString(SubscriptionLevel.values, data['level']) : null,
        price = data['price'] != null ? Price.fromJSON(data['price']) : null,
        status = data['status'] != null ? EnumToString.fromString(SubscriptionStatus.values, data['status']) : null,
        startDate = data['startDate'] ?? 0,
        endDate = data['endDate'] ?? 0,
        endReason = data['endReason'] != null ? EnumToString.fromString(CancellationReason.values, data['endReason']) : null;
        // renewalDate = data['renewalDate'] != null ? DateTime.parse(data['renewalDate']) : null,
        // autoRenew = data['autoRenew'] ?? true,
        // paymentMethodId = data['paymentMethodId'];
}
