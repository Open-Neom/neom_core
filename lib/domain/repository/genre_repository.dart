import 'dart:async';
import '../model/genre.dart';

abstract class GenreRepository {

  Future<Map<String?,Genre>> retrieveGenres(String profileId);

  Future<bool> removeGenre({required String profileId, required String genreId});

  Future<bool> addGenre({required String profileId, required String genreId});

  Future<bool> updateMainGenre({required String profileId,
    required String genreId, required String prevGenreId});

}
