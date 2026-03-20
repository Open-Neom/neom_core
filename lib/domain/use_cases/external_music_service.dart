import 'package:neom_core/domain/model/external_item.dart';
import 'package:neom_core/domain/model/item_list.dart';

abstract class ExternalMusicService {
  Future<List<ExternalItem>> searchArtists(String query);
  Future<List<ExternalItem>> searchSongs(String query);
  Future<List<Itemlist>> searchAlbums(String query);
}
