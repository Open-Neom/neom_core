import 'genre.dart';

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
      this.publishedDate = ""
  });

  @override
  String toString() {
    return 'AppItem{id: $id, name: $name, artist: $artist, artistId: $artistId, artistImgUrl: $artistImgUrl, albumName: $albumName, durationMs: $durationMs, albumImgUrl: $albumImgUrl, previewUrl: $previewUrl, state: $state, genres: $genres, infoUrl: $infoUrl, description: $description, publisher: $publisher, publishedDate: $publishedDate, currentTime: $currentTime}';
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
    publishedDate = data["publishedDate"] ?? "";

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
    'publishedDate': publishedDate
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
        genres = appItem.genres;

}
