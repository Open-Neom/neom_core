import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../app_config.dart';
import '../../domain/model/hashtag.dart';
import '../../domain/repository/hashtag_repository.dart';
import 'constants/app_firestore_collection_constants.dart';
import 'constants/app_firestore_constants.dart';
import 'core_firestore_guard.dart';

class HashtagFirestore implements HashtagRepository {

  var logger = AppConfig.logger;
  CollectionReference<Map<String, dynamic>> get hashtagReference =>
      FirebaseFirestore.instance.collection(AppFirestoreCollectionConstants.hashtags);
  Query<Map<String, dynamic>> get profileReference =>
      FirebaseFirestore.instance.collectionGroup(AppFirestoreCollectionConstants.profiles);

  @override
  Future<Hashtag> retrieve(String hashtag) async {
    final cleanTag = hashtag.trim();
    if (!CoreFirestoreGuard.isSafeDocId(cleanTag)) return Hashtag();
    logger.d("Getting hashtag info for $cleanTag");
    Hashtag appHashtag = Hashtag();
    try {
      final doc = await hashtagReference.doc(cleanTag).get();
      if (doc.exists && doc.data() != null) {
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
    final cleanTag = hashtag.trim();
    if (!CoreFirestoreGuard.isSafeDocId(cleanTag)) return false;
    logger.d("Getting hashtag $cleanTag");
    try {
      final doc = await hashtagReference.doc(cleanTag).get();
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
    final cleanTag = hashtag.id.trim();
    if (!CoreFirestoreGuard.isSafeDocId(cleanTag)) return;
    logger.d("Adding hashtag to database collection");
    try {
      await hashtagReference.doc(cleanTag).set(hashtag.toJSON());
      logger.d("Hashtag inserted into Firestore");
    } catch (e) {
      logger.e(e.toString());
      logger.i("Hashtag not inserted into Firestore");
    }
  }

  Future<bool> remove(String hashtag) async {
    final cleanTag = hashtag.trim();
    if (!CoreFirestoreGuard.isSafeDocId(cleanTag)) return false;
    logger.d("Removing Hashtag from database collection");
    try {
      await hashtagReference.doc(cleanTag).delete();
      return true;
    } catch (e) {
      logger.d(e.toString());
      return false;
    }
  }

  @override
  Future<bool> addPost(String hashtag, String postId) async {
    final cleanTag = hashtag.trim();
    final cleanPostId = postId.trim();
    if (!CoreFirestoreGuard.isSafeDocId(cleanTag) ||
        !CoreFirestoreGuard.isSafeDocId(cleanPostId)) {
      return false;
    }
    logger.d("Adding Post for hashtag $cleanTag");

    try {
      await hashtagReference
          .doc(cleanTag)
          .update({AppFirestoreConstants.postIds: FieldValue.arrayUnion([cleanPostId])});

      logger.d("PostId $cleanPostId was added to hashtag $cleanTag");
      return true;
    } catch (e) {
      logger.d(e.toString());
    }

    logger.d("PostId $cleanPostId was not added to hashtag $cleanTag");
    return false;
  }

  @override
  Future<bool> removePost(String hashtag, String postId) async {
    final cleanTag = hashtag.trim();
    final cleanPostId = postId.trim();
    if (!CoreFirestoreGuard.isSafeDocId(cleanTag) ||
        !CoreFirestoreGuard.isSafeDocId(cleanPostId)) {
      return false;
    }
    logger.d("Removing Post for hashtag $cleanTag");

    try {

      await hashtagReference.doc(cleanTag)
          .update({AppFirestoreConstants.postIds: FieldValue.arrayRemove([cleanPostId])});

      logger.d("PostId $cleanPostId was removed from hashtag $cleanTag");
      return true;
    } catch (e) {
      logger.d(e.toString());
    }

    logger.d("PostId $cleanPostId was not removed from hashtag $cleanTag");
    return false;
  }

}
