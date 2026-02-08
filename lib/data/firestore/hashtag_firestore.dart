import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../app_config.dart';
import '../../domain/model/hashtag.dart';
import '../../domain/repository/hashtag_repository.dart';
import 'constants/app_firestore_collection_constants.dart';
import 'constants/app_firestore_constants.dart';

class HashtagFirestore implements HashtagRepository {

  var logger = AppConfig.logger;
  final hashtagReference = FirebaseFirestore.instance.collection(AppFirestoreCollectionConstants.hashtags );
  final profileReference = FirebaseFirestore.instance.collectionGroup(AppFirestoreCollectionConstants.profiles);

  @override
  Future<Hashtag> retrieve(String hashtag) async {
    logger.d("Getting hashtag info for $hashtag");
    Hashtag appHashtag = Hashtag();
    try {
      // OPTIMIZED: Use await instead of .then()
      final doc = await hashtagReference.doc(hashtag).get();
      if (doc.exists) {
        appHashtag = Hashtag.fromJSON(doc.data()!);
        logger.d("Hashtag ${appHashtag.id} was retrieved with details");
      } else {
        logger.d("Hashtag not found");
      }
    } catch (e) {
      logger.d(e);
      rethrow;
    }
    return appHashtag;
  }

  @override
  Future<bool> exists(String hashtag) async {
    logger.d("Getting hashtag $hashtag");
    try {
      // OPTIMIZED: Use await instead of .then()
      final doc = await hashtagReference.doc(hashtag).get();
      if (doc.exists) {
        logger.d("Hashtag found");
        return true;
      }
      logger.d("Hashtag not found");
    } catch (e) {
      logger.e(e);
    }
    return false;
  }


  @override
  Future<void> insert(Hashtag hashtag) async {
    logger.d("Adding hashtag to database collection");
    try {
      await hashtagReference.doc(hashtag.id).set(hashtag.toJSON());
      logger.d("Hashtag inserted into Firestore");
    } catch (e) {
      logger.e(e.toString());
      logger.i("Hashtag not inserted into Firestore");
    }
  }

  Future<bool> remove(String hashtag) async {
    logger.d("Removing Hashtag from database collection");
    try {
      await hashtagReference.doc(hashtag).delete();
      return true;
    } catch (e) {
      logger.d(e.toString());
      return false;
    }
  }

  @override
  Future<bool> addPost(String hashtag, String postId) async {
    logger.d("Adding Post for hashtag $hashtag");

    try {
      await hashtagReference
          .doc(hashtag)
          .update({AppFirestoreConstants.postIds: FieldValue.arrayUnion([postId])});

      logger.d("PostId $postId} was added to hashtag $hashtag");
      return true;
    } catch (e) {
      logger.d(e.toString());
    }

    logger.d("PostId $postId} was not added to hashtag $hashtag");
    return false;
  }

  @override
  Future<bool> removePost(String hashtag, String postId) async {
    logger.d("Removing Post for hashtag $hashtag");

    try {

      await hashtagReference.doc(hashtag)
          .update({AppFirestoreConstants.postIds: FieldValue.arrayRemove([postId])});

      logger.d("PostId $postId was removed from hashtag $hashtag");
      return true;
    } catch (e) {
      logger.d(e.toString());
    }

    logger.d("PostId $postId was not removed from hashtag $hashtag");
    return false;
  }

}
