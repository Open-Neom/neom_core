import 'package:enum_to_string/enum_to_string.dart';

import '../../app_config.dart';
import '../../utils/enums/external_media_source.dart';
import '../../utils/enums/media_item_type.dart';

class ExternalItem {
  
  String id;
  String name;
  String? description;
  String ownerName;
  String? ownerId;
  String album;
  String? albumId;
  int duration;

  List<String>? externalArtists;

  List<String>? categories;
  String lyrics;  
  String? language;
  
  String imgUrl;
  List<String>? galleryUrls;

  String? metaOwner;
  int? publishedYear; ///YEAR RELEASE TO PUBLIC
  int releaseDate;

  String url; ///URL FOR STREAMING PURPOSE
  String? path; ///IN CASE IS OFFLINE

  String permaUrl; ///URL FOR EXTERNAL USE
  List<String>? allUrls; ///ADDITIONAL URLS FOR QUALITIES

  int? trackNumber;
  int? discNumber;

  int? quality; ///TO DEFINE QUALITY 0-1-2-3-4-5 ...
  bool is320Kbps;
  int likes;
  int state; ///STATE FOR USERS WHEN THE SAVE ITEM ON ITEMLISTS - FROM O to 5
  MediaItemType? type;

  ExternalSource source;

  ExternalItem({
    this.id = '',
    this.album = '',
    this.albumId,
    this.ownerName = '',
    this.ownerId,
    this.externalArtists,
    this.duration = 0,
    this.categories,
    this.imgUrl = '',
    this.galleryUrls,
    this.language,
    this.description,
    this.name = '',
    this.url = '',
    this.allUrls,
    this.metaOwner,
    this.publishedYear, ///YEAR
    this.quality,
    this.permaUrl = '',
    this.releaseDate = 0,
    this.lyrics = '',
    this.trackNumber,
    this.discNumber,
    this.source = ExternalSource.unknown,
    this.is320Kbps = false,
    this.likes = 0,
    this.path,
    this.type,
    this.state = 0,
  });

  @override
  String toString() {
    return 'ExternalItem{id: $id, name: $name, description: $description, ownerName: $ownerName, ownerId: $ownerId, album: $album, albumId: $albumId, duration: $duration, externalArtists: $externalArtists, categories: $categories, lyrics: $lyrics, language: $language, imgUrl: $imgUrl, galleryUrls: $galleryUrls, metaOwner: $metaOwner, publishedYear: $publishedYear, releaseDate: $releaseDate, url: $url, path: $path, permaUrl: $permaUrl, allUrls: $allUrls, trackNumber: $trackNumber, discNumber: $discNumber, quality: $quality, is320Kbps: $is320Kbps, likes: $likes, state: $state, type: $type, source: $source';
  }

  factory ExternalItem.fromJSON(map) {
    try {
      AppConfig.logger.t("ExternalItem fromJSON: ${map['name'] ?? ''} with id ${map['id'] ?? ''}");
      int dur = 30;

      if(map['duration'] is String && map['duration'].toString().contains(":")) {
        final List<String> parts = map['duration'].toString().split(':');
        for (int i = 0; i < parts.length; i++) {
          dur += int.parse(parts[i]) * (60 ^ (parts.length - i - 1));
        }
      } else if(map['duration'] is int) {
        dur = map['duration'];
      }

      final externalItem = ExternalItem(
        id: map['id'] ?? '',
        type: EnumToString.fromString(MediaItemType.values, map['type'].toString()) ?? MediaItemType.song,
        album: map['album'] ?? '',
        publishedYear: map['publishedYear'] ?? 0,
        duration: dur,
        language: map['language'] ?? '',
        is320Kbps: map['is320Kbps'] ?? false,
        lyrics: map['lyrics'] ?? '',
        albumId: map['albumId'] ?? '',
        description: map['description'] ?? '',
        name: map['name'] ?? '',
        ownerName: map['ownerName'] ?? '',
        externalArtists: (map['externalArtists'] as List<dynamic>?)?.map((e) => e.toString()).toList(),
        imgUrl: map['imgUrl'] ?? '',
        galleryUrls: (map['galleryUrls'] as List<dynamic>?)?.map((e) => e.toString()).toList(),
        url: map['url']?.toString() ?? '',
        permaUrl: map['permaUrl'] ?? '',
        allUrls: (map['allUrls'] as List<dynamic>?)?.map((e) => e.toString()).toList(),
        quality: int.tryParse(map['quality'].toString()),
        releaseDate: map['releaseDate'] ?? 0,
        trackNumber: map['trackNumber'],
        discNumber: map['discNumber'],
        source: EnumToString.fromString(ExternalSource.values, map["source"] ?? ExternalSource.unknown.name) ?? ExternalSource.unknown,
        likes: map['likes'] ?? 0,
        path: map['path'] ?? '',
        state: map['state'] ?? 0,
      );
      return externalItem;
    } catch (e) {
      AppConfig.logger.e(e.toString());
      throw Exception('Error parsing song item: $e');
    }
  }

  Map<String, dynamic> toJSON() {
    return <String, dynamic>{
      'id': id,
      'album': album,
      'duration': duration,
      'categories': categories,
      'imgUrl': imgUrl,
      'galleryUrls': galleryUrls,
      'language': language,
      'releaseDate': releaseDate,
      'description': description,
      'name': name,
      'url': url,
      'allUrls': allUrls,
      'publishedYear': publishedYear,
      'quality': quality,
      'permaUrl': permaUrl,
      'lyrics': lyrics,
      'trackNumber': trackNumber,
      'discNumber': discNumber,
      'albumId': albumId,
      'externalArtists': externalArtists,
      'source': source.name,
      'is320Kbps': is320Kbps,
      'ownerName': ownerName,
      'ownerId': ownerId,
      'likes': likes,
      'path': path,
      'state': state,
      'type': type?.value,
    };
  }

}
