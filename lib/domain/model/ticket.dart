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
  int checkInDate;

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
    this.checkInDate = 0,
  });

  Ticket.fromJSON(dynamic data)
      : id = data['id'] ?? '',
        eventId = data['eventId'] ?? '',
        eventName = data['eventName'] ?? '',
        buyerProfileId = data['buyerProfileId'] ?? '',
        buyerName = data['buyerName'] ?? '',
        purchaseDate = data['purchaseDate'] ?? 0,
        paymentTransactionId = data['paymentTransactionId'] ?? '',
        pricePaid = data['pricePaid'] != null ? Price.fromJSON(data['pricePaid']) : null,
        checkedIn = data['checkedIn'] ?? false,
        checkInDate = data['checkInDate'] ?? 0;

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
        'checkInDate': checkInDate,
      };
}
