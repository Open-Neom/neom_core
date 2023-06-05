import 'package:enum_to_string/enum_to_string.dart';

import '../../utils/enums/release_type.dart';
import 'band_fulfillment.dart';
import 'place.dart';
import 'price.dart';

class AppReleaseItem {

  String id;
  String name;
  String description;
  String imgUrl;
  int duration;
  String previewUrl;

  String ownerName;
  String ownerId;
  String ownerImgUrl;

  List<String> appItemIds;
  List<String> genres;
  List<String> instruments;

  String publisher = "";
  int publishedDate;
  Place? place;
  ReleaseType type = ReleaseType.single;

  Price? digitalPrice;
  Price? physicalPrice;
  List<BandFulfillment> bandsFulfillment;
  List<String>? watchingProfiles;
  List<String>? boughtProfiles;

  bool isAvailable;
  bool isPhysical;
  bool isTest;

  @override
  String toString() {
    return 'AppReleaseItem{id: $id, name: $name, description: $description, imgUrl: $imgUrl, duration: $duration, ownerName: $ownerName, ownerId: $ownerId, ownerImgUrl: $ownerImgUrl, appItemIds: $appItemIds, genres: $genres, instruments: $instruments, publisher: $publisher, publishedDate: $publishedDate, type: $type, price: $digitalPrice, bandsFulfillment: $bandsFulfillment, watchedProfiles: $watchingProfiles, boughtProfiles: $boughtProfiles, isAvailable: $isAvailable, isPhysical: $isPhysical, isTest: $isTest}';
  }

  AppReleaseItem({
      this.id = "",
      this.name = "",
      this.ownerName = "",
      this.ownerId = "",
      this.ownerImgUrl = "",
      this.imgUrl = "",
      this.duration = 0,
      this.previewUrl = "",
      this.appItemIds = const [],
      this.genres = const [],
      this.instruments = const [],
      this.description = "",
      this.publishedDate = 0,
      this.digitalPrice,
      this.physicalPrice,
      this.place,
      this.bandsFulfillment = const [],
      this.isPhysical = false,
      this.isAvailable = false,
      this.isTest = false
  });

  AppReleaseItem.fromJSON(data) :
    id = data["id"] ?? "",
    name = data["name"] ?? "",
    description = data["description"] ?? "",
    imgUrl = data["imgUrl"] ?? "",
    duration = data["duration"] ?? 0,
    previewUrl = data["previewUrl"] ?? "",
    ownerName = data["ownerName"] ?? "",
    ownerId = data["ownerId"] ?? "",
    ownerImgUrl = data["ownerImgUrl"] ?? "",
    appItemIds = List.from(data["appItemIds"]?.cast<String>() ?? []),
    genres = List.from(data["genres"]?.cast<String>() ?? []),
    instruments = List.from(data["instruments"]?.cast<String>() ?? []),
    publisher = data["publisher"] ?? "",
    publishedDate = data["publishedDate"] ?? 0,
    type = EnumToString.fromString(ReleaseType.values, data["type"]) ?? ReleaseType.single,
    watchingProfiles = List.from(data["watchingProfiles"]?.cast<String>() ?? []),
    boughtProfiles = List.from(data["boughtProfiles"]?.cast<String>() ?? []),
    digitalPrice = Price.fromJSON(data["digitalPrice"] ?? {}),
    physicalPrice = Price.fromJSON(data["physicalPrice"] ?? {}),
    place =  Place.fromJSON(data["place"] ?? {}),
    bandsFulfillment = data["bandsFulfillment"]?.map<BandFulfillment>((item) {
      return BandFulfillment.fromJSON(item);
    }).toList() ?? [],
    isAvailable = data["isAvailable"] ?? false,
    isPhysical = data["isPhysical"] ?? false,
    isTest = data["isFulfilled"] ?? false;

  Map<String, dynamic>  toJSON() => {
    'id': id,
    'name': name,
    'description': description,
    'imgUrl': imgUrl,
    'duration': duration,
    'previewUrl': previewUrl,
    'ownerName': ownerName,
    'ownerId': ownerId,
    'ownerImgUrl': ownerImgUrl,
    'appItemIds': appItemIds,
    'genres': genres,
    'instruments': instruments,
    'publisher': publisher,
    'publishedDate': publishedDate,
    'type': type.name,
    'watchingProfiles': watchingProfiles,
    'boughtProfiles': boughtProfiles,
    'digitalPrice': digitalPrice?.toJSON() ?? Price().toJSON(),
    'physicalPrice': physicalPrice?.toJSON() ?? Price().toJSON(),
    'place': place?.toJSON() ?? Place().toJSON(),
    'bandsFulfillment': bandsFulfillment.map((bandFulfillment) => bandFulfillment.toJSON()).toList(),
    'isAvailable': isAvailable,
    'isPhysical': isPhysical,
    'isTest': isTest,
  };

}
