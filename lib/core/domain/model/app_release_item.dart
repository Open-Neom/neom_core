import 'package:enum_to_string/enum_to_string.dart';
import '../../utils/enums/owner_type.dart';
import '../../utils/enums/release_type.dart';
import 'place.dart';
import 'price.dart';

class AppReleaseItem {

  String id;
  String name;
  String description;
  
  String ownerId;
  String ownerName;
  String ownerImgUrl;
  OwnerType ownerType;
  
  String lyrics;
  String language;
  String metaName; ///itemlistName
  String metaId; ///itemlistId
  String metaOwnerId; ///UserId used to upload item

  String imgUrl; ///Cover image
  int duration; ///Seconds
  String previewUrl; ///Url with file
  
  List<String> appMediaItemIds;
  List<String> genres;
  List<String> instruments;

  String publisher;
  int publishedYear;
  Place? place;
  ReleaseType type;

  Price? digitalPrice;
  Price? physicalPrice;
  List<String>? watchingProfiles;
  List<String>? boughtUsers;
  // List<BandFulfillment> bandsFulfillment;

  int createdTime;
  bool isAvailable;
  bool isPhysical;
  bool isTest;
  int state;

  List<String>? externalArtists; ///Out of the app
  Map<String, String>? featInternalArtists; ///key: artistId - value: name
  int likes;


  @override
  String toString() {
    return 'AppReleaseItem{id: $id, name: $name, description: $description, ownerId: $ownerId, ownerName: $ownerName, ownerImgUrl: $ownerImgUrl, ownerType: $ownerType, lyrics: $lyrics, language: $language, metaName: $metaName, metaId: $metaId, metaOwnerId: $metaOwnerId, imgUrl: $imgUrl, duration: $duration, previewUrl: $previewUrl, appMediaItemIds: $appMediaItemIds, genres: $genres, instruments: $instruments, publisher: $publisher, publishedYear: $publishedYear, place: $place, type: $type, digitalPrice: $digitalPrice, physicalPrice: $physicalPrice, watchingProfiles: $watchingProfiles, boughtUsers: $boughtUsers, createdTime: $createdTime, isAvailable: $isAvailable, isPhysical: $isPhysical, isTest: $isTest, state: $state, externalArtists: $externalArtists, featInternalArtists: $featInternalArtists, likes: $likes}';
  }


  AppReleaseItem({
      this.id = '',
      this.name = '',
      this.lyrics = '',
      this.language = '',
      this.ownerName = '',
      this.ownerId = '',
      this.ownerImgUrl = '',
      this.ownerType = OwnerType.profile,
      this.metaName = '',
      this.metaId = '',
      this.metaOwnerId = '',
      this.publisher = '',
      this.imgUrl = '',
      this.duration = 0,
      this.previewUrl = '',
      this.appMediaItemIds = const [],
      this.genres = const [],
      this.instruments = const [],
      this.description = '',
      this.publishedYear = 0,
      this.digitalPrice,
      this.physicalPrice,
      this.place,
      this.isPhysical = false,
      this.isAvailable = false,
      this.isTest = false,
      this.state = 0,
      this.createdTime = 0,
      this.externalArtists,
      this.featInternalArtists,
      this.likes = 0,
      this.type = ReleaseType.single,
      this.boughtUsers,
      this.watchingProfiles,
  });

  AppReleaseItem.fromJSON(data) :
    id = data["id"] ?? '',
    name = data["name"] ?? '',
    description = data["description"] ?? '',
    imgUrl = data["imgUrl"] ?? '',
    duration = data["duration"] ?? 0,
    previewUrl = data["previewUrl"] ?? '',
    language = data["language"] ?? '',
    lyrics = data["lyrics"] ?? '',
    ownerName = data["ownerName"] ?? '',
    ownerId = data["ownerId"] ?? '',
    ownerImgUrl = data["ownerImgUrl"] ?? '',
    ownerType = EnumToString.fromString(OwnerType.values, data["ownerType"] ?? OwnerType.profile.name) ?? OwnerType.profile,
    metaName = data["metaName"] ?? '',
    metaId = data["metaId"] ?? '',
    metaOwnerId = data["metaOwnerId"] ?? '',
    appMediaItemIds = List.from(data["appMediaItemIds"]?.cast<String>() ?? []),
    genres = List.from(data["genres"]?.cast<String>() ?? []),
    instruments = List.from(data["instruments"]?.cast<String>() ?? []),
    publisher = data["publisher"] ?? '',
    publishedYear = data["publishedYear"] ?? 0,
    type = EnumToString.fromString(ReleaseType.values, data["type"] ?? ReleaseType.single.name) ?? ReleaseType.single,
    watchingProfiles = List.from(data["watchingProfiles"]?.cast<String>() ?? []),
    boughtUsers = List.from(data["boughtUsers"]?.cast<String>() ?? []),
    digitalPrice = Price.fromJSON(data["digitalPrice"] ?? {}),
    physicalPrice = Price.fromJSON(data["physicalPrice"] ?? {}),
    place =  Place.fromJSON(data["place"] ?? {}),
    isAvailable = data["isAvailable"] ?? false,
    isPhysical = data["isPhysical"] ?? false,
    isTest = data["isTest"] ?? false,
    state = data["state"] ?? 1,
    createdTime = data["createdTime"] ?? 0,
    externalArtists = List.from(data["externalArtists"]?.cast<String>() ?? []),
    featInternalArtists = data["featInternalArtists"] as Map<String,String>?,
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
    'ownerName': ownerName,
    'ownerId': ownerId,
    'ownerImgUrl': ownerImgUrl,
    'ownerType': ownerType.name,
    'metaName': metaName,
    'metaId': metaId,
    'metaOwnerId': metaOwnerId,
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
    'isAvailable': isAvailable,
    'isPhysical': isPhysical,
    'isTest': isTest,
    'externalArtists': externalArtists,
    'featInternalArtists': featInternalArtists,
    'state': state,
    'likes': likes,
  };

}
