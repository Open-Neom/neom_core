import 'package:enum_to_string/enum_to_string.dart';

import '../../utils/enums/release_type.dart';
import 'band_fulfillment.dart';
import 'place.dart';
import 'price.dart';

class AppReleaseItem {

  String id;
  String name;
  String description;
  String ownerName;
  String ownerId;
  String lyrics;
  String language;
  String metaName;
  String metaId;
  
  String imgUrl;
  int duration;
  String previewUrl;
  String ownerImgUrl;

  List<String> appMediaItemIds;
  List<String> genres;
  List<String> instruments;

  String publisher = "";
  int publishedYear;
  Place? place;
  ReleaseType type;

  Price? digitalPrice;
  Price? physicalPrice;
  List<BandFulfillment> bandsFulfillment;
  List<String>? watchingProfiles;
  List<String>? boughtUsers;
  int createdTime;

  bool isAvailable;
  bool isPhysical;
  bool isTest;
  int state;

  List<String>? externalArtists;
  Map<String, String>? featInternalArtists; //key: artist Id - value: name
  int likes;

  @override
  String toString() {
    return 'AppReleaseItem{id: $id, name: $name, description: $description, imgUrl: $imgUrl, duration: $duration, ownerName: $ownerName, ownerId: $ownerId, ownerImgUrl: $ownerImgUrl, appItemIds: $appMediaItemIds, genres: $genres, instruments: $instruments, publisher: $publisher, publishedYear: $publishedYear, type: $type, price: $digitalPrice, bandsFulfillment: $bandsFulfillment, watchedProfiles: $watchingProfiles, boughtProfiles: $boughtUsers, isAvailable: $isAvailable, isPhysical: $isPhysical, isTest: $isTest}';
  }

  AppReleaseItem({
      this.id = "",
      this.name = "",
      this.metaName = "",
      this.metaId = '',
      this.lyrics = '',
      this.language = '',
      this.ownerName = "",
      this.ownerId = "",
      this.ownerImgUrl = "",
      this.imgUrl = "",
      this.duration = 0,
      this.previewUrl = "",
      this.appMediaItemIds = const [],
      this.genres = const [],
      this.instruments = const [],
      this.description = "",
      this.publishedYear = 0,
      this.digitalPrice,
      this.physicalPrice,
      this.place,
      this.bandsFulfillment = const [],
      this.isPhysical = false,
      this.isAvailable = false,
      this.isTest = false,
      this.state = 0,
      this.createdTime = 0,
      this.externalArtists,
      this.featInternalArtists,
      this.likes = 0,
      this.type = ReleaseType.single,
  });

  AppReleaseItem.fromJSON(data) :
    id = data["id"] ?? "",
    name = data["name"] ?? "",
    description = data["description"] ?? "",
    imgUrl = data["imgUrl"] ?? "",
    duration = data["duration"] ?? 0,
    previewUrl = data["previewUrl"] ?? "",
    language = data["language"] ?? "",
    lyrics = data["lyrics"] ?? "",
    metaName = data["metaName"] ?? "",
    metaId = data["metaId"] ?? "",
    ownerName = data["ownerName"] ?? "",
    ownerId = data["ownerId"] ?? "",
    ownerImgUrl = data["ownerImgUrl"] ?? "",
    appMediaItemIds = List.from(data["appMediaItemIds"]?.cast<String>() ?? []),
    genres = List.from(data["genres"]?.cast<String>() ?? []),
    instruments = List.from(data["instruments"]?.cast<String>() ?? []),
    publisher = data["publisher"] ?? "",
    publishedYear = data["publishedYear"] ?? 0,
    type = EnumToString.fromString(ReleaseType.values, data["type"] ?? ReleaseType.single.name) ?? ReleaseType.single,
    watchingProfiles = List.from(data["watchingProfiles"]?.cast<String>() ?? []),
    boughtUsers = List.from(data["boughtUsers"]?.cast<String>() ?? []),
    digitalPrice = Price.fromJSON(data["digitalPrice"] ?? {}),
    physicalPrice = Price.fromJSON(data["physicalPrice"] ?? {}),
    place =  Place.fromJSON(data["place"] ?? {}),
    bandsFulfillment = data["bandsFulfillment"]?.map<BandFulfillment>((item) {
      return BandFulfillment.fromJSON(item);
    }).toList() ?? [],
    isAvailable = data["isAvailable"] ?? false,
    isPhysical = data["isPhysical"] ?? false,
    isTest = data["isFulfilled"] ?? false,
    state = data["state"] ?? 0,
    createdTime = data["createdTime"] ?? 0,
    externalArtists = List.from(data["externalArtists"]?.cast<String>() ?? []),
    featInternalArtists = data["featInternalArtists"]?.cast<Map<String,String>>() ?? [],
    likes = data["likes"] ?? 0;

  Map<String, dynamic>  toJSON() => {
    'id': id,
    'name': name,
    'description': description,
    'imgUrl': imgUrl,
    'duration': duration,
    'previewUrl': previewUrl,
    'lyrics': lyrics,
    'language': language,
    'metaName': metaName,
    'metaId': metaId,
    'ownerName': ownerName,
    'ownerId': ownerId,
    'ownerImgUrl': ownerImgUrl,
    'appMediaItemIds': appMediaItemIds,
    'genres': genres,
    'instruments': instruments,
    'publisher': publisher,
    'publishedYear': publishedYear,
    'type': type.name,
    'watchingProfiles': watchingProfiles,
    'boughtUsers': boughtUsers,
    'digitalPrice': digitalPrice?.toJSON() ?? Price().toJSON(),
    'physicalPrice': physicalPrice?.toJSON() ?? Price().toJSON(),
    'place': place?.toJSON() ?? Place().toJSON(),
    'bandsFulfillment': bandsFulfillment.map((bandFulfillment) => bandFulfillment.toJSON()).toList(),
    'isAvailable': isAvailable,
    'isPhysical': isPhysical,
    'isTest': isTest,
    'externalArtists': externalArtists,
    'featInternalArtists': featInternalArtists,
    'state': state,
    'likes': likes,
  };

}
