import 'package:enum_to_string/enum_to_string.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:spotify/spotify.dart';

import '../../utils/app_utilities.dart';
import '../../utils/enums/app_media_source.dart';
import '../../utils/enums/media_item_type.dart';
import 'app_release_item.dart';
import 'genre.dart';
import 'google_book.dart';
import 'item_list.dart';
import 'neom/chamber_preset.dart';

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
  
  String? genre;
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
  MediaItemType type;
  AppMediaSource mediaSource;

  int? expireAt; ///TIME WHEN EXPIRES IF APPLY

  AppMediaItem({
    this.id = '',
    this.album = '',
    this.albumId,
    this.artist = '',
    this.artistId,
    this.externalArtists,
    this.featInternalArtists,
    this.duration = 0,
    this.genre = '',
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
    this.type = MediaItemType.song,
    this.state = 0,
  });

  @override
  String toString() {
    return 'AppMediaItem{id: $id, name: $name, description: $description, artist: $artist, artistId: $artistId, album: $album, albumId: $albumId, duration: $duration, featInternalArtists: $featInternalArtists, externalArtists: $externalArtists, genre: $genre, genres: $genres, lyrics: $lyrics, language: $language, imgUrl: $imgUrl, allImgs: $allImgs, publisher: $publisher, publishedYear: $publishedYear, releaseDate: $releaseDate, url: $url, path: $path, permaUrl: $permaUrl, allUrls: $allUrls, trackNumber: $trackNumber, discNumber: $discNumber, quality: $quality, is320Kbps: $is320Kbps, likes: $likes, state: $state, type: $type, mediaSource: $mediaSource, expireAt: $expireAt}';
  }

  factory AppMediaItem.fromJSON(map) {
    try {
      AppUtilities.logger.t("AppMediaItem fromJSON: ${map['name'] ?? ''} with id ${map['id'] ?? ''}");
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
        genre: map['genre'] ?? '',
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
      AppUtilities.logger.e(e.toString());
      throw Exception('Error parsing song item: $e');
    }
  }

  Map<String, dynamic> toJSON() {
    return <String, dynamic>{
      'id': id,
      'album': album,
      'duration': duration,
      'genre': genre,
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
      'type': type.value,
    };
  }


  static List<AppMediaItem> listFromMap(Map<String, List<dynamic>> map) {
    List<AppMediaItem> items = [];
    try {

    } catch (e) {
      throw Exception('Error parsing song item: $e');
    }

    return items;
  }

  static List<AppMediaItem> listFromList(List<dynamic>? list) {
    List<AppMediaItem> items = [];
    try {

    } catch (e) {
      throw Exception('Error parsing song item: $e');
    }

    return items;
  }

  static List<AppMediaItem> listFromSongModel(List<SongModel>? list) {
    List<AppMediaItem> items = [];
    try {


    } catch (e) {
      throw Exception('Error parsing song item: $e');
    }

    return items;
  }

  static AppMediaItem fromSongModel(SongModel songModel) {
    return AppMediaItem(
      id: songModel.id.toString(),
      album: songModel.album ?? '',
      artist: songModel.artist ?? '',
      duration: songModel.duration ?? 0,
      name: songModel.title,
      genre: songModel.genre ?? '',
      description: songModel.composer,
      url: songModel.uri ?? '',
    );
  }

  static AppMediaItem fromAppReleaseItem(AppReleaseItem releaseItem) {
    try {
      return AppMediaItem(
        id: releaseItem.id,
        name: releaseItem.name,
        description: releaseItem.description,
        lyrics: releaseItem.lyrics ?? '',
        language: releaseItem.language,
        album: releaseItem.metaName ?? '',
        albumId: releaseItem.metaId,
        externalArtists: releaseItem.featInternalArtists?.values.toList(),
        duration: releaseItem.duration,
        genre: releaseItem.categories.join(', '),
        imgUrl: releaseItem.imgUrl,
        allImgs: releaseItem.galleryUrls,
        url: releaseItem.previewUrl,
        publisher: releaseItem.publisher,
        publishedYear: releaseItem.publishedYear,
        releaseDate: releaseItem.createdTime,
        permaUrl: releaseItem.previewUrl,
        featInternalArtists: releaseItem.featInternalArtists,
        artist: releaseItem.ownerName ?? '',
        artistId: releaseItem.ownerId,
        likes: releaseItem.likedProfiles?.length ?? 0,
        state: releaseItem.state,
        mediaSource: AppMediaSource.internal,
      );
    } catch (e) {
      throw Exception('Error parsing song item: $e');
    }
  }

  static List<AppMediaItem> mapItemsFromItemlist(Itemlist itemlist) {

    List<AppMediaItem> appMediaItems = [];

    if(itemlist.appMediaItems != null) {
      appMediaItems.addAll(itemlist.appMediaItems!);
    }

    if(itemlist.appReleaseItems != null) {
      for (var element in itemlist.appReleaseItems!) {
        appMediaItems.add(AppMediaItem.fromAppReleaseItem(element));
      }
    }

    // if(itemlist.chamberPresets != null) {
    //   itemlist.chamberPresets!.forEach((element) {
    //     appMediaItems.add(AppMediaItem.fromAppItem(element));
    //   });
    // }

    AppUtilities.logger.t("Retrieving ${appMediaItems.length} total AppMediaItems.");
    return appMediaItems;
  }

  static AppMediaItem mapTrackToSong(Track track) {
    AppMediaItem song = AppMediaItem();
    String artistName = "";
    String albumImgUrl = "";

    try {
      if (track.artists!.length > 1) {
        for (var artists in track.artists!) {
          artistName.isEmpty ? artistName = (artists.name ?? "")
              : artistName = "$artistName, ${artists.name ?? ""}";
        }
      } else {
        artistName = track.artists?.first.name ?? "";
        albumImgUrl = track.album?.images?.first.url ?? "";
      }

      song = AppMediaItem(
          id: track.id ?? "",
          state: 1,
          name: track.name ?? "",
          artist: artistName,
          artistId: track.artists?.first.id ?? "",
          album: track.album?.name ?? "",
          duration: ((track.durationMs ?? 0) / 1000).ceil(),
          imgUrl: albumImgUrl,
          url: track.previewUrl ?? "",
          genres: Genre.listFromJSON(track.artists?.first.genres ?? []).map((e) => e.name).toList(),
          mediaSource: AppMediaSource.spotify,
          type: MediaItemType.song,
          permaUrl: track.externalUrls?.spotify ?? ''
      );

    } catch (e) {
      AppUtilities.logger.e(e.toString());
    }

    return song;
  }

  static List<AppMediaItem> mapTracksToSongs(Paging<Track> tracks) {

    List<AppMediaItem> songs = [];

    ///DEPRECATED
    // String artistName = "";
    // String albumImgUrl = "";

    try {
      for (var playlistTrack in tracks.itemsNative!) {
        Track track = Track.fromJson(playlistTrack["track"]);
        songs.add(mapTrackToSong(track));
      }
    } catch (e) {
      AppUtilities.logger.e(e.toString());
    }

    return songs;
  }

  AppMediaItem.fromChamberPreset(ChamberPreset chamberPreset) :
        id = chamberPreset.id,
        name = chamberPreset.name,
        artist = "",
        artistId = chamberPreset.ownerId,
        album = "",
        imgUrl = chamberPreset.imgUrl,
        duration =  chamberPreset.neomFrequency?.frequency.ceil() ?? 0,
        url = "",
        description = chamberPreset.description.isNotEmpty ? chamberPreset.description : chamberPreset.neomFrequency?.description ?? "",
        publisher = "",
        state = chamberPreset.state,
        genres = [],
        mediaSource = AppMediaSource.internal,
        releaseDate = 0,
        is320Kbps = true,
        likes = 0,
        lyrics = '',
        permaUrl = chamberPreset.imgUrl,
        publishedYear = 0,
        type = MediaItemType.neomPreset;

  static AppMediaItem fromGoogleBook(GoogleBook googleBook) {

    AppMediaItem appItem = AppMediaItem();
    List<Genre> genres = [];

    try {
      String authors = "";

      if(googleBook.volumeInfo?.authors?.isNotEmpty ?? false) {
        googleBook.volumeInfo?.authors?.forEach((element) {
          if(authors.isNotEmpty) {
            authors = "$authors, ";
          }

          if(authors.isEmpty) {
            authors = element;
          } else {
            authors = "$authors$element";
          }
        });
      }

      if(googleBook.volumeInfo?.categories?.isNotEmpty ?? false) {
        googleBook.volumeInfo?.categories?.forEach((element) {
          genres.add(Genre(id: element, name: element));
        });
      }

      appItem =  AppMediaItem(
        id: googleBook.id ?? "",
        name: googleBook.volumeInfo?.title ?? "",
        album: googleBook.volumeInfo?.publisher ?? "",
        artist: authors,
        allImgs: [googleBook.volumeInfo?.imageLinks?.smallThumbnail ?? ""],
        duration: googleBook.volumeInfo?.pageCount ?? 0, ///NUMBER OF PAGES
        imgUrl: googleBook.volumeInfo?.imageLinks?.thumbnail ?? "",
        permaUrl: googleBook.volumeInfo?.infoLink ?? "",
        url: googleBook.volumeInfo?.previewLink ?? "",
        state: 0,
        genres: genres.map((e) => e.name).toList(),
        description: googleBook.volumeInfo?.description ?? "",
        publishedYear: 0, ///VERIFY HOW TO HANDLE THIS DATE TO SINCEEPOCH googleBook.volumeInfo?.publishedDate ?? ""
      );
    } catch (e) {
      AppUtilities.logger.e(e.toString());
    }

    return appItem;
  }

}
