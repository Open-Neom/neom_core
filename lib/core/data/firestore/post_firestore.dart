import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/model/post.dart';
import '../../domain/repository/post_repository.dart';
import '../../utils/app_utilities.dart';
import '../../utils/constants/app_constants.dart';
import '../../utils/enums/post_type.dart';
import 'activity_feed_firestore.dart';
import 'constants/app_firestore_collection_constants.dart';
import 'constants/app_firestore_constants.dart';
import 'profile_firestore.dart';

class PostFirestore implements PostRepository {

  var logger = AppUtilities.logger;
  final postsReference = FirebaseFirestore.instance.collection(
      AppFirestoreCollectionConstants.posts);

  List<QueryDocumentSnapshot> _documentTimeline = [];

  @override
  Future<List<Post>> retrievePosts() async {
    logger.d("RetrievingProfiles");
    List<Post> posts = <Post>[];

    try {
      QuerySnapshot querySnapshot = await postsReference.get();

      if (querySnapshot.docs.isNotEmpty) {
        logger.v("Snapshot is not empty");
        for (var postSnapshot in querySnapshot.docs) {
          Post post = Post.fromJSON(postSnapshot.data());
          post.id = postSnapshot.id;
          logger.v(post.toString());
          posts.add(post);
        }
        logger.v("${posts.length} posts found");
      }
    } catch (e) {
      logger.e(e.toString());
      logger.w("No Posts Found");
    }

    return posts;
  }

  @override
  Future<bool> handleLikePost(String profileId, String postId,
      bool isLiked) async {
    logger.d("Handle Like Post");
    try {
      if (isLiked) {
        await postsReference.doc(postId).update({
          AppFirestoreConstants.likedProfiles: FieldValue.arrayRemove([profileId])
        });
      } else {
        await postsReference.doc(postId).update({
          AppFirestoreConstants.likedProfiles: FieldValue.arrayUnion([profileId])
        });
      }
      return true;
    } catch (e) {
      logger.e(e.toString());
      return false;
    }
  }

  @override
  Future<String> insert(Post post) async {
    logger.d("");
    String postId = "";
    try {
      DocumentReference documentReference = await postsReference
          .add(post.toJSON());
      postId = documentReference.id;
    } catch (e) {
      logger.e(e.toString());
    }

    return postId;
  }

  @override
  Future<Post> retrieve(String postId) async {
    logger.d("Retrieving post: $postId");
    Post post = Post();
    try {
      DocumentSnapshot postSnapshot = await postsReference.doc(postId).get();
      post = Post.fromJSON(postSnapshot.data());
      post.id = postSnapshot.id;
    } catch (e) {
      logger.e(e.toString());
    }

    return post;
  }


  @override
  Future<bool> remove(String profileId, String postId) async {
    logger.d("");
    bool wasDeleted = false;
    try {
      await postsReference.doc(postId).delete();
      wasDeleted = await ProfileFirestore().removePost(profileId, postId);
      await ActivityFeedFirestore().removePostActivity(postId);
    } catch (e) {
      logger.e(e.toString());
    }

    return wasDeleted;
  }

  Future<bool> update(Post post) async {
    logger.d("");
    try {
      await postsReference.doc(post.id).update(post.toJSON());
      return true;
    } catch (e) {
      logger.e(e.toString());
    }

    return false;
  }

  @override
  Future<List<Post>> getProfilePosts(String profileId) async {
    logger.d("");

    List<Post> posts = [];

    QuerySnapshot querySnapshot = await postsReference.where(
        AppFirestoreConstants.ownerId, isEqualTo: profileId).get();

    if (querySnapshot.docs.isNotEmpty) {
      logger.v("Snapshot is not empty");
      for (int queryIndex = 0; queryIndex <
          querySnapshot.docs.length; queryIndex++) {
        Post post = Post.fromJSON(querySnapshot.docs.elementAt(queryIndex).data());
        post.id = querySnapshot.docs.elementAt(queryIndex).id;
        logger.d(post.toString());
        if (post.type != PostType.event && post.type != PostType.releaseItem) {
          posts.add(post);
        }
      }
    }
    return posts;
  }


  @override
  Future<Map<String, Post>> getTimeline() async {
    logger.v("");
    Map<String, Post> posts = {};

    try {
      QuerySnapshot snapshot = await postsReference
          //.where(AppFirestoreConstants.isDraft, isEqualTo: false)
          .orderBy(AppFirestoreConstants.createdTime, descending: true)
          .limit(AppConstants.timelineLimit)
          .get();

      _documentTimeline = snapshot.docs;

      for (int i = 0; i < _documentTimeline.length; i++) {
        Post post = Post.fromJSON(_documentTimeline.elementAt(i).data());
        if(!post.isDraft) {
          post.id = _documentTimeline.elementAt(i).id;
          if(post.location.isEmpty && post.position != null) {
            post.location = await AppUtilities.getAddressFromPlacerMark(post.position!);
          }
          posts[post.id] = post;
        }

      }
    } catch (e) {
      logger.e(e.toString());
    }

    return posts;
  }


  Future<Map<String, Post>> getDrafts({String profileId = ""}) async {
    logger.d("");
    List<Post> sortedDrafts = [];
    Map<String, Post> drafts = {};

    try {
      QuerySnapshot snapshot = await postsReference
          .where(AppFirestoreConstants.isDraft, isEqualTo: true)
          .get();

      _documentTimeline = snapshot.docs;

      for (int i = 0; i < _documentTimeline.length; i++) {
        Post post = Post.fromJSON(_documentTimeline.elementAt(i).data());
        post.id = _documentTimeline.elementAt(i).id;
        if(post.location.isEmpty && post.position != null) {
          post.location = await AppUtilities.getAddressFromPlacerMark(post.position!);
        }

        if(profileId == post.ownerId || profileId.isEmpty) {
          sortedDrafts.add(post);
        }

      }

      sortedDrafts.sort((a,b) => a.modifiedTime.compareTo(b.modifiedTime));

      for (var post in sortedDrafts) {
        drafts[post.id] = post;
      }

    } catch (e) {
      logger.e(e.toString());
    }

    return drafts;
  }

  @override
  Future<Map<String, Post>> getNextTimeline() async {
    logger.d("Getting Next Timeline Posts");
    Map<String, Post> posts = {};

    try {
      QuerySnapshot snapshot = await postsReference
          .orderBy(AppFirestoreConstants.createdTime, descending: true)
          .startAfterDocument(_documentTimeline[_documentTimeline.length-1])
          .limit(AppConstants.timelineLimit).get();

      _documentTimeline.addAll(snapshot.docs);

      for (int i = 0; i < snapshot.docs.length; i++) {
        Post post = Post.fromJSON(snapshot.docs.elementAt(i).data());
        post.id = snapshot.docs.elementAt(i).id;

        //TODO Verify if needed
        // post.comments = await GigCommentFirestore().retrieveComments(
        //   gigPostId: post.id
        // );

        posts[post.id] = post;
      }
    } catch (e) {
      logger.e(e.toString());
    }

    return posts;
  }


  Future<bool> removeEventPost(String ownerId, String eventId) async {
    logger.d("RetrievingProfiles");
    bool wasDeleted = false;

    try {

      QuerySnapshot querySnapshot = await postsReference.get();
      if (querySnapshot.docs.isNotEmpty) {
        logger.d("Snapshot is not empty");
        for (var postSnapshot in querySnapshot.docs) {
          Post post = Post.fromJSON(postSnapshot.data());
          post.id = postSnapshot.id;
          if(post.referenceId == eventId) {
            logger.i("Removing post for Event $eventId");
            await postSnapshot.reference.delete();
            wasDeleted = await ProfileFirestore().removePost(ownerId, postSnapshot.reference.id);
            await ActivityFeedFirestore().removePostActivity(postSnapshot.reference.id);
            wasDeleted = true;
          }
        }
      }
    } catch (e) {
      logger.e(e.toString());
    }

    return wasDeleted;
  }


  @override
  Future<bool> addComment(String postId, String commentId) async {
    logger.d("");
    try {

      await postsReference.doc(postId).update({
        AppFirestoreConstants.commentIds: FieldValue.arrayUnion([commentId])
      });

      return true;
    } catch (e) {
      logger.e(e.toString());
      return false;
    }
  }


  @override
  Future<bool> removeComment(String postId, String commentId) async {
    logger.d("");
    try {
      await postsReference.doc(postId).update({
      AppFirestoreConstants.commentIds: FieldValue.arrayRemove([commentId])
      });
      return true;
    } catch (e) {
      logger.e(e.toString());
      return false;
    }
  }


  @override
  Future<Post> retrievePostForEvent(String eventId) async {
    logger.d("Retrieving post for Event $eventId");

    Post post = Post();

    try {
      QuerySnapshot querySnapshot = await postsReference.where(
          AppFirestoreConstants.eventId, isEqualTo: eventId).get();

      if (querySnapshot.docs.isNotEmpty) {
        logger.d("Snapshot is not empty");
        for (DocumentSnapshot doc in querySnapshot.docs) {
          post = Post.fromJSON(doc.data());
          post.id = doc.id;
          logger.d(post.toString());
        }
      }
    } catch (e) {
      logger.e(e.toString());
    }

    return post;
  }

  @override
  Future<Map<String, Post>> getBlogEntries({String profileId = ""}) async {
    logger.d("getBlogEntries");
    List<Post> sortedDrafts = [];
    Map<String, Post> drafts = {};

    try {
      QuerySnapshot snapshot = await postsReference
          .where(AppFirestoreConstants.type, isEqualTo: PostType.blogEntry.name)
          .get();

      for (int i = 0; i < snapshot.docs.length; i++) {
        Post post = Post.fromJSON(snapshot.docs.elementAt(i).data());
        post.id = snapshot.docs.elementAt(i).id;

        if(profileId == post.ownerId || profileId.isEmpty) {
          if(post.location.isEmpty && post.position != null) {
            post.location = await AppUtilities.getAddressFromPlacerMark(post.position!);
          }
          sortedDrafts.add(post);
        }

      }

      if(sortedDrafts.isNotEmpty) {
        sortedDrafts.sort((a,b) => a.modifiedTime.compareTo(b.modifiedTime));

        for (var post in sortedDrafts) {
          drafts[post.id] = post;
        }
      }

    } catch (e) {
      logger.e(e.toString());
    }

    return drafts;
  }

}
