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
        createdAt = data['createdAt'] ?? 0;
}
