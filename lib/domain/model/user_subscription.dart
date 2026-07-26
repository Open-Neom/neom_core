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

  // ── Dunning (kimi, 2026-07-23) ──
  /// Fin del periodo de gracia (ms epoch) tras un pago fallido.
  int? graceUntil;

  /// Número de intentos de cobro fallidos consecutivos.
  int failedAttempts;

  /// True cuando Stripe agotó los reintentos y el downgrade es inminente.
  bool pendingDowngrade;

  /// Detalle del último fallo de pago (reason, message, brand, last4,
  /// invoiceUrl, amount, currency) escrito por el webhook.
  Map<String, dynamic>? lastFailure;

  UserSubscription({
    this.subscriptionId = '',
    this.userId = '',
    this.level,
    this.price,
    this.status,
    this.startDate = 0,
    this.endDate = 0,
    this.endReason,
    this.graceUntil,
    this.failedAttempts = 0,
    this.pendingDowngrade = false,
    this.lastFailure,
    // this.renewalDate,
    // this.autoRenew = true,
    // this.paymentMethodId,

  });

  // ── Getters de dunning (kimi, 2026-07-23) ──

  /// True cuando el último pago falló (status 'past_due').
  bool get isPastDue => status == SubscriptionStatus.pastDue;

  /// True si está en periodo de gracia: past_due y aún dentro de la
  /// ventana — el acceso/tier debe seguir tratándose como ACTIVO.
  bool get isInGracePeriod =>
      isPastDue &&
      (graceUntil ?? 0) > DateTime.now().millisecondsSinceEpoch;

  /// Días de gracia restantes (redondeo hacia arriba; 0 si no aplica).
  int get graceDaysRemaining {
    if (!isInGracePeriod) return 0;
    final msLeft =
        graceUntil! - DateTime.now().millisecondsSinceEpoch;
    return (msLeft / (24 * 3600 * 1000)).ceil();
  }

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
      'graceUntil': graceUntil,
      'failedAttempts': failedAttempts,
      'pendingDowngrade': pendingDowngrade,
      'lastFailure': lastFailure,
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
        // El webhook escribe 'past_due' (snake_case); se mapea al enum.
        status = data['status'] == 'past_due'
            ? SubscriptionStatus.pastDue
            : data['status'] != null
                ? EnumToString.fromString(SubscriptionStatus.values, data['status'])
                : null,
        startDate = data['startDate'] ?? 0,
        endDate = data['endDate'] ?? 0,
        endReason = data['endReason'] != null ? EnumToString.fromString(CancellationReason.values, data['endReason']) : null,
        graceUntil = data['graceUntil'],
        failedAttempts = data['failedAttempts'] ?? 0,
        pendingDowngrade = data['pendingDowngrade'] ?? false,
        lastFailure = data['lastFailure'] != null
            ? Map<String, dynamic>.from(data['lastFailure'])
            : null;
        // renewalDate = data['renewalDate'] != null ? DateTime.parse(data['renewalDate']) : null,
        // autoRenew = data['autoRenew'] ?? true,
        // paymentMethodId = data['paymentMethodId'];
}
