
class NupaleSession {

  String id; ///createdTime in milisecondsSinceEpoch as id
  String itemId; /// ID del libro
  String itemName; /// Título del libro
  String ownerId; ///USERID OR EMAIL OF OWNER
  String readerId; ///PROFILEID OF READER

  Map<int, int> pagesDuration;
  int nupale; ///REAL Number of Pages Read
  int createdTime; ///CREATED SESSION TIME IN MILISECONDSSINCEEPOCH

  bool isInternalArtist;
  bool isFreemium;
  bool isTest;

  @override
  String toString() {
    return 'NupaleSession{id: $id, itemId: $itemId, itemName: $itemName, '
        'ownerId: $ownerId, readerId: $readerId, pages: $pagesDuration, '
        'nupale: $nupale, createdTime: $createdTime, '
        'isInternalArtist: $isInternalArtist, isFreemium: $isFreemium, isTest: $isTest}';
  }

  NupaleSession({
    this.id = '',
    this.itemId = '',
    this.itemName = '',
    this.ownerId = '',
    this.readerId = '',
    this.pagesDuration = const {},
    this.nupale = 0,
    this.createdTime = 0,
    this.isInternalArtist = false,
    this.isFreemium = true,
    this.isTest = false,
  });

  /// Convert the NupaleSession object to a JSON map.
  Map<String, dynamic> toJSON() {
    return {
      'id': id,
      'itemId': itemId,
      'itemName': itemName,
      'ownerId': ownerId,
      'readerId': readerId,
      'pagesDuration': pagesDuration.map((key, value) => MapEntry(key.toString(), value)),
      'nupale': nupale,
      'createdTime': createdTime,
      'isInternalArtist': isInternalArtist,
      'isFreemium': isFreemium,
      'isTest': isTest,
    };
  }

  /// Create a NupaleSession object from a JSON map.
  factory NupaleSession.fromJSON(json) {
    return NupaleSession(
      id: json['id'] ?? '',
      itemId: json['itemId'] ?? '',
      itemName: json['itemName'] ?? '',
      ownerId: json['ownerId'] ?? '',
      readerId: json['readerId'] ?? '',
      pagesDuration: (json['pagesDuration'] != null)
          ? (json['pagesDuration'] as Map).map((key, value) => MapEntry(int.parse(key), value))
          : {},
      nupale: json['nupale'] ?? 0,
      createdTime: json['createdTime'] ?? 0,
      isInternalArtist: json['isInternalArtist'] ?? false,
      isFreemium: json['isFreemium'] ?? true,
      isTest: json['isTest'] ?? false,
    );
  }

}
