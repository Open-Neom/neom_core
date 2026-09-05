import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../app_config.dart';
import '../../domain/model/genre.dart';
import '../../domain/repository/genre_repository.dart';
import 'constants/app_firestore_collection_constants.dart';
import 'constants/app_firestore_constants.dart';
import 'profile_document_locator.dart';

class GenreFirestore implements GenreRepository {

  final logger = AppConfig.logger;
  final _profileLocator = ProfileDocumentLocator();

  /// `profiles/{profileId}/genres`, or null when the profile does not exist.
  Future<CollectionReference?> _genresOf(String profileId) => _profileLocator.subcollection(
      profileId, AppFirestoreCollectionConstants.genres);

  @override
  Future<Map<String,Genre>> retrieveGenres(profileId) async {
    logger.t("Retrieving Genre by Profile $profileId");

    Map<String, Genre> genres = {};

    try {
      final genresReference = await _genresOf(profileId);
      if (genresReference == null) return genres;

      final qSnapshot = await genresReference.get();
      for (var queryDocumentSnapshot in qSnapshot.docs) {
        Genre genre = Genre.fromQueryDocumentSnapshot(queryDocumentSnapshot);
        genres[genre.name] = genre;
      }
    } catch (e) {
      logger.e("No genres found");
    }

    logger.t("${genres.length} genres found");
    return genres;
  }

  @override
  Future<bool> removeGenre({required String profileId, required String genreId}) async {
    logger.d("Removing $genreId for by $profileId");
    try {
      final genresReference = await _genresOf(profileId);
      if (genresReference == null) return false;

      await genresReference.doc(genreId).delete();

      logger.d("Genre $genreId removed");
      return true;
    } catch (e) {
      logger.e(e.toString());
      return false;
    }
  }

  @override
  Future<bool> addGenre({required String profileId, required String genreId}) async {
    logger.t("Adding $genreId for by $profileId");

    Genre genreBasic = Genre.addBasic(genreId);
    try {
      final genresReference = await _genresOf(profileId);
      if (genresReference == null) return false;

      await genresReference.doc(genreId).set(genreBasic.toJSON());

      logger.d("Genre $genreId added");
      return true;
    } catch (e) {
      logger.e(e.toString());
      return false;
    }
  }

  @override
  Future<bool> updateMainGenre({required String profileId,
      required String genreId, required String prevGenreId}) async {

    logger.d("Updating $genreId as main for $profileId");

    try {
      final genresReference = await _genresOf(profileId);
      if (genresReference == null) return false;

      logger.i("Genre $genreId as main genre at genres collection");
      await genresReference.doc(genreId)
          .update({AppFirestoreConstants.isMain: true});

      if(prevGenreId.isNotEmpty) {
        logger.d("Genre $prevGenreId unset from main genre");
        await genresReference.doc(prevGenreId)
            .update({AppFirestoreConstants.isMain: false});
      }

      return true;
    } catch (e) {
      logger.e(e.toString());
      return false;
    }
  }

}
