
import 'package:enum_to_string/enum_to_string.dart';

import '../../../utils/enums/subscription_level.dart';

class NupaleSession {

  String id; ///createdTime in milisecondsSinceEpoch as id
  String itemId; /// ID del libro
  String itemName; /// Título del libro
  String ownerEmail; ///EMAIL OF OWNER
  String readerEmail; ///EMAIL OF READER

  Map<int, int> pagesDuration;
  int nupale; ///REAL Number of Pages Read
  int createdTime; ///CREATED SESSION TIME IN MILISECONDSSINCEEPOCH
  int totalPages; /// TOTAL PAGES IN THE ITEM

  SubscriptionLevel? subscriptionLevel;
  bool isTest;

  @override
  String toString() {
    return 'NupaleSession{id: $id, itemId: $itemId, itemName: $itemName, ownerEmail: $ownerEmail, readerEmail: $readerEmail, pagesDuration: $pagesDuration, nupale: $nupale, createdTime: $createdTime, subscriptionLevel: $subscriptionLevel, isTest: $isTest}';
  }

  NupaleSession({
    this.id = '',
    this.itemId = '',
    this.itemName = '',
    this.ownerEmail = '',
    this.readerEmail = '',
    this.pagesDuration = const {},
    this.nupale = 0,
    this.createdTime = 0,
    this.totalPages = 0,
    this.subscriptionLevel,
    this.isTest = false,
  });

  /// Convert the NupaleSession object to a JSON map.
  Map<String, dynamic> toJSON() {
    return {
      'id': id,
      'itemId': itemId,
      'itemName': itemName,
      'ownerEmail': ownerEmail,
      'readerEmail': readerEmail,
      'pagesDuration': pagesDuration.map((key, value) => MapEntry(key.toString(), value)),
      'nupale': nupale,
      'createdTime': createdTime,
      'totalPages': totalPages,
      'subscriptionLevel': subscriptionLevel?.name,
      'isTest': isTest,
    };
  }

  /// Create a NupaleSession object from a JSON map.
  factory NupaleSession.fromJSON(dynamic json) {
    return NupaleSession(
      id: json['id'] ?? '',
      itemId: json['itemId'] ?? '',
      itemName: json['itemName'] ?? '',
      ownerEmail: json['ownerEmail'] ?? json['ownerId'] ?? '',
      readerEmail: json['readerEmail'] ?? json['readerId'] ?? '',
      pagesDuration: (json['pagesDuration'] != null)
          ? (json['pagesDuration'] as Map).map((key, value) => MapEntry(int.parse(key), value))
          : {},
      nupale: json['nupale'] ?? 0,
      createdTime: json['createdTime'] ?? 0,
      totalPages: json['totalPages'] ?? 0,
      subscriptionLevel: EnumToString.fromString(SubscriptionLevel.values, json["subscriptionLevel"].toString()),
      isTest: json['isTest'] ?? false,
    );
  }

}
