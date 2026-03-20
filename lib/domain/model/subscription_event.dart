/// Tracks Stripe webhook events with EMXI business-language translation.
/// Stored in Firestore `subscriptionEvents` collection.
/// Used to power the ERP alert feed for COO/CEO.
class SubscriptionEvent {

  String id;
  String subscriptionId;
  String userId;
  String userName;               // display name for alerts
  String stripeEventType;        // e.g. "invoice.payment_failed"
  String emxiStatus;             // e.g. "Fricción de Pago"
  String emxiStatusColor;        // "green", "red", "yellow", "blue", "grey"
  String planName;               // "Artista", "Premium", etc.
  bool alertCOO;
  bool alertCEO;
  Map<String, dynamic> metadata;
  int createdAt;

  // ── v2: Enriched Stripe data ──
  double amount;                 // Monto del cobro/invoice (en moneda local, ya dividido /100)
  String currency;               // MXN, USD, etc.
  double stripeFees;             // Comisión Stripe
  double stripeNet;              // Monto neto después de fees
  String invoiceId;              // Stripe invoice ID
  String invoiceUrl;             // URL del PDF de factura Stripe
  String chargeId;               // Stripe charge ID
  String paymentMethodBrand;     // Visa, Mastercard, Amex, etc.
  String paymentMethodLast4;     // Últimos 4 dígitos de la tarjeta
  String failureReason;          // card_declined, insufficient_funds, expired_card, etc.
  String failureMessage;         // Mensaje legible del error
  int currentPeriodEnd;          // Fin del periodo actual (ms) — para predecir renovación
  bool cancelAtPeriodEnd;        // Si el usuario programó cancelación
  String customerEmail;          // Email del customer de Stripe
  String couponId;               // Código de cupón si hay descuento activo
  double discountPercent;        // % de descuento aplicado

  SubscriptionEvent({
    this.id = '',
    this.subscriptionId = '',
    this.userId = '',
    this.userName = '',
    this.stripeEventType = '',
    this.emxiStatus = '',
    this.emxiStatusColor = 'grey',
    this.planName = '',
    this.alertCOO = false,
    this.alertCEO = false,
    this.metadata = const {},
    this.createdAt = 0,
    // v2
    this.amount = 0,
    this.currency = '',
    this.stripeFees = 0,
    this.stripeNet = 0,
    this.invoiceId = '',
    this.invoiceUrl = '',
    this.chargeId = '',
    this.paymentMethodBrand = '',
    this.paymentMethodLast4 = '',
    this.failureReason = '',
    this.failureMessage = '',
    this.currentPeriodEnd = 0,
    this.cancelAtPeriodEnd = false,
    this.customerEmail = '',
    this.couponId = '',
    this.discountPercent = 0,
  });

  Map<String, dynamic> toJSON() {
    return <String, dynamic>{
      'id': id,
      'subscriptionId': subscriptionId,
      'userId': userId,
      'userName': userName,
      'stripeEventType': stripeEventType,
      'emxiStatus': emxiStatus,
      'emxiStatusColor': emxiStatusColor,
      'planName': planName,
      'alertCOO': alertCOO,
      'alertCEO': alertCEO,
      'metadata': metadata,
      'createdAt': createdAt,
      // v2
      'amount': amount,
      'currency': currency,
      'stripeFees': stripeFees,
      'stripeNet': stripeNet,
      'invoiceId': invoiceId,
      'invoiceUrl': invoiceUrl,
      'chargeId': chargeId,
      'paymentMethodBrand': paymentMethodBrand,
      'paymentMethodLast4': paymentMethodLast4,
      'failureReason': failureReason,
      'failureMessage': failureMessage,
      'currentPeriodEnd': currentPeriodEnd,
      'cancelAtPeriodEnd': cancelAtPeriodEnd,
      'customerEmail': customerEmail,
      'couponId': couponId,
      'discountPercent': discountPercent,
    };
  }

  SubscriptionEvent.fromJSON(Map<String, dynamic> data)
      : id = data['id'] ?? '',
        subscriptionId = data['subscriptionId'] ?? '',
        userId = data['userId'] ?? '',
        userName = data['userName'] ?? '',
        stripeEventType = data['stripeEventType'] ?? '',
        emxiStatus = data['emxiStatus'] ?? '',
        emxiStatusColor = data['emxiStatusColor'] ?? 'grey',
        planName = data['planName'] ?? '',
        alertCOO = data['alertCOO'] ?? false,
        alertCEO = data['alertCEO'] ?? false,
        metadata = Map<String, dynamic>.from(data['metadata'] ?? {}),
        createdAt = data['createdAt'] ?? 0,
        // v2
        amount = (data['amount'] ?? 0).toDouble(),
        currency = data['currency'] ?? '',
        stripeFees = (data['stripeFees'] ?? 0).toDouble(),
        stripeNet = (data['stripeNet'] ?? 0).toDouble(),
        invoiceId = data['invoiceId'] ?? '',
        invoiceUrl = data['invoiceUrl'] ?? '',
        chargeId = data['chargeId'] ?? '',
        paymentMethodBrand = data['paymentMethodBrand'] ?? '',
        paymentMethodLast4 = data['paymentMethodLast4'] ?? '',
        failureReason = data['failureReason'] ?? '',
        failureMessage = data['failureMessage'] ?? '',
        currentPeriodEnd = data['currentPeriodEnd'] ?? 0,
        cancelAtPeriodEnd = data['cancelAtPeriodEnd'] ?? false,
        customerEmail = data['customerEmail'] ?? '',
        couponId = data['couponId'] ?? '',
        discountPercent = (data['discountPercent'] ?? 0).toDouble();

  // ── Computed getters ──

  /// Whether this event has financial data attached.
  bool get hasFinancialData => amount > 0;

  /// Formatted payment method (e.g. "Visa ****1234")
  String get paymentMethodDisplay =>
      paymentMethodBrand.isNotEmpty && paymentMethodLast4.isNotEmpty
          ? '$paymentMethodBrand ****$paymentMethodLast4'
          : '';

  /// Whether the subscription is scheduled to cancel.
  bool get isScheduledToCancel => cancelAtPeriodEnd && currentPeriodEnd > 0;

  /// Stripe fee percentage (approximate).
  double get stripeFeePercent => amount > 0 ? (stripeFees / amount) * 100 : 0;
}
