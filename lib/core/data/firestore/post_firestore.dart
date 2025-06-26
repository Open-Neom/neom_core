import 'package:cloud_firestore/cloud_firestore.dart';
import '../../app_config.dart';
import '../../domain/model/post.dart';
import '../../domain/repository/post_repository.dart';

import '../../utils/constants/core_constants.dart';
import '../../utils/enums/post_type.dart';
import '../../utils/position_utilities.dart';
import 'activity_feed_firestore.dart';
import 'constants/app_firestore_collection_constants.dart';
import 'constants/app_firestore_constants.dart';
import 'profile_firestore.dart';

class PostFirestore implements PostRepository {

  final postsReference = FirebaseFirestore.instance.collection(
      AppFirestoreCollectionConstants.posts);

  final List<QueryDocumentSnapshot> _profileDocPosts = [];
  final List<QueryDocumentSnapshot> _recentDocTimeline = [];
  final List<QueryDocumentSnapshot> _moreCommentsDocTimeline = [];
  final List<QueryDocumentSnapshot> _moreLikedDocTimeline = [];
  final List<QueryDocumentSnapshot> _releaseDocTimeline = [];
  final List<QueryDocumentSnapshot> _blogEntriesDocTimeline = [];
  final List<QueryDocumentSnapshot> _followingDocTimeline = [];
  final Map<String, QueryDocumentSnapshot> _diverseDocTimeline = {};

  @override
  Future<List<Post>> retrievePosts() async {
    AppConfig.logger.d("Retrieving Posts");
    List<Post> posts = <Post>[];

    try {
      QuerySnapshot querySnapshot = await postsReference.get();

      if (querySnapshot.docs.isNotEmpty) {
        AppConfig.logger.t("Snapshot is not empty");
        for (var postSnapshot in querySnapshot.docs) {
          Post post = Post.fromJSON(postSnapshot.data());
          post.id = postSnapshot.id;
          AppConfig.logger.t(post.toString());
          posts.add(post);
        }
        AppConfig.logger.t("${posts.length} posts found");
      }
    } catch (e) {
      AppConfig.logger.e(e.toString());
      AppConfig.logger.w("No Posts Found");
    }

    return posts;
  }

  @override
  Future<bool> handleLikePost(String profileId, String postId,
      bool isLiked) async {
    AppConfig.logger.d("Handle Like for Post: $postId - isLiked: $isLiked");
    try {
      await postsReference.doc(postId).update({
        AppFirestoreConstants.likedProfiles: isLiked ? FieldValue.arrayRemove([profileId]) : FieldValue.arrayUnion([profileId]),
        AppFirestoreConstants.lastInteraction: DateTime.now().millisecondsSinceEpoch,
      });

      return true;
    } catch (e) {
      AppConfig.logger.e(e.toString());
      return false;
    }
  }

  @override
  Future<String> insert(Post post) async {
    AppConfig.logger.t("Insert");
    String postId = "";
    try {
      DocumentReference documentReference = await postsReference
          .add(post.toJSON());
      postId = documentReference.id;
    } catch (e) {
      AppConfig.logger.e(e.toString());
    }
    AppConfig.logger.d("Post Inserted with ID: $postId");
    return postId;
  }

  @override
  Future<Post> retrieve(String postId) async {
    AppConfig.logger.d("Retrieving post: $postId");
    Post post = Post();
    try {
      DocumentSnapshot postSnapshot = await postsReference.doc(postId).get();
      post = Post.fromJSON(postSnapshot.data());
      post.id = postSnapshot.id;
    } catch (e) {
      AppConfig.logger.e(e.toString());
    }

    return post;
  }


  @override
  Future<bool> remove(String profileId, String postId) async {
    AppConfig.logger.t("remove Post");
    bool wasDeleted = false;
    try {
      await postsReference.doc(postId).delete();
      wasDeleted = await ProfileFirestore().removePost(profileId, postId);
      await ActivityFeedFirestore().removePostActivity(postId);
    } catch (e) {
      AppConfig.logger.e(e.toString());
    }

    return wasDeleted;
  }

  Future<bool> update(Post post) async {
    AppConfig.logger.d("");
    try {
      await postsReference.doc(post.id).update(post.toJSON());
      return true;
    } catch (e) {
      AppConfig.logger.e(e.toString());
    }

    return false;
  }

  @override
  Future<List<Post>> getProfilePosts(String profileId) async {
    AppConfig.logger.t("getProfilePosts from Firestore");

    List<Post> posts = [];

    try {
      Query query = postsReference
          .where(AppFirestoreConstants.ownerId, isEqualTo: profileId)
          .orderBy(AppFirestoreConstants.createdTime, descending: true);
          // .limit(AppConstants.profilePostsLimit); //TODO Implement to improve performance on profile tab
      if (_profileDocPosts.isNotEmpty) {
        query = query.startAfterDocument(_profileDocPosts.last);
      }
      QuerySnapshot querySnapshot  = await query.get();

      if (querySnapshot.docs.isNotEmpty) {
        for(var doc in querySnapshot.docs) {
          Post post = Post.fromJSON(doc.data());
          post.id = doc.id;
          AppConfig.logger.t('Post ${post.id} of type ${post.type.name} at ${post.location}');
          if (post.type != PostType.event && post.type != PostType.releaseItem) {
            posts.add(post);
          }
        }
      }
    } catch (e) {
      AppConfig.logger.e(e.toString());
    }

    AppConfig.logger.d("Retrieveing ${posts.length} Posts");
    return posts;
  }


  @override
  Future<Map<String, Post>> getTimeline({int limit = CoreConstants.timelineLimit}) async {
    AppConfig.logger.t("getTimeline");
    Map<String, Post> posts = {};

    try {
      Query query = postsReference
          .orderBy(AppFirestoreConstants.lastInteraction, descending: true)
          .limit(limit);
      if (_recentDocTimeline.isNotEmpty) {
        query = query.startAfterDocument(_recentDocTimeline.last);
      }
      QuerySnapshot snapshot  = await query.get();

      _recentDocTimeline.addAll(snapshot.docs);

      for(var doc in snapshot.docs) {
        Post post = Post.fromJSON(doc.data());
        if(!post.isDraft && !_diverseDocTimeline.containsKey(doc.id)) {
          post.id = doc.id;
          if(post.location.isEmpty && post.position?.latitude != 0) {
            post.location = await PositionUtilities.getAddressFromPlacerMark(post.position!);
          }
          posts[post.id] = post;
          _diverseDocTimeline[doc.id] = doc;
        }

      }
    } catch (e) {
      AppConfig.logger.e(e.toString());
    }

    AppConfig.logger.d("Retrieveing ${posts.length} Posts");
    return posts;
  }

  ///DEPRECATED
  // @override
  // Future<Map<String, Post>> getNextTimeline() async {
  //   AppConfig.logger.d("Getting Next Timeline Posts");
  //   Map<String, Post> posts = {};
  //
  //   try {
  //     QuerySnapshot snapshot = await postsReference
  //         .orderBy(AppFirestoreConstants.createdTime, descending: true)
  //         .startAfterDocument(_recentDocTimeline[_recentDocTimeline.length-1])
  //         .limit(AppConstants.timelineLimit).get();
  //
  //     _recentDocTimeline.addAll(snapshot.docs);
  //
  //     for(var doc in snapshot.docs) {
  //       Post post = Post.fromJSON(doc.data());
  //       post.id = doc.id;
  //       posts[post.id] = post;
  //     }
  //   } catch (e) {
  //     AppConfig.logger.e(e.toString());
  //   }
  //
  //   return posts;
  // }

  Future<Map<String, Post>> getDrafts({String profileId = ""}) async {
    AppConfig.logger.d("");
    List<Post> sortedDrafts = [];
    Map<String, Post> drafts = {};

    try {
      QuerySnapshot snapshot = await postsReference
          .where(AppFirestoreConstants.isDraft, isEqualTo: true)
          .get();

      _recentDocTimeline.addAll(snapshot.docs);

      for (int i = 0; i < _recentDocTimeline.length; i++) {
        Post post = Post.fromJSON(_recentDocTimeline.elementAt(i).data());
        post.id = _recentDocTimeline.elementAt(i).id;
        if(post.location.isEmpty && post.position != null) {
          post.location = await PositionUtilities.getAddressFromPlacerMark(post.position!);
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
      AppConfig.logger.e(e.toString());
    }

    return drafts;
  }

  Future<bool> removeEventPost(String ownerId, String eventId) async {
    AppConfig.logger.t('Remove Event Post $eventId');
    bool wasDeleted = false;

    try {
      QuerySnapshot querySnapshot = await postsReference.get();
      if (querySnapshot.docs.isNotEmpty) {
        for (var postSnapshot in querySnapshot.docs) {
          Post post = Post.fromJSON(postSnapshot.data());
          post.id = postSnapshot.id;
          if(post.referenceId == eventId) {
            await postSnapshot.reference.delete();
            wasDeleted = await ProfileFirestore().removePost(ownerId, postSnapshot.reference.id);
            await ActivityFeedFirestore().removePostActivity(postSnapshot.reference.id);
            wasDeleted = true;
          }
        }
      }
    } catch (e) {
      AppConfig.logger.e(e.toString());
    }

    return wasDeleted;
  }


  @override
  Future<bool> addComment(String postId, String commentId) async {
    AppConfig.logger.d("");
    try {

      await postsReference.doc(postId).update({
        AppFirestoreConstants.commentIds: FieldValue.arrayUnion([commentId]),
        AppFirestoreConstants.lastInteraction: DateTime.now().millisecondsSinceEpoch,
      });

      return true;
    } catch (e) {
      AppConfig.logger.e(e.toString());
      return false;
    }
  }


  @override
  Future<bool> removeComment(String postId, String commentId) async {
    AppConfig.logger.d("");
    try {
      await postsReference.doc(postId).update({
        AppFirestoreConstants.commentIds: FieldValue.arrayRemove([commentId]),
        AppFirestoreConstants.lastInteraction: DateTime.now().millisecondsSinceEpoch,
      });
      return true;
    } catch (e) {
      AppConfig.logger.e(e.toString());
      return false;
    }
  }


  @override
  Future<Post> retrievePostForEvent(String eventId) async {
    AppConfig.logger.d("Retrieving post for Event $eventId");

    Post post = Post();

    try {
      QuerySnapshot querySnapshot = await postsReference.where(
          AppFirestoreConstants.eventId, isEqualTo: eventId).get();

      if (querySnapshot.docs.isNotEmpty) {
        AppConfig.logger.d("Snapshot is not empty");
        for (DocumentSnapshot doc in querySnapshot.docs) {
          post = Post.fromJSON(doc.data());
          post.id = doc.id;
          AppConfig.logger.d(post.toString());
        }
      }
    } catch (e) {
      AppConfig.logger.e(e.toString());
    }

    return post;
  }

  @override
  Future<Map<String, Post>> getBlogEntries({String profileId = ""}) async {
    AppConfig.logger.d("getBlogEntries");
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
            post.location = await PositionUtilities.getAddressFromPlacerMark(post.position!);
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
      AppConfig.logger.e(e.toString());
    }

    return drafts;
  }

  // Future<Map<String, Post>> getDiverseTimelineSingleCall({bool getRecent = true, bool
  // getMoreLiked = true, bool getMoreComment = true, bool getReleases = true, bool
  // getBlogEntries = true, List<String>? followingIds}) async {
  //
  //   final stopwatch = Stopwatch()..start();
  //   AppConfig.logger.d("Getting Next Timeline Posts");
  //   Map<String, Post> posts = {};
  //   List<Post> fetchedPosts = [];
  //
  //   try {
  //
  //     Query query = postsReference
  //         .orderBy(AppFirestoreConstants.createdTime, descending: true)
  //         .limit(AppConstants.diverseTimelineLimit*5);
  //     if (_recentDocTimeline.isNotEmpty) {
  //       query = query.startAfterDocument(_recentDocTimeline.last);
  //     }
  //     QuerySnapshot snapshot  = await query.get();
  //
  //     _recentDocTimeline.addAll(snapshot.docs);
  //
  //     for (var doc in snapshot.docs) {
  //       Post post = Post.fromJSON(doc.data());
  //       post.id = doc.id;
  //       if(post.location.isEmpty && post.position?.latitude != 0) {
  //         post.location = await AppUtilities.getAddressFromPlacerMark(post.position!);
  //       }
  //       posts[post.id] = post;
  //       _diverseDocTimeline[doc.id] = doc;
  //     }
  //
  //   } catch (e) {
  //     AppConfig.logger.e(e.toString());
  //   }
  //
  //   AppConfig.logger.d("Retrieveing ${posts.length} Posts");
  //   stopwatch.stop();
  //   AppConfig.logger.i('Tiempo de ejecución: ${stopwatch.elapsedMilliseconds} ms');
  //   return posts;
  // }

  @override
  Future<Map<String, Post>> getDiverseTimeline({bool getRecent = true, bool
    getMoreLiked = true, bool getMoreComment = true, bool getReleases = true, bool
    getBlogEntries = true, List<String>? followingIds}) async {

    AppConfig.logger.d("Getting Next Timeline Posts");
    Map<String, Post> posts = {};

    try {
      List<QueryDocumentSnapshot> queryDocumentSnapshots = [];
      QuerySnapshot? recentSnapshot;
      QuerySnapshot? moreLikedSnapshot;
      QuerySnapshot? moreCommentSnapshot;
      QuerySnapshot? releaseSnapshot;
      QuerySnapshot? blogSnapshot;
      QuerySnapshot? followingSnapshot;

      if(getRecent) {
        Query query = postsReference
            .orderBy(AppFirestoreConstants.lastInteraction, descending: true)
            .limit(CoreConstants.diverseTimelineLimit);
        if (_recentDocTimeline.isNotEmpty) {
          query = query.startAfterDocument(_recentDocTimeline.last);
        }
        recentSnapshot = await query.get();
      }

      if(getMoreLiked) {
        Query query = postsReference
            .orderBy(AppFirestoreConstants.likedProfiles, descending: true)
            .limit(CoreConstants.diverseTimelineLimit);
        if (_moreLikedDocTimeline.isNotEmpty) {
          query = query.startAfterDocument(_moreLikedDocTimeline.last);
        }
        moreLikedSnapshot = await query.get();
      }

      if(getMoreComment) {
        Query query = postsReference
            .orderBy(AppFirestoreConstants.commentIds, descending: true)
            .limit(CoreConstants.diverseTimelineLimit);
        if (_moreCommentsDocTimeline.isNotEmpty) {
          query = query.startAfterDocument(_moreCommentsDocTimeline.last);
        }
        moreCommentSnapshot = await query.get();
      }

      if(getReleases) {
        Query query = postsReference
            .where(AppFirestoreConstants.type, isEqualTo: PostType.releaseItem.name)
            .orderBy(AppFirestoreConstants.lastInteraction, descending: true)
            .limit(CoreConstants.diverseTimelineLimit);
        if (_releaseDocTimeline.isNotEmpty) {
          query = query.startAfterDocument(_releaseDocTimeline.last);
        }
        releaseSnapshot = await query.get();
      }

      if(getBlogEntries) {
        Query query = postsReference
            .where(AppFirestoreConstants.type, isEqualTo: PostType.blogEntry.name)
            .orderBy(AppFirestoreConstants.lastInteraction, descending: true)
            .limit(CoreConstants.diverseTimelineLimit);
        if (_blogEntriesDocTimeline.isNotEmpty) {
          query = query.startAfterDocument(_blogEntriesDocTimeline.last);
        }
        blogSnapshot = await query.get();
      }

      ///IMPROVE PAGINATION FOR FOLLOWINGIDS
      if(followingIds?.isNotEmpty ?? false) {
        int start = _followingDocTimeline.length;
        int end = (start + CoreConstants.diverseTimelineLimit < followingIds!.length)
            ? start + CoreConstants.diverseTimelineLimit : followingIds.length;

        // List<String> shuffleFollowingIds = List<String>.from(followingIds)..shuffle();
        followingIds.shuffle();
        Query query = postsReference
            .where(AppFirestoreConstants.ownerId, whereIn: followingIds.sublist(start, end))
            .orderBy(AppFirestoreConstants.lastInteraction, descending: true)
            .limit(CoreConstants.diverseTimelineLimit);
        if (_followingDocTimeline.isNotEmpty) {
          query = query.startAfterDocument(_followingDocTimeline.last);
        }
        followingSnapshot = await query.get();
      }

      // Convertir los QuerySnapshots a listas de documentos.
      List<QueryDocumentSnapshot> recentDocs = recentSnapshot?.docs ?? [];
      _recentDocTimeline.addAll(recentDocs);
      List<QueryDocumentSnapshot> moreLikeDocs = moreLikedSnapshot?.docs ?? [];
      _moreLikedDocTimeline.addAll(moreLikeDocs);
      List<QueryDocumentSnapshot> moreCommentsDoc = moreCommentSnapshot?.docs ?? [];
      _moreCommentsDocTimeline.addAll(moreCommentsDoc);
      List<QueryDocumentSnapshot> releaseDocs = releaseSnapshot?.docs ?? [];
      _releaseDocTimeline.addAll(releaseDocs);
      List<QueryDocumentSnapshot> blogDocs = blogSnapshot?.docs ?? [];
      _blogEntriesDocTimeline.addAll(blogDocs);
      List<QueryDocumentSnapshot> followingDocs = followingSnapshot?.docs ?? [];
      _followingDocTimeline.addAll(followingDocs);

      /// Encontrar el tamaño máximo entre las listas.
      int maxSize = [recentDocs.length, moreLikeDocs.length, moreCommentsDoc.length, releaseDocs.length,
        blogDocs.length, followingDocs.length].reduce((a, b) => a > b ? a : b);

      for (int i = 0; i < maxSize; i++) {
        if (i < recentDocs.length) queryDocumentSnapshots.add(recentDocs[i]);
        if (i < moreCommentsDoc.length) queryDocumentSnapshots.add(moreCommentsDoc[i]);
        if (i < followingDocs.length) queryDocumentSnapshots.add(followingDocs[i]);
        if (i < blogDocs.length) queryDocumentSnapshots.add(blogDocs[i]);
        if (i < releaseDocs.length) queryDocumentSnapshots.add(releaseDocs[i]);
        if (i < moreLikeDocs.length) queryDocumentSnapshots.add(moreLikeDocs[i]);
      }

      for(var doc in queryDocumentSnapshots) {
        if(!_diverseDocTimeline.containsKey(doc.id)) {
          Post post = Post.fromJSON(doc.data());
          post.id = doc.id;
          if(post.location.isEmpty && post.position?.latitude != 0) {
            post.location = await PositionUtilities.getAddressFromPlacerMark(post.position!);
          }
          posts[post.id] = post;
          _diverseDocTimeline[doc.id] = doc;
        }
      }
    } catch (e) {
      AppConfig.logger.e(e.toString());
    }

    AppConfig.logger.d("Retrieveing ${posts.length} Posts");
    return posts;
  }

  ///NOT NEEDED
  Future<void> updateAllPostsLastInteraction() async {
    AppConfig.logger.i("Updating lastInteraction for all posts");

    try {
      // Fetch all posts
      QuerySnapshot querySnapshot = await postsReference.get();

      // Create a batch
      WriteBatch batch = FirebaseFirestore.instance.batch();

      // Iterate through all documents and add them to the batch
      for (QueryDocumentSnapshot doc in querySnapshot.docs) {
        Post post = Post.fromJSON(doc.data());
        post.id = doc.id;

        batch.update(doc.reference, {
          AppFirestoreConstants.lastInteraction: post.createdTime,
        });
      }

      // Commit the batch
      await batch.commit();

      AppConfig.logger.d("All ${querySnapshot.docs.length} posts updated successfully.");
    } catch (e) {
      AppConfig.logger.e(e.toString());
    }
  }


}
