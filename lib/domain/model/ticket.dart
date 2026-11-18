import 'price.dart';

class Ticket {
  String id;
  String eventId;
  String eventName;
  String buyerProfileId;
  String buyerName;
  int purchaseDate;
  String paymentTransactionId;
  Price? pricePaid;
  bool checkedIn;
  int checkedInCount;
  int checkInDate;
  String qrToken;
  int quantity;
  String tierName;
  String paymentMethod;
  double paidCoins;

  int get remainingAccesses => (quantity - checkedInCount).clamp(0, quantity);

  Ticket({
    this.id = '',
    this.eventId = '',
    this.eventName = '',
    this.buyerProfileId = '',
    this.buyerName = '',
    this.purchaseDate = 0,
    this.paymentTransactionId = '',
    this.pricePaid,
    this.checkedIn = false,
    this.checkedInCount = 0,
    this.checkInDate = 0,
    this.qrToken = '',
    this.quantity = 1,
    this.tierName = 'General',
    this.paymentMethod = '',
    this.paidCoins = 0.0,
  });

  Ticket.fromJSON(dynamic data)
      : id = (data['id'] ?? '').toString(),
        eventId = (data['eventId'] ?? '').toString(),
        eventName = (data['eventName'] ?? '').toString(),
        buyerProfileId = (data['buyerProfileId'] ?? '').toString(),
        buyerName = (data['buyerName'] ?? '').toString(),
        purchaseDate = (data['purchaseDate'] ?? data['createdTime'] ?? 0) is num
            ? ((data['purchaseDate'] ?? data['createdTime'] ?? 0) as num).toInt()
            : 0,
        paymentTransactionId = (data['paymentTransactionId'] ?? '').toString(),
        pricePaid = data['pricePaid'] != null
            ? Price.fromJSON(data['pricePaid'])
            : (data['price'] != null ? Price.fromJSON(data['price']) : null),
        checkedIn = data['checkedIn'] == true,
        checkedInCount = (data['checkedInCount'] is num)
            ? (data['checkedInCount'] as num).toInt()
            : (data['checkedIn'] == true
                ? ((data['quantity'] is num) ? (data['quantity'] as num).toInt() : 1)
                : 0),
        checkInDate = (data['checkInDate'] ?? data['checkedInTime'] ?? 0) is num
            ? ((data['checkInDate'] ?? data['checkedInTime'] ?? 0) as num).toInt()
            : 0,
        qrToken = (data['qrToken'] ?? '').toString(),
        quantity = (data['quantity'] is num)
            ? (data['quantity'] as num).toInt()
            : 1,
        tierName = (data['tierName'] ?? 'General').toString(),
        paymentMethod = (data['paymentMethod'] ?? '').toString(),
        paidCoins = (data['paidCoins'] is num)
            ? (data['paidCoins'] as num).toDouble()
            : 0.0;

  Map<String, dynamic> toJSON() => {
        'id': id,
        'eventId': eventId,
        'eventName': eventName,
        'buyerProfileId': buyerProfileId,
        'buyerName': buyerName,
        'purchaseDate': purchaseDate,
        'paymentTransactionId': paymentTransactionId,
        'pricePaid': pricePaid?.toJSON(),
        'checkedIn': checkedIn,
        'checkedInCount': checkedInCount,
        'checkInDate': checkInDate,
        'qrToken': qrToken,
        'quantity': quantity,
        'tierName': tierName,
        'paymentMethod': paymentMethod,
        'paidCoins': paidCoins,
      };
}
