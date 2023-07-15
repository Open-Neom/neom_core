import 'package:spotify/spotify.dart';

import '../../utils/app_utilities.dart';
import 'app_release_item.dart';
import 'genre.dart';
import 'neom/chamber_preset.dart';

class AppItem {

  String id;
  String name;
  String artist;
  String artistId;
  String artistImgUrl;
  String albumName;
  int durationMs;
  String albumImgUrl;
  String previewUrl;
  int state;
  List<Genre> genres;

  String infoUrl = "";
  String description = "";
  String publisher = "";
  String publishedDate = "";
  int currentTime = 0;
  bool isRelease = false;

  AppItem({
      this.id = "",
      this.name = "",
      this.artist = "",
      this.artistId = "",
      this.artistImgUrl = "",
      this.albumName = "",
      this.albumImgUrl = "",
      this.durationMs = 0,
      this.previewUrl = "",
      this.state = 0,
      this.genres = const [],
      this.infoUrl = "",
      this.description = "",
      this.publishedDate = "",
      this.isRelease = false,
  });


  @override
  String toString() {
    return 'AppItem{id: $id, name: $name, artist: $artist, artistId: $artistId, artistImgUrl: $artistImgUrl, albumName: $albumName, durationMs: $durationMs, albumImgUrl: $albumImgUrl, previewUrl: $previewUrl, state: $state, genres: $genres, infoUrl: $infoUrl, description: $description, publisher: $publisher, publishedDate: $publishedDate, currentTime: $currentTime, isRelease: $isRelease}';
  }


  AppItem.fromJSON(data) :
    id = data["id"] ?? "",
    name = data["name"] ?? "",
    albumName = data["albumName"] ?? "",
    artist = data["artist"] ?? "",
    artistId = data["artistId"] ?? "",
    artistImgUrl = data["artistImgUrl"] ?? "",
    albumImgUrl = data["albumImgUrl"] ?? "",
    durationMs = data["durationMs"] ?? 0,
    previewUrl = data["previewUrl"] ?? "",
    state = data["state"] ?? data["songState"] ?? 0,
    genres = List<Genre>.from(data["genres"].map((model)=> Genre.fromJson(model))),
    infoUrl = data["infoUrl"] ?? "",
    description = data["description"] ?? "",
    publishedDate = data["publishedDate"] ?? "",
    isRelease = data["isRelease"] ?? false;

  Map<String, dynamic>  toJSON()=>{
    'id': id,
    'name': name,
    'albumName': albumName,
    'artist': artist,
    'artistId': artistId,
    'artistImgUrl': artistImgUrl,
    'durationMs': durationMs,
    'albumImgUrl': albumImgUrl,
    'previewUrl': previewUrl,
    'state': state,
    'genres': genres.map((genre) => genre.toJSON()).toList(),
    'infoUrl': infoUrl,
    'description': description,
    'publishedDate': publishedDate,
    'isRelease': isRelease,
  };

  AppItem.forItemsCollection(AppItem appItem) :
        id = appItem.id,
        name = appItem.name,
        artist = appItem.artist,
        artistId = appItem.artistId,
        artistImgUrl = appItem.artistImgUrl,
        albumName = appItem.albumName,
        albumImgUrl = appItem.albumImgUrl,
        durationMs = appItem.durationMs,
        previewUrl = appItem.previewUrl,
        state = 0,
        genres = appItem.genres,
        isRelease = appItem.isRelease;

  static AppItem mapTrackToSong(Track track) {

    String artistName = "";
    String albumImgUrl = "";
    String artistImgUrl = "";
    List<String> genres = [];

    try {
      if (track.artists!.length > 1) {
        for (var artist in track.artists!) {
          (artistName.isEmpty && artist.name != null) ? artistName = artist.name!
              : artistName = "$artistName, ${artist.name!}";
          genres.addAll(artist.genres ?? []);
        }
      } else {
        artistName = track.artists!.first.name ?? "";
        genres.addAll(track.artists!.first.genres ?? []);
        albumImgUrl = track.album!.images!.first.url ?? "";
      }

      artistImgUrl = track.artists!.first.images?.first.url ?? "";

    } catch (e) {
      AppUtilities.logger.e("");
    }

    return AppItem(
        id: track.id ?? "",
        name: track.name ?? "",
        albumName: track.album!.name ?? "",
        artist: artistName,
        artistImgUrl: artistImgUrl,
        durationMs: track.durationMs ?? 0,
        albumImgUrl: albumImgUrl,
        previewUrl: track.previewUrl ?? "",
        state: 0);
  }

  static Future<List<AppItem>> mapTracksToSongs(Paging<Track> tracks) async {
    List<AppItem> songs = [];
    String artistName = "";
    String albumImgUrl = "";

    try {
      for (var playlistTrack in tracks.itemsNative!) {

        Track track = Track.fromJson(playlistTrack["track"]);

        if (track.artists!.length > 1) {
          for (var artists in track.artists!) {
            artistName.isEmpty ? artistName = (artists.name ?? "")
                : artistName = "$artistName, ${artists.name ?? ""}";
          }
        } else {
          artistName = track.artists?.first.name ?? "";
          albumImgUrl = track.album?.images?.first.url ?? "";
        }

        //TODO Verify how to improve this with a job routine
        //Artist trackArtist = await SpotifySearch().loadArtistDetails(track.artists?.first.id ?? "");

        songs.add(
            AppItem(
                id: track.id ?? "",
                state: 1,
                name: track.name ?? "",
                artist: artistName,
                artistId: track.artists?.first.id ?? "",
                albumName: track.album?.name ?? "",
                durationMs: track.durationMs ?? 0,
                albumImgUrl: albumImgUrl,
                previewUrl: track.previewUrl ?? "",
                genres: Genre.listFromJSON(track.artists?.first.genres ?? [])
            )
        );
      }
    } catch (e) {
      AppUtilities.logger.e(e.toString());
    }

    return songs;
  }

  static List<AppItem> mapPageTracksToSongs(Pages<Track> tracks){

    List<AppItem> songs = [];

    String artist = "";
    String albumImgUrl = "";
    tracks.all().then((tracks) {
      for (var track in tracks) {
        if ((track.artists?.length ?? 0) > 1) {
          for (var artists in track.artists!) {
            artist.isEmpty ? artist = artists.name ?? ""
                : artist = "$artist, ${artists.name ?? ""}";
          }
        } else {
          artist = track.artists?.first.name ?? "";
          albumImgUrl = track.album?.images?.first.url ?? "";
        }
        songs.add(
            AppItem(
                id: track.id ?? "",
                state: 0,
                name: track.name ?? "",
                artist: artist,
                albumName: track.album?.name ?? "",
                durationMs: track.durationMs ?? 0,
                albumImgUrl: albumImgUrl,
                previewUrl: track.previewUrl ?? "",
                genres: []
            )
        );
      }
    });

    return songs;
  }

  AppItem.fromReleaseItem(AppReleaseItem releaseItem) :
        id = releaseItem.id,
        name = releaseItem.name,
        artist = releaseItem.ownerName,
        artistId = releaseItem.ownerId,
        artistImgUrl = releaseItem.ownerImgUrl,
        albumName = releaseItem.metaName,
        albumImgUrl = releaseItem.imgUrl,
        durationMs = releaseItem.duration,
        previewUrl = releaseItem.previewUrl,
        description = releaseItem.description,
        publisher = releaseItem.publisher,
        publishedDate = releaseItem.publishedYear.toString(),
        state = 0,
        genres = releaseItem.genres.map((e) => Genre(name: e)).toList(),
        isRelease = true;

  AppItem.fromChamberPreset(ChamberPreset chamberPreset) :
        id = chamberPreset.id,
        name = chamberPreset.name,
        artist = "",
        artistId = chamberPreset.ownerId,
        artistImgUrl = "",
        albumName = "",
        albumImgUrl = chamberPreset.imgUrl,
        durationMs =  chamberPreset.neomFrequency?.frequency.ceil() ?? 0,
        previewUrl = "",
        description = chamberPreset.description.isNotEmpty ? chamberPreset.description : chamberPreset.neomFrequency?.description ?? "",
        publisher = "",
        publishedDate = "",
        state = chamberPreset.state,
        genres = [],
        isRelease = false;

}
