import 'package:neom_core/domain/model/external_item.dart';
import 'package:neom_core/domain/model/item_list.dart';

class ExternalPlaylistImportResult {
  final String playlistId;
  final String title;
  final String description;
  final String imgUrl;
  final List<ExternalItem> songs;
  final String? error;

  const ExternalPlaylistImportResult({
    this.playlistId = '',
    this.title = '',
    this.description = '',
    this.imgUrl = '',
    this.songs = const [],
    this.error,
  });

  bool get hasSongs => songs.isNotEmpty;
}

abstract class ExternalMusicService {
  Future<List<ExternalItem>> searchArtists(String query);
  Future<List<ExternalItem>> searchSongs(String query);
  Future<List<Itemlist>> searchAlbums(String query);

  /// Fetches tracks from a public external playlist (e.g. YouTube / YouTube Music
  /// URL or playlist ID) so musicians can migrate their repertoire into a Giglist
  /// in bulk instead of adding songs one by one.
  Future<ExternalPlaylistImportResult> fetchPlaylistItems(
    String playlistIdOrUrl, {
    int maxResults = 100,
  }) async =>
      const ExternalPlaylistImportResult(error: 'Not supported');
}
