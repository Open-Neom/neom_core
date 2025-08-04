import '../model/genre.dart';

abstract class GenreService {

  Future<void> loadGenres();
  Future<void>  addGenre(int index);
  Future<void> removeGenre(int index);
  void makeMainGenre(Genre genre);
  void sortFavGenres();

}
