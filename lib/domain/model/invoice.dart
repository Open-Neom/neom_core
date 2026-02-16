import 'address.dart';
import 'app_transaction.dart';
import 'app_user.dart';

class Invoice {

  String id;
  String description;
  AppUser toUser = AppUser();
  String orderId;
  int createdTime;
  AppTransaction? transaction;
  Address? address;

  Invoice({
    this.id = "",
    this.description = "",
    this.orderId = "",
    this.createdTime = 0,
    this.transaction,
  });

  Map<String, dynamic> toJSON() {
    return <String, dynamic>{
      //'id': id, ///NOT IN USE WITH FIREBASE
      'description': description,
      'toUser': toUser.toInvoiceJSON(),
      'orderId': orderId,
      'createdTime': createdTime,
      'transaction': transaction?.toJSON(),
      'address': address?.toJSON(),
    };
  }

  Invoice.fromJSON(dynamic data) :
    id = data["id"] ?? "",
    description = data["description"] ?? "",
    toUser = AppUser.fromJSON(data["toUser"]),
    orderId = data["orderId"] ?? "",
    createdTime = data["createdTime"] ?? 0,
    transaction = AppTransaction.fromJSON(data["transaction"]),
    address = Address.fromJSON(data["address"]);

}
