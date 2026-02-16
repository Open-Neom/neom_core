
import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../app_config.dart';
import '../../domain/model/band.dart';
import '../../domain/model/band_member.dart';
import '../../domain/model/genre.dart';
import '../../domain/repository/band_repository.dart';

import '../../utils/enums/owner_type.dart';
import 'constants/app_firestore_collection_constants.dart';
import 'constants/app_firestore_constants.dart';
import 'itemlist_firestore.dart';
import 'profile_firestore.dart';
import 'request_firestore.dart';

class BandFirestore implements BandRepository {

  var logger = AppConfig.logger;
  final bandsReference = FirebaseFirestore.instance.collection(AppFirestoreCollectionConstants.bands);

  @override
  Future<Band> retrieve(String bandId) async {
    logger.t("Retrieving Bands from firestore");
    Band band = Band();

    try {
      DocumentSnapshot documentSnapshot = await bandsReference.doc(bandId).get();
      // FIXED: Added null check after .data()
      if (documentSnapshot.exists && documentSnapshot.data() != null) {
        band = Band.fromJSON(documentSnapshot.data() as Map<String, dynamic>);
        band.id = documentSnapshot.id;
        band.members = await getBandMembers(band.id);
        band.itemlists = await ItemlistFirestore().fetchAll(ownerId: band.id, ownerType: OwnerType.band);
        logger.t(band.name);
      }
    } catch (e) {
      logger.e(e.toString());
    }


    return band;
  }


  /// OPTIMIZED: Batch operations in parallel instead of sequential N+1
  @override
  Future<String> insert(Band band) async {
    logger.d("Inserting band ${band.name}");
    String bandId = "";
    try {
      DocumentReference documentReference = await bandsReference.add(band.toJSON());
      bandId = documentReference.id;

      final List<Future> operations = [];

      // OPTIMIZATION: Add all members in parallel
      if (band.members != null) {
        for (var bandMember in band.members!.values) {
          operations.add(
            _addMemberAndUpdateProfile(bandMember, bandId)
          );
        }
      }

      // OPTIMIZATION: Add all genres in parallel
      if (band.genres != null) {
        for (var genre in band.genres!.values) {
          operations.add(addGenreToBand(genre, bandId));
        }
      }

      await Future.wait(operations);
      logger.i("Band $bandId inserted with ${band.members?.length ?? 0} members and ${band.genres?.length ?? 0} genres");
    } catch (e) {
      logger.e(e.toString());
    }

    return bandId;
  }

  /// Helper to add member and update profile in one operation
  Future<void> _addMemberAndUpdateProfile(BandMember bandMember, String bandId) async {
    if (await addMemberToBand(bandMember, bandId) && bandMember.profileId.isNotEmpty) {
      await ProfileFirestore().addBand(profileId: bandMember.profileId, bandId: bandId);
    }
  }


  Future<bool> addMemberToBand(BandMember bandMember, String bandId) async {
    logger.d("Adding member to band $bandId");
    bool addedMember = false;

    try {

      DocumentSnapshot documentSnapshot = await bandsReference.doc(bandId).get();
      await documentSnapshot.reference
          .collection(AppFirestoreCollectionConstants.members)
          .add(bandMember.toJSON());

      addedMember = true;

    } catch (e) {
      logger.e(e.toString());
    }
    await Future.delayed(const Duration(seconds: 1));
    addedMember ? logger.d("Member was added to band $bandId") :
    logger.d("Member was not added to band $bandId");
    return addedMember;
  }


  /// OPTIMIZED: Parallel operations + removeBandRequests called once (not N times)
  @override
  Future<bool> remove(Band band) async {
    logger.d("Removing band ${band.id}");
    bool wasDeleted = false;
    try {
      final List<Future> operations = [];

      // Delete band document
      operations.add(bandsReference.doc(band.id).delete());

      // OPTIMIZATION: Remove band requests ONCE, not once per member
      operations.add(RequestFirestore().removeBandRequests(band.id));

      // OPTIMIZATION: Remove band from all member profiles in parallel
      for (var bandMemberId in band.members!.keys) {
        BandMember bandMember = band.members?[bandMemberId] ?? BandMember();
        if (bandMemberId == bandMember.profileId && bandMember.profileId.isNotEmpty) {
          operations.add(
            ProfileFirestore().removeBand(profileId: bandMember.profileId, bandId: band.id)
          );
        }
      }

      await Future.wait(operations);
      wasDeleted = true;
      logger.i("Band ${band.id} removed successfully");

    } catch (e) {
      logger.e(e.toString());
    }

    return wasDeleted;
  }


  /// OPTIMIZED: Added limit parameter to prevent full collection scan
  /// Also loads members in parallel instead of sequential N+1
  @override
  Future<Map<String, Band>> getBands({int limit = 20}) async {
    logger.d("Getting bands with limit: $limit");
    Map<String, Band> bands = {};

    try {
      QuerySnapshot snapshot = await bandsReference
          .orderBy(AppFirestoreConstants.createdTime, descending: true)
          .limit(limit)  // OPTIMIZATION: Prevent full collection scan
          .get();

      logger.d("${snapshot.docs.length} Bands Found as Snapshot");

      // OPTIMIZATION: First collect all bands without members
      final List<Band> bandList = [];
      for (var documentSnapshot in snapshot.docs) {
        final data = documentSnapshot.data();
        if (data == null) continue;
        Band band = Band.fromJSON(data as Map<String, dynamic>);
        band.id = documentSnapshot.id;
        bandList.add(band);
      }

      // OPTIMIZATION: Load members in parallel instead of sequential N+1
      final memberFutures = bandList.map((b) => getBandMembers(b.id));
      final memberResults = await Future.wait(memberFutures);

      for (int i = 0; i < bandList.length; i++) {
        bandList[i].members = memberResults[i];
        // Note: itemlists loading deferred - can be loaded on demand when viewing band details
        bands[bandList[i].id] = bandList[i];
      }

      logger.d("${bands.length} Bands Found");
    } catch (e) {
      logger.e(e.toString());
    }

    return bands;
  }


  /// OPTIMIZED: Use whereIn instead of full collection scan + client filter
  @override
  Future<Map<String, Band>> getBandsFromList(List<String> bandIds) async {
    logger.d("Retrieving ${bandIds.length} bands from list");
    Map<String, Band> bands = {};

    if (bandIds.isEmpty) return bands;

    try {
      // OPTIMIZATION: Use whereIn batches instead of scanning entire collection
      const batchSize = 10; // Firestore whereIn limit
      final List<Band> bandList = [];

      for (var i = 0; i < bandIds.length; i += batchSize) {
        final batch = bandIds.skip(i).take(batchSize).toList();
        QuerySnapshot snapshot = await bandsReference
            .where(FieldPath.documentId, whereIn: batch)
            .get();

        for (var documentSnapshot in snapshot.docs) {
          final data = documentSnapshot.data();
          if (data == null) continue;
          Band band = Band.fromJSON(data as Map<String, dynamic>);
          band.id = documentSnapshot.id;
          bandList.add(band);
        }
      }

      // OPTIMIZATION: Load members in parallel
      if (bandList.isNotEmpty) {
        final memberFutures = bandList.map((b) => getBandMembers(b.id));
        final memberResults = await Future.wait(memberFutures);

        for (int i = 0; i < bandList.length; i++) {
          bandList[i].members = memberResults[i];
          bands[bandList[i].id] = bandList[i];
        }
      }

      logger.d("${bands.length} Bands Found");
    } catch (e) {
      logger.d("${bands.length} Bands Found");
      logger.e(e.toString());
    }

    return bands;
  }



  @override
  Future<bool> fulfillBandMember(String bandId, BandMember bandMember) async {
    logger.d("Fulfilling bandMember ${bandMember.name} for band $bandId");

    try {
      await bandsReference.doc(bandId).get()
          .then((querySnapshot) async {
        await querySnapshot.reference
            .collection(AppFirestoreCollectionConstants.members)
            .doc(bandMember.id)
            .update({
              AppFirestoreConstants.imgUrl: bandMember.imgUrl,
              AppFirestoreConstants.name: bandMember.name,
              AppFirestoreConstants.profileId: bandMember.profileId,
            });
          });
      await ProfileFirestore().addBand(profileId: bandMember.profileId, bandId: bandId);
      logger.i("BandMember ${bandMember.name} has been fulfilled");
    } catch (e) {
      logger.e(e.toString());
      return false;
    }

    return true;
  }


  @override
  Future<bool> unfulfillBandMember(String bandId, BandMember bandMember) async {

    logger.d("Unfulfilling bandMember ${bandMember.name} for band $bandId");

    try {
      await bandsReference.doc(bandId).get()
          .then((querySnapshot) async {
        await querySnapshot.reference
            .collection(AppFirestoreCollectionConstants.members)
            .doc(bandMember.id)
            .update({
              AppFirestoreConstants.imgUrl: "",
              AppFirestoreConstants.name: "",
              AppFirestoreConstants.profileId: "",
            });
        }
      );
      await ProfileFirestore().removeBand(profileId: bandMember.profileId, bandId: bandId);
      logger.i("BandMember ${bandMember.name} has been unfulfilled");
    } catch (e) {
      logger.e(e.toString());
      return false;
    }

    return true;
  }

  @override
  Future<bool> removeBandMember(String bandId, BandMember bandMember) async {

    logger.d("Removing bandMember ${bandMember.name} for band $bandId");

    try {

      await bandsReference.doc(bandId).get()
          .then((querySnapshot) async {
        await querySnapshot.reference
            .collection(AppFirestoreCollectionConstants.members)
            .doc(bandMember.id).delete();
      });

      await ProfileFirestore().removeBand(profileId: bandMember.profileId, bandId: bandId);
      logger.i("BandMember ${bandMember.name} has been removed");
    } catch (e) {
      logger.e(e.toString());
      return false;
    }

    return true;
  }

  @override
  Future<bool> isAvailableName(String bandName) async {

    logger.d("Verify if name $bandName is available to create this band");

    try {
      QuerySnapshot querySnapshot = await bandsReference.where(
          AppFirestoreConstants.name,
          isEqualTo: bandName).get();

      if (querySnapshot.docs.isNotEmpty) {
        logger.i("Band Name already in use");
        return false;
      }

    } catch (e) {
      logger.e(e.toString());
      return false;
    }

    logger.d("No Bands found");
    return true;
  }


  Future<Map<String,BandMember>> getBandMembers(String bandId) async {
    logger.t("getBandMembers on firestore");

    Map<String,BandMember> bandMembers = {};

    try {
      QuerySnapshot querySnapshot = await bandsReference.doc(bandId)
          .collection(AppFirestoreCollectionConstants.members).get();
      if (querySnapshot.docs.isNotEmpty) {
        for (var bandMemberSnapshot in querySnapshot.docs) {
          // FIXED: Added null check after .data()
          final data = bandMemberSnapshot.data();
          if (data == null) continue;
          BandMember bandMember = BandMember.fromJSON(data as Map<String, dynamic>);
          bandMember.id = bandMemberSnapshot.id;
          logger.t('Band member ${bandMember.instrument?.name} - ${bandMember.name.isNotEmpty
              ? bandMember.name : 'unfulfilled'} - retrieved for band $bandId');

          ///TO VERIFY IF DEPRECATED
          // bandMembers[bandMember.profileId.isNotEmpty
          //     ? bandMember.profileId
          //     : bandMember.instrument!.id] = bandMember;

          bandMembers[bandMember.id] = bandMember;
        }
        logger.d("${bandMembers.length} members retrieved for band $bandId");
      } else {
        logger.d("No band members found for band $bandId");
      }
    } catch (e) {
      logger.e(e.toString());
    }

    return bandMembers;
  }


  Future<Map<String,Genre>> getBandGenres(String bandId) async {
    logger.t("Get genres for band $bandId");

    Map<String,Genre> bandGenres = {};

    try {
      QuerySnapshot querySnapshot = await bandsReference.doc(bandId)
          .collection(AppFirestoreCollectionConstants.genres)
          .get();
      if (querySnapshot.docs.isNotEmpty) {
        for (var bandMemberSnapshot in querySnapshot.docs) {
          Genre genre = Genre.fromQueryDocumentSnapshot(bandMemberSnapshot);
          logger.t(genre.name);

          bandGenres[genre.name] = genre;
        }
        logger.d("${bandGenres.length} genres retrieved");
      } else {
        logger.d("No band genres found");
      }
    } catch (e) {
      logger.e(e.toString());
    }

    return bandGenres;
  }


  Future<bool> addGenreToBand(Genre genre, String bandId) async {

    logger.d("Adding genre to band $bandId");
    bool addedGenre = false;

    try {

      DocumentSnapshot documentSnapshot = await bandsReference.doc(bandId).get();
      await documentSnapshot.reference
          .collection(AppFirestoreCollectionConstants.genres)
          .add(genre.toJSON());

      addedGenre = true;

    } catch (e) {
      logger.e(e.toString());
    }
    await Future.delayed(const Duration(seconds: 1));
    addedGenre ? logger.d("Genre was added to band $bandId") :
    logger.d("Genre was not added to band $bandId");
    return addedGenre;
  }

  /// OPTIMIZED: Direct document access instead of scanning all bands
  @override
  Future<bool> addPlayingEvent(String bandId, String eventId) async {
    logger.t("$bandId would add event $eventId");

    try {
      // OPTIMIZATION: Direct document update instead of full collection scan
      await bandsReference.doc(bandId).update({
        AppFirestoreConstants.playingEvents: FieldValue.arrayUnion([eventId])
      });

      logger.d("$bandId has added event $eventId");
      return true;
    } catch (e) {
      logger.e(e.toString());
    }
    return false;
  }

  /// OPTIMIZED: Direct document updates in parallel instead of scanning all bands
  @override
  Future<bool> addPlayingEventToBands(List<String> bandIds, String eventId) async {
    logger.d("$bandIds would add $eventId");

    if (bandIds.isEmpty) return true;

    try {
      // OPTIMIZATION: Update each band directly in parallel
      final updates = bandIds.map((bandId) =>
        bandsReference.doc(bandId).update({
          AppFirestoreConstants.playingEvents: FieldValue.arrayUnion([eventId])
        })
      );

      await Future.wait(updates);

      logger.d("$bandIds has added event $eventId");
      return true;
    } catch (e) {
      logger.e(e.toString());
    }
    return false;
  }


  /// OPTIMIZED: Direct document access instead of scanning all bands
  @override
  Future<bool> removePlayingEvent(String bandId, String eventId) async {
    logger.d("Band $bandId would remove event $eventId");

    try {
      // OPTIMIZATION: Direct document update instead of full collection scan
      await bandsReference.doc(bandId).update({
        AppFirestoreConstants.playingEvents: FieldValue.arrayRemove([eventId])
      });

      logger.d("$bandId has removed event $eventId");
      return true;
    } catch (e) {
      logger.e(e.toString());
    }
    return false;
  }


  ///DEPRECATED
  // @override
  // Future<bool> addAppMediaItem(String bandId, String itemId) async {
  //   logger.d("");
  //   try {
  //
  //     await bandsReference.get()
  //         .then((querySnapshot) async {
  //       for (var document in querySnapshot.docs) {
  //         if(document.id == bandId) {
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
  // Future<bool> removeItem(String bandId, String itemId) async {
  //   logger.d("");
  //   try {
  //
  //     await bandsReference.get()
  //         .then((querySnapshot) async {
  //       for (var document in querySnapshot.docs) {
  //         if(document.id == bandId) {
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
