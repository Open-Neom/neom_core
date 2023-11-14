import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/model/genre.dart';
import '../../domain/repository/genre_repository.dart';
import '../../utils/app_utilities.dart';
import 'constants/app_firestore_collection_constants.dart';
import 'constants/app_firestore_constants.dart';

class GenreFirestore implements GenreRepository {

  var logger = AppUtilities.logger;
  final profileReference = FirebaseFirestore.instance.collectionGroup(AppFirestoreCollectionConstants.profiles);


  @override
  Future<Map<String,Genre>> retrieveGenres(profileId) async {
    logger.t("Retrieving Genre by Profile $profileId");

    Map<String, Genre> genres = {};

    try {
      QuerySnapshot querySnapshot = await profileReference.get();
      for (var document in querySnapshot.docs) {
        if(document.id == profileId) {
          QuerySnapshot qSnapshot = await document.reference
              .collection(AppFirestoreCollectionConstants.genres).get();

          for (var queryDocumentSnapshot in qSnapshot.docs) {
            Genre genre = Genre.fromQueryDocumentSnapshot(queryDocumentSnapshot);
            genres[genre.name] = genre;
          }
        }
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
      await profileReference.get()
          .then((querySnapshot) async {
        for (var document in querySnapshot.docs) {
          if (document.id == profileId) {
            await document.reference
                .collection(AppFirestoreCollectionConstants.genres)
                .doc(genreId)
                .delete();
          }
        }
      });

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
      await profileReference.get()
          .then((querySnapshot) async {
        for (var document in querySnapshot.docs) {
          if (document.id == profileId) {
            await document.reference
                .collection(AppFirestoreCollectionConstants.genres)
                .doc(genreId)
                .set(genreBasic.toJSON());
          }
        }
      });

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
      await profileReference.get()
          .then((querySnapshot) async {
        for (var document in querySnapshot.docs) {
          if (document.id == profileId) {
            logger.i("Genre $genreId as main genre at genres collection");
            await document.reference
                .collection(AppFirestoreCollectionConstants.genres)
                .doc(genreId)
                .update({AppFirestoreConstants.isMain: true});

            logger.d("Genre $genreId as main genre at profile level");

            //TODO Add to model
            //document.reference.update({GigFirestoreConstants.mainGenre: genreId});

            if(prevGenreId.isNotEmpty) {
              logger.d("Genre $prevGenreId unset from main genre");
              await document.reference
                  .collection(AppFirestoreCollectionConstants.genres)
                  .doc(prevGenreId)
                  .update({AppFirestoreConstants.isMain: false});
            }
          }
        }
      });

      return true;
    } catch (e) {
      logger.e(e.toString());
      return false;
    }
  }


}
