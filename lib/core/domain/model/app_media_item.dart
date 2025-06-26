import 'package:enum_to_string/enum_to_string.dart';

import '../../app_config.dart';
import '../../utils/enums/app_media_source.dart';
import '../../utils/enums/media_item_type.dart';

class AppMediaItem {
  
  String id;
  String name;
  String? description;
  String artist;
  String? artistId; ///IF ARTIST IS ON GIGMEOUT
  String album;
  String? albumId; ///IF ALBUM IS ON GIGMEOUT
  int duration; ///DURATION IN SECONDS
  
  Map<String, String>? featInternalArtists; //key: artistId - value: artist name
  List<String>? externalArtists; ///

  List<String>? genres;
  String lyrics;  
  String? language;
  
  String imgUrl;
  List<String>? allImgs;

  String? publisher;
  int? publishedYear; ///YEAR RELEASE TO PUBLIC
  int releaseDate; ///RELEASED AT GIGMEOUT INTERNAL PURPOSES

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
  AppMediaSource mediaSource;

  AppMediaItem({
    this.id = '',
    this.album = '',
    this.albumId,
    this.artist = '',
    this.artistId,
    this.externalArtists,
    this.featInternalArtists,
    this.duration = 0,
    this.genres,
    this.imgUrl = '',
    this.allImgs,
    this.language,
    this.description,
    this.name = '',
    this.url = '',
    this.allUrls,
    this.publisher,
    this.publishedYear, ///YEAR
    this.quality,
    this.permaUrl = '',
    this.releaseDate = 0,
    this.lyrics = '',
    this.trackNumber,
    this.discNumber,
    this.mediaSource = AppMediaSource.internal,
    this.is320Kbps = false,
    this.likes = 0,
    this.path,
    this.type,
    this.state = 0,
  });

  @override
  String toString() {
    return 'AppMediaItem{id: $id, name: $name, description: $description, artist: $artist, artistId: $artistId, album: $album, albumId: $albumId, duration: $duration, featInternalArtists: $featInternalArtists, externalArtists: $externalArtists, genres: $genres, lyrics: $lyrics, language: $language, imgUrl: $imgUrl, allImgs: $allImgs, publisher: $publisher, publishedYear: $publishedYear, releaseDate: $releaseDate, url: $url, path: $path, permaUrl: $permaUrl, allUrls: $allUrls, trackNumber: $trackNumber, discNumber: $discNumber, quality: $quality, is320Kbps: $is320Kbps, likes: $likes, state: $state, type: $type, mediaSource: $mediaSource';
  }

  factory AppMediaItem.fromJSON(map) {
    try {
      AppConfig.logger.t("AppMediaItem fromJSON: ${map['name'] ?? ''} with id ${map['id'] ?? ''}");
      int dur = 30;

      if(map['duration'] is String && map['duration'].toString().contains(":")) {
        final List<String> parts = map['duration'].toString().split(':');
        for (int i = 0; i < parts.length; i++) {
          dur += int.parse(parts[i]) * (60 ^ (parts.length - i - 1));
        }
      } else if(map['duration'] is int) {
        dur = map['duration'];
      }

      final appMediaItem = AppMediaItem(
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
        artist: map['artist'] ?? '',
        featInternalArtists: map['featInternalArtists'] as Map<String, String>?,
        externalArtists: (map['externalArtists'] as List<dynamic>?)?.map((e) => e.toString()).toList(),
        imgUrl: map['imgUrl'] ?? '',
        allImgs: (map['allImgs'] as List<dynamic>?)?.map((e) => e.toString()).toList(),
        url: map['url']?.toString() ?? '',
        permaUrl: map['permaUrl'] ?? '',
        allUrls: (map['allUrls'] as List<dynamic>?)?.map((e) => e.toString()).toList(),
        quality: int.tryParse(map['quality'].toString()),
        releaseDate: map['releaseDate'] ?? 0,
        trackNumber: map['trackNumber'],
        discNumber: map['discNumber'],
        mediaSource: EnumToString.fromString(AppMediaSource.values, map["mediaSource"] ?? AppMediaSource.internal.name) ?? AppMediaSource.internal,
        likes: map['likes'] ?? 0,
        path: map['path'] ?? '',
        state: map['state'] ?? 0,
      );
      return appMediaItem;
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
      'genres': genres,
      'imgUrl': imgUrl,
      'allImgs': allImgs,
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
      'featInternalArtists': featInternalArtists,
      'mediaSource': mediaSource.name,
      'is320Kbps': is320Kbps,
      'artist': artist,
      'artistId': artistId,
      'likes': likes,
      'path': path,
      'state': state,
      'type': type?.value,
    };
  }

}
