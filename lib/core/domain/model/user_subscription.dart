import 'package:enum_to_string/enum_to_string.dart';

import '../../utils/enums/cancellation_reason.dart';
import '../../utils/enums/subscription_level.dart';
import '../../utils/enums/subscription_status.dart';
import 'price.dart';

class UserSubscription {

  String subscriptionId;
  SubscriptionLevel? level;
  Price? price;
  SubscriptionStatus? status;
  DateTime? startDate;
  DateTime? renewalDate;   // Optional renewal date
  bool autoRenew;          // Indicates if the subscription auto-renews
  String? userId;          // Optional user identifier
  String? paymentMethodId; // Optional payment method identifier
  DateTime? endDate;       //End date or CancellationDate
  CancellationReason? endReason; // Reason for cancellation, if applicable

  UserSubscription({
    this.subscriptionId = '',
    this.level,
    this.price,
    this.status,
    this.startDate,
    this.endDate,
    this.renewalDate,
    this.autoRenew = true,
    this.userId,
    this.paymentMethodId,
  });

  Map<String, dynamic> toJSON() {
    return <String, dynamic>{
      'subscriptionId': subscriptionId,
      'level': level?.name,
      'price': price?.toJSON(),
      'status': status?.name,
      'startDate': startDate?.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      'renewalDate': renewalDate?.toIso8601String(),
      'autoRenew': autoRenew,
      'userId': userId,
      'paymentMethodId': paymentMethodId,
    };
  }

  UserSubscription.fromJSON(Map<String, dynamic> data)
      : subscriptionId = data['subscriptionId'],
        level = EnumToString.fromString(SubscriptionLevel.values, data['level'])!,
        price = Price.fromJSON(data['price']),
        status = EnumToString.fromString(SubscriptionStatus.values, data['status'])!,
        startDate = DateTime.parse(data['startDate']),
        endDate = data['endDate'] != null ? DateTime.parse(data['endDate']) : null,
        renewalDate = data['renewalDate'] != null ? DateTime.parse(data['renewalDate']) : null,
        autoRenew = data['autoRenew'] ?? true,
        userId = data['userId'],
        paymentMethodId = data['paymentMethodId'];
}
