/// Tracks billing/collection events for the ERP cobranza system.
/// Stored in Firestore `collectionEvents` collection.
/// Created by Cloud Functions (webhook handlers + checkOverduePayments).
class CollectionEvent {

  String id;
  String userId;
  String userEmail;
  String userName;
  String userPhone;
  String type;                   // 'payment_failed', 'reminder_sent', 'suspended', 'reactivated'
  String invoiceId;
  String subscriptionId;
  double amount;
  String currency;
  int attemptNumber;
  bool whatsappSent;
  String whatsappMessageId;
  int escalationLevel;           // 1, 2, 3, or 4 (suspended)
  int createdAt;

  CollectionEvent({
    this.id = '',
    this.userId = '',
    this.userEmail = '',
    this.userName = '',
    this.userPhone = '',
    this.type = '',
    this.invoiceId = '',
    this.subscriptionId = '',
    this.amount = 0.0,
    this.currency = 'MXN',
    this.attemptNumber = 0,
    this.whatsappSent = false,
    this.whatsappMessageId = '',
    this.escalationLevel = 1,
    this.createdAt = 0,
  });

  Map<String, dynamic> toJSON() {
    return <String, dynamic>{
      'id': id,
      'userId': userId,
      'userEmail': userEmail,
      'userName': userName,
      'userPhone': userPhone,
      'type': type,
      'invoiceId': invoiceId,
      'subscriptionId': subscriptionId,
      'amount': amount,
      'currency': currency,
      'attemptNumber': attemptNumber,
      'whatsappSent': whatsappSent,
      'whatsappMessageId': whatsappMessageId,
      'escalationLevel': escalationLevel,
      'createdAt': createdAt,
    };
  }

  CollectionEvent.fromJSON(Map<String, dynamic> data)
      : id = data['id'] ?? '',
        userId = data['userId'] ?? '',
        userEmail = data['userEmail'] ?? '',
        userName = data['userName'] ?? '',
        userPhone = data['userPhone'] ?? '',
        type = data['type'] ?? '',
        invoiceId = data['invoiceId'] ?? '',
        subscriptionId = data['subscriptionId'] ?? '',
        amount = (data['amount'] ?? 0).toDouble(),
        currency = data['currency'] ?? 'MXN',
        attemptNumber = data['attemptNumber'] ?? 0,
        whatsappSent = data['whatsappSent'] ?? false,
        whatsappMessageId = data['whatsappMessageId'] ?? '',
        escalationLevel = data['escalationLevel'] ?? 1,
        createdAt = data['createdAt'] ?? 0;

  /// Human-readable type label
  String get typeLabel {
    switch (type) {
      case 'payment_failed': return 'Pago Fallido';
      case 'reminder_sent': return 'Recordatorio Enviado';
      case 'suspended': return 'Suspendido';
      case 'reactivated': return 'Reactivado';
      default: return type;
    }
  }

  /// Escalation level label
  String get escalationLabel {
    switch (escalationLevel) {
      case 1: return 'Aviso 1 — Amigable';
      case 2: return 'Aviso 2 — Recordatorio';
      case 3: return 'Aviso 3 — Última Oportunidad';
      case 4: return 'Suspendido';
      default: return 'Nivel $escalationLevel';
    }
  }
}
