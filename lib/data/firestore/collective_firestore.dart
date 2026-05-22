
import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../app_config.dart';
import '../../domain/model/collective.dart';
import '../../domain/model/collective_member.dart';
import '../../domain/model/genre.dart';
import '../../domain/repository/collective_repository.dart';

import '../../utils/enums/owner_type.dart';
import 'constants/app_firestore_collection_constants.dart';
import 'constants/app_firestore_constants.dart';
import 'itemlist_firestore.dart';
import 'profile_firestore.dart';
import 'request_firestore.dart';

class CollectiveFirestore implements CollectiveRepository {

  var logger = AppConfig.logger;
  final collectivesReference = FirebaseFirestore.instance.collection(AppFirestoreCollectionConstants.collectives);

  @override
  Future<Collective> retrieve(String collectiveId) async {
    logger.t("Retrieving Collectives from firestore");
    Collective collective = Collective();

    try {
      DocumentSnapshot documentSnapshot = await collectivesReference.doc(collectiveId).get();
      // FIXED: Added null check after .data()
      if (documentSnapshot.exists && documentSnapshot.data() != null) {
        collective = Collective.fromJSON(documentSnapshot.data() as Map<String, dynamic>);
        collective.id = documentSnapshot.id;
        collective.members = await getCollectiveMembers(collective.id);
        collective.itemlists = await ItemlistFirestore().fetchAll(ownerId: collective.id, ownerType: OwnerType.collective);
        logger.t(collective.name);
      }
    } catch (e) {
      logger.e(e.toString());
    }


    return collective;
  }


  Future<Collective?> getBySlug(String slug) async {
    if (slug.isEmpty) return null;
    try {
      final querySnapshot = await collectivesReference
          .where('slug', isEqualTo: slug)
          .limit(1)
          .get();
      if (querySnapshot.docs.isNotEmpty) {
        final doc = querySnapshot.docs.first;
        final collective = Collective.fromJSON(doc.data());
        collective.id = doc.id;
        return collective;
      }
    } catch (e) {
      logger.e("getBySlug error: $e");
    }
    return null;
  }

  /// OPTIMIZED: Batch operations in parallel instead of sequential N+1
  @override
  Future<String> insert(Collective collective) async {
    logger.d("Inserting collective ${collective.name}");
    String collectiveId = "";
    try {
      // Auto-generate slug if empty
      if (collective.slug.isEmpty && collective.name.isNotEmpty) {
        final titleSlug = Collective.generateSlug(collective.name);
        final existing = await getBySlug(titleSlug);
        final emailPrefix = collective.email.contains('@') ? collective.email.split('@').first : collective.email;
        collective.slug = existing == null ? titleSlug : Collective.generateSlug('$emailPrefix ${collective.name}');
      }

      DocumentReference documentReference = await collectivesReference.add(collective.toJSON());
      collectiveId = documentReference.id;

      final List<Future> operations = [];

      // OPTIMIZATION: Add all members in parallel
      if (collective.members != null) {
        for (var collectiveMember in collective.members!.values) {
          operations.add(
            _addMemberAndUpdateProfile(collectiveMember, collectiveId)
          );
        }
      }

      // OPTIMIZATION: Add all genres in parallel
      if (collective.genres != null) {
        for (var genre in collective.genres!.values) {
          operations.add(addGenreToCollective(genre, collectiveId));
        }
      }

      await Future.wait(operations);
      logger.i("Collective $collectiveId inserted with ${collective.members?.length ?? 0} members and ${collective.genres?.length ?? 0} genres");
    } catch (e) {
      logger.e(e.toString());
    }

    return collectiveId;
  }

  /// Helper to add member and update profile in one operation
  Future<void> _addMemberAndUpdateProfile(CollectiveMember collectiveMember, String collectiveId) async {
    if (await addMemberToCollective(collectiveMember, collectiveId) && collectiveMember.profileId.isNotEmpty) {
      await ProfileFirestore().addCollective(profileId: collectiveMember.profileId, collectiveId: collectiveId);
    }
  }


  Future<bool> addMemberToCollective(CollectiveMember collectiveMember, String collectiveId) async {
    logger.d("Adding member to collective $collectiveId");
    bool addedMember = false;

    try {

      DocumentSnapshot documentSnapshot = await collectivesReference.doc(collectiveId).get();
      await documentSnapshot.reference
          .collection(AppFirestoreCollectionConstants.members)
          .add(collectiveMember.toJSON());

      addedMember = true;

    } catch (e) {
      logger.e(e.toString());
    }
    await Future.delayed(const Duration(seconds: 1));
    addedMember ? logger.d("Member was added to collective $collectiveId") :
    logger.d("Member was not added to collective $collectiveId");
    return addedMember;
  }


  /// OPTIMIZED: Parallel operations + removeCollectiveRequests called once (not N times)
  @override
  Future<bool> remove(Collective collective) async {
    logger.d("Removing collective ${collective.id}");
    bool wasDeleted = false;
    try {
      final List<Future> operations = [];

      // Delete collective document
      operations.add(collectivesReference.doc(collective.id).delete());

      // OPTIMIZATION: Remove collective requests ONCE, not once per member
      operations.add(RequestFirestore().removeCollectiveRequests(collective.id));

      // OPTIMIZATION: Remove collective from all member profiles in parallel
      for (var collectiveMemberId in collective.members!.keys) {
        CollectiveMember collectiveMember = collective.members?[collectiveMemberId] ?? CollectiveMember();
        if (collectiveMemberId == collectiveMember.profileId && collectiveMember.profileId.isNotEmpty) {
          operations.add(
            ProfileFirestore().removeCollective(profileId: collectiveMember.profileId, collectiveId: collective.id)
          );
        }
      }

      await Future.wait(operations);
      wasDeleted = true;
      logger.i("Collective ${collective.id} removed successfully");

    } catch (e) {
      logger.e(e.toString());
    }

    return wasDeleted;
  }


  /// OPTIMIZED: Added limit parameter to prevent full collection scan
  /// Also loads members in parallel instead of sequential N+1
  @override
  Future<Map<String, Collective>> getCollectives({int limit = 20}) async {
    logger.d("Getting collectives with limit: $limit");
    Map<String, Collective> collectives = {};

    try {
      QuerySnapshot snapshot = await collectivesReference
          .orderBy(AppFirestoreConstants.createdTime, descending: true)
          .limit(limit)  // OPTIMIZATION: Prevent full collection scan
          .get();

      logger.d("${snapshot.docs.length} Collectives Found as Snapshot");

      // OPTIMIZATION: First collect all collectives without members
      final List<Collective> collectiveList = [];
      for (var documentSnapshot in snapshot.docs) {
        final data = documentSnapshot.data();
        if (data == null) continue;
        Collective collective = Collective.fromJSON(data as Map<String, dynamic>);
        collective.id = documentSnapshot.id;
        collectiveList.add(collective);
      }

      // OPTIMIZATION: Load members in parallel instead of sequential N+1
      final memberFutures = collectiveList.map((b) => getCollectiveMembers(b.id));
      final memberResults = await Future.wait(memberFutures);

      for (int i = 0; i < collectiveList.length; i++) {
        collectiveList[i].members = memberResults[i];
        // Note: itemlists loading deferred - can be loaded on demand when viewing collective details
        collectives[collectiveList[i].id] = collectiveList[i];
      }

      logger.d("${collectives.length} Collectives Found");
    } catch (e) {
      logger.e(e.toString());
    }

    return collectives;
  }


  /// OPTIMIZED: Use whereIn instead of full collection scan + client filter
  @override
  Future<Map<String, Collective>> getCollectivesFromList(List<String> collectiveIds) async {
    logger.d("Retrieving ${collectiveIds.length} collectives from list");
    Map<String, Collective> collectives = {};

    if (collectiveIds.isEmpty) return collectives;

    try {
      // OPTIMIZATION: Use whereIn batches instead of scanning entire collection
      const batchSize = 10; // Firestore whereIn limit
      final List<Collective> collectiveList = [];

      for (var i = 0; i < collectiveIds.length; i += batchSize) {
        final batch = collectiveIds.skip(i).take(batchSize).toList();
        QuerySnapshot snapshot = await collectivesReference
            .where(FieldPath.documentId, whereIn: batch)
            .get();

        for (var documentSnapshot in snapshot.docs) {
          final data = documentSnapshot.data();
          if (data == null) continue;
          Collective collective = Collective.fromJSON(data as Map<String, dynamic>);
          collective.id = documentSnapshot.id;
          collectiveList.add(collective);
        }
      }

      // OPTIMIZATION: Load members in parallel
      if (collectiveList.isNotEmpty) {
        final memberFutures = collectiveList.map((b) => getCollectiveMembers(b.id));
        final memberResults = await Future.wait(memberFutures);

        for (int i = 0; i < collectiveList.length; i++) {
          collectiveList[i].members = memberResults[i];
          collectives[collectiveList[i].id] = collectiveList[i];
        }
      }

      logger.d("${collectives.length} Collectives Found");
    } catch (e) {
      logger.d("${collectives.length} Collectives Found");
      logger.e(e.toString());
    }

    return collectives;
  }



  @override
  Future<bool> fulfillCollectiveMember(String collectiveId, CollectiveMember collectiveMember) async {
    logger.d("Fulfilling collectiveMember ${collectiveMember.name} for collective $collectiveId");

    try {
      await collectivesReference.doc(collectiveId).get()
          .then((querySnapshot) async {
        await querySnapshot.reference
            .collection(AppFirestoreCollectionConstants.members)
            .doc(collectiveMember.id)
            .update({
              AppFirestoreConstants.imgUrl: collectiveMember.imgUrl,
              AppFirestoreConstants.name: collectiveMember.name,
              AppFirestoreConstants.profileId: collectiveMember.profileId,
            });
          });
      await ProfileFirestore().addCollective(profileId: collectiveMember.profileId, collectiveId: collectiveId);
      logger.i("CollectiveMember ${collectiveMember.name} has been fulfilled");
    } catch (e) {
      logger.e(e.toString());
      return false;
    }

    return true;
  }


  @override
  Future<bool> unfulfillCollectiveMember(String collectiveId, CollectiveMember collectiveMember) async {

    logger.d("Unfulfilling collectiveMember ${collectiveMember.name} for collective $collectiveId");

    try {
      await collectivesReference.doc(collectiveId).get()
          .then((querySnapshot) async {
        await querySnapshot.reference
            .collection(AppFirestoreCollectionConstants.members)
            .doc(collectiveMember.id)
            .update({
              AppFirestoreConstants.imgUrl: "",
              AppFirestoreConstants.name: "",
              AppFirestoreConstants.profileId: "",
            });
        }
      );
      await ProfileFirestore().removeCollective(profileId: collectiveMember.profileId, collectiveId: collectiveId);
      logger.i("CollectiveMember ${collectiveMember.name} has been unfulfilled");
    } catch (e) {
      logger.e(e.toString());
      return false;
    }

    return true;
  }

  @override
  Future<bool> removeCollectiveMember(String collectiveId, CollectiveMember collectiveMember) async {

    logger.d("Removing collectiveMember ${collectiveMember.name} for collective $collectiveId");

    try {

      await collectivesReference.doc(collectiveId).get()
          .then((querySnapshot) async {
        await querySnapshot.reference
            .collection(AppFirestoreCollectionConstants.members)
            .doc(collectiveMember.id).delete();
      });

      await ProfileFirestore().removeCollective(profileId: collectiveMember.profileId, collectiveId: collectiveId);
      logger.i("CollectiveMember ${collectiveMember.name} has been removed");
    } catch (e) {
      logger.e(e.toString());
      return false;
    }

    return true;
  }

  @override
  Future<bool> isAvailableName(String collectiveName) async {

    logger.d("Verify if name $collectiveName is available to create this collective");

    try {
      QuerySnapshot querySnapshot = await collectivesReference.where(
          AppFirestoreConstants.name,
          isEqualTo: collectiveName).get();

      if (querySnapshot.docs.isNotEmpty) {
        logger.i("Collective Name already in use");
        return false;
      }

    } catch (e) {
      logger.e(e.toString());
      return false;
    }

    logger.d("No Collectives found");
    return true;
  }


  Future<Map<String,CollectiveMember>> getCollectiveMembers(String collectiveId) async {
    logger.t("getCollectiveMembers on firestore");

    Map<String,CollectiveMember> collectiveMembers = {};

    try {
      QuerySnapshot querySnapshot = await collectivesReference.doc(collectiveId)
          .collection(AppFirestoreCollectionConstants.members).get();
      if (querySnapshot.docs.isNotEmpty) {
        for (var collectiveMemberSnapshot in querySnapshot.docs) {
          // FIXED: Added null check after .data()
          final data = collectiveMemberSnapshot.data();
          if (data == null) continue;
          CollectiveMember collectiveMember = CollectiveMember.fromJSON(data as Map<String, dynamic>);
          collectiveMember.id = collectiveMemberSnapshot.id;
          logger.t('Collective member ${collectiveMember.instrument?.name} - ${collectiveMember.name.isNotEmpty
              ? collectiveMember.name : 'unfulfilled'} - retrieved for collective $collectiveId');

          ///TO VERIFY IF DEPRECATED
          // collectiveMembers[collectiveMember.profileId.isNotEmpty
          //     ? collectiveMember.profileId
          //     : collectiveMember.instrument!.id] = collectiveMember;

          collectiveMembers[collectiveMember.id] = collectiveMember;
        }
        logger.d("${collectiveMembers.length} members retrieved for collective $collectiveId");
      } else {
        logger.d("No collective members found for collective $collectiveId");
      }
    } catch (e) {
      logger.e(e.toString());
    }

    return collectiveMembers;
  }


  Future<Map<String,Genre>> getCollectiveGenres(String collectiveId) async {
    logger.t("Get genres for collective $collectiveId");

    Map<String,Genre> collectiveGenres = {};

    try {
      QuerySnapshot querySnapshot = await collectivesReference.doc(collectiveId)
          .collection(AppFirestoreCollectionConstants.genres)
          .get();
      if (querySnapshot.docs.isNotEmpty) {
        for (var collectiveMemberSnapshot in querySnapshot.docs) {
          Genre genre = Genre.fromQueryDocumentSnapshot(collectiveMemberSnapshot);
          logger.t(genre.name);

          collectiveGenres[genre.name] = genre;
        }
        logger.d("${collectiveGenres.length} genres retrieved");
      } else {
        logger.d("No collective genres found");
      }
    } catch (e) {
      logger.e(e.toString());
    }

    return collectiveGenres;
  }


  Future<bool> addGenreToCollective(Genre genre, String collectiveId) async {

    logger.d("Adding genre to collective $collectiveId");
    bool addedGenre = false;

    try {

      DocumentSnapshot documentSnapshot = await collectivesReference.doc(collectiveId).get();
      await documentSnapshot.reference
          .collection(AppFirestoreCollectionConstants.genres)
          .add(genre.toJSON());

      addedGenre = true;

    } catch (e) {
      logger.e(e.toString());
    }
    await Future.delayed(const Duration(seconds: 1));
    addedGenre ? logger.d("Genre was added to collective $collectiveId") :
    logger.d("Genre was not added to collective $collectiveId");
    return addedGenre;
  }

  /// OPTIMIZED: Direct document access instead of scanning all collectives
  @override
  Future<bool> addPlayingEvent(String collectiveId, String eventId) async {
    logger.t("$collectiveId would add event $eventId");

    try {
      // OPTIMIZATION: Direct document update instead of full collection scan
      await collectivesReference.doc(collectiveId).update({
        AppFirestoreConstants.playingEvents: FieldValue.arrayUnion([eventId])
      });

      logger.d("$collectiveId has added event $eventId");
      return true;
    } catch (e) {
      logger.e(e.toString());
    }
    return false;
  }

  /// OPTIMIZED: Direct document updates in parallel instead of scanning all collectives
  @override
  Future<bool> addPlayingEventToCollectives(List<String> collectiveIds, String eventId) async {
    logger.d("$collectiveIds would add $eventId");

    if (collectiveIds.isEmpty) return true;

    try {
      // OPTIMIZATION: Update each collective directly in parallel
      final updates = collectiveIds.map((collectiveId) =>
        collectivesReference.doc(collectiveId).update({
          AppFirestoreConstants.playingEvents: FieldValue.arrayUnion([eventId])
        })
      );

      await Future.wait(updates);

      logger.d("$collectiveIds has added event $eventId");
      return true;
    } catch (e) {
      logger.e(e.toString());
    }
    return false;
  }


  /// OPTIMIZED: Direct document access instead of scanning all collectives
  @override
  Future<bool> removePlayingEvent(String collectiveId, String eventId) async {
    logger.d("Collective $collectiveId would remove event $eventId");

    try {
      // OPTIMIZATION: Direct document update instead of full collection scan
      await collectivesReference.doc(collectiveId).update({
        AppFirestoreConstants.playingEvents: FieldValue.arrayRemove([eventId])
      });

      logger.d("$collectiveId has removed event $eventId");
      return true;
    } catch (e) {
      logger.e(e.toString());
    }
    return false;
  }


  ///DEPRECATED
  // @override
  // Future<bool> addAppMediaItem(String collectiveId, String itemId) async {
  //   logger.d("");
  //   try {
  //
  //     await collectivesReference.get()
  //         .then((querySnapshot) async {
  //       for (var document in querySnapshot.docs) {
  //         if(document.id == collectiveId) {
  //           await document.reference.update({
  //             AppFirestoreConstants.appMediaItems: FieldValue.arrayUnion([itemId])
  //           });
  //         }
  //       }
  //     });
  //
  //   } catch (e) {
  //     logger.e(e.toString());
  //     return false;
  //   }
  //
  //   return true;
  // }
  //
  //
  // @override
  // Future<bool> removeItem(String collectiveId, String itemId) async {
  //   logger.d("");
  //   try {
  //
  //     await collectivesReference.get()
  //         .then((querySnapshot) async {
  //       for (var document in querySnapshot.docs) {
  //         if(document.id == collectiveId) {
  //           await document.reference.update({
  //             AppFirestoreConstants.appMediaItems: FieldValue.arrayRemove([itemId])
  //           });
  //         }
  //       }
  //     });
  //
  //   } catch (e) {
  //     logger.e(e.toString());
  //     return false;
  //   }
  //
  //   return true;
  // }

}
