import 'package:enum_to_string/enum_to_string.dart';

import '../../utils/enums/app_item_size.dart';
import '../../utils/enums/app_item_type.dart';
import 'genre.dart';

class AppPhysicalItem {

  String id;
  String name;
  String imgUrl;
  String description = "";
  String ownerId;
  String ownerName;
  String ownerImgUrl;
  int duration;
  String previewUrl;
  AppItemSize size;
  AppItemType type;
  List<Genre> genres;
  String publisher = "";
  String publishedDate = "";

  AppPhysicalItem({
    this.id = "",
    this.name = "",
    this.imgUrl = "",
    this.description = "",
    this.ownerId = "",
    this.ownerName = "",
    this.ownerImgUrl = "",
    this.duration = 0,
    this.previewUrl = "",
    this.size = AppItemSize.halfLetter,
    this.type = AppItemType.a,
    this.genres = const [],
    this.publisher = "",
    this.publishedDate = "",
  });

  @override
  String toString() {
    return 'AppPhysicalItem{id: $id, name: $name, imgUrl: $imgUrl, description: $description, ownerId: $ownerId, ownerName: $ownerName, ownerImgUrl: $ownerImgUrl, duration: $duration, previewUrl: $previewUrl, size: $size, genres: $genres, publisher: $publisher, publishedDate: $publishedDate}';
  }

  AppPhysicalItem.fromJSON(dynamic data) :
    id = data["id"] ?? "",
    name = data["name"] ?? "",
    imgUrl = data["imgUrl"] ?? "",
    description = data["description"] ?? "",
    ownerId = data["ownerId"] ?? "",
    ownerName = data["ownerName"] ?? "",
    ownerImgUrl = data["ownerImgUrl"] ?? "",
    duration = data["duration"] ?? 0,
    previewUrl = data["previewUrl"] ?? "",
    size = EnumToString.fromString(AppItemSize.values, data["size"] ?? AppItemSize.letter) ?? AppItemSize.letter,
    type = EnumToString.fromString(AppItemType.values, data["type"] ?? AppItemType.a) ?? AppItemType.a,
    genres = List<Genre>.from(data["genres"].map((model)=> Genre.fromJson(model))),
    publisher = data["publisher"] ?? "",
    publishedDate = data["publishedDate"] ?? "";

  Map<String, dynamic>  toJSON()=>{
    'id': id,
    'name': name,
    'description': description,
    'imgUrl': imgUrl,
    'ownerId': ownerId,
    'ownerName': ownerName,
    'ownerImgUrl': ownerImgUrl,
    'duration': duration,
    'previewUrl': previewUrl,
    'size': size.name,
    'type': type.name,
    'genres': genres.map((genre) => genre.toJSON()).toList(),
    'publisher': publisher,
    'publishedDate': publishedDate
  };

}
