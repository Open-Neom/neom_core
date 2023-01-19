import 'package:cloud_firestore/cloud_firestore.dart';

class AppInfo {

  String id;
  String version;
  bool coinPromo;
  double coinAmount;
  bool fbLoginEnabled;
  int orderNumber;


  AppInfo({
    this.id = "",
    this.version = "",
    this.coinPromo = true,
    this.fbLoginEnabled = false,
    this.coinAmount = 10.00,
    this.orderNumber = 1
  });


  @override
  String toString() {
    return 'AppInfo{id: $id, version: $version, coinPromo: $coinPromo, coinAmount: $coinAmount, fbLoginEnabled: $fbLoginEnabled, orderNumber: $orderNumber}';
  }

  AppInfo.fromDocumentSnapshot(DocumentSnapshot documentSnapshot):
    id = documentSnapshot.id,
    version = documentSnapshot.get("version") ?? "",
    coinPromo = documentSnapshot.get("coinPromo") ?? true,
    coinAmount = double.parse(documentSnapshot.get("coinAmount").toString()),
    fbLoginEnabled = documentSnapshot.get("fbLoginEnabled") ?? false,
    orderNumber = documentSnapshot.get("orderNumber") ?? 1;


  Map<String, dynamic> toJSON() {
    return <String, dynamic> {
      'version': version,
      'coinPromo': coinPromo,
      'coinAmount': coinAmount,
      'fbLoginEnabled': fbLoginEnabled,
    };
  }

}
