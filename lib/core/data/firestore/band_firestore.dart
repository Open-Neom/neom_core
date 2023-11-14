
import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/model/band.dart';
import '../../domain/model/band_member.dart';
import '../../domain/model/genre.dart';
import '../../domain/repository/band_repository.dart';
import '../../utils/app_utilities.dart';
import '../../utils/enums/owner_type.dart';
import 'constants/app_firestore_collection_constants.dart';
import 'constants/app_firestore_constants.dart';
import 'itemlist_firestore.dart';
import 'profile_firestore.dart';
import 'request_firestore.dart';

class BandFirestore implements BandRepository {

  var logger = AppUtilities.logger;
  final bandsReference = FirebaseFirestore.instance.collection(AppFirestoreCollectionConstants.bands);

  @override
  Future<Band> retrieve(String bandId) async {
    logger.t("Retrieving Bands from firestore");
    Band band = Band();

    try {
      DocumentSnapshot documentSnapshot = await bandsReference.doc(bandId).get();
      if (documentSnapshot.exists) {
        band = Band.fromJSON(documentSnapshot.data());
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


  @override
  Future<String> insert(Band band) async {
    logger.d("");
    String bandId = "";
    try {
      DocumentReference documentReference = await bandsReference.add(band.toJSON());
      bandId = documentReference.id;

      for (var bandMember in band.members!.values) {
        if(await addMemberToBand(bandMember, bandId) && bandMember.profileId.isNotEmpty) {
          if(await ProfileFirestore().addBand(profileId: bandMember.profileId, bandId: bandId)){
            logger.i("Band added to Profile ${bandMember.profileId}");
          }
        }
      }

      for (var genre in band.genres!.values) {
        if(await addGenreToBand(genre, bandId)) {
          logger.i("Genre ${genre.name} added to Band $bandId");
        } else {
          logger.i("Genre ${genre.name} was not added to Band $bandId");
        }
      }
    } catch (e) {
      logger.e(e.toString());
    }

    return bandId;
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


  @override
  Future<bool> remove(Band band) async {
    logger.d("");
    bool wasDeleted = false;
    try {

      await bandsReference.doc(band.id).delete();

      for (var bandMemberId in band.members!.keys) {
        BandMember bandMember = band.members?[bandMemberId] ?? BandMember();

        if(bandMemberId == bandMember.profileId) {
          if(await ProfileFirestore().removeBand(profileId: bandMember.profileId, bandId: band.id)){
            wasDeleted = true;
            logger.i("Band remove from Profile $bandMemberId");
          } else {
            logger.i("Band could not be removed from Profile $bandMemberId");
            wasDeleted = false;
          }
        }

        await RequestFirestore().removeBandRequests(band.id);
      }

    } catch (e) {
      logger.e(e.toString());
    }

    return wasDeleted;
  }


  @override
  Future<Map<String, Band>> getBands() async {
    logger.d("");
    Map<String, Band> bands = {};

    try {
      QuerySnapshot snapshot = await bandsReference
          .orderBy(AppFirestoreConstants.createdTime, descending: true)
          .get();

      logger.d("${snapshot.docs.length} Bands Found as Snapshot");
      for (var documentSnapshot in snapshot.docs) {
        Band band = Band.fromJSON(documentSnapshot.data());
        band.id = documentSnapshot.id;

        band.members = await getBandMembers(band.id);
        band.itemlists = await ItemlistFirestore().fetchAll(ownerId: band.id, ownerType: OwnerType.band);
        bands[band.id] = band;
      }


      logger.d("${bands.length} Bands Found");
    } catch (e) {
      logger.e(e.toString());
    }

    return bands;
  }


  @override
  Future<Map<String, Band>> getBandsFromList(List<String> bandIds) async {
    logger.d("Retrieving ${bandIds.length} bands from list");
    Map<String, Band> bands = {};

    try {
      QuerySnapshot snapshot = await bandsReference
          .orderBy(AppFirestoreConstants.createdTime, descending: true)
          .get();

      logger.d("${snapshot.docs.length} Bands Found as Snapshot");
      for (var documentSnapshot in snapshot.docs) {
        if(bandIds.contains(documentSnapshot.id)) {
          Band band = Band.fromJSON(documentSnapshot.data());
          band.id = documentSnapshot.id;
          band.members = await getBandMembers(band.id);
          band.itemlists = await ItemlistFirestore().fetchAll(ownerId: band.id, ownerType: OwnerType.band);
          bands[band.id] = band;
        }
      }

      logger.d("${bands.length} Bands Found");
    } catch (e) {
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
          BandMember bandMember = BandMember.fromJSON(bandMemberSnapshot.data());
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

  @override
  Future<bool> addPlayingEvent(String bandId, String eventId) async {
    logger.t("$bandId would add event $eventId");

    try {

      await bandsReference.get()
          .then((querySnapshot) async {
        for (var document in querySnapshot.docs) {
          if(bandId == document.id) {
            String eventListToUpdate = "";
            eventListToUpdate = AppFirestoreConstants.playingEvents;
            await document.reference
                .update({eventListToUpdate: FieldValue.arrayUnion([eventId])});

          }
        }
      });

      logger.d("$bandId has added event $eventId");
      return true;
    } catch (e) {
      logger.e(e.toString());
    }
    return false;
  }

  @override
  Future<bool> addPlayingEventToBands(List<String> bandIds, String eventId) async {
    logger.d("$bandIds would add $eventId");

    try {

      await bandsReference.get()
          .then((querySnapshot) async {
        for (var document in querySnapshot.docs) {
          if(bandIds.contains(document.id)) {
            String eventListToUpdate = "";
            eventListToUpdate = AppFirestoreConstants.playingEvents;
            await document.reference
                .update({eventListToUpdate: FieldValue.arrayUnion([eventId])});

          }
        }
      });

      logger.d("$bandIds has added event $eventId");
      return true;
    } catch (e) {
      logger.e(e.toString());
    }
    return false;
  }


  @override
  Future<bool> removePlayingEvent(String bandId, String eventId) async {
    logger.d("Band $bandId would remove event $eventId");

    try {

      await bandsReference.get()
          .then((querySnapshot) async {
        for (var document in querySnapshot.docs) {
          if(bandId == document.id) {
            String eventListToUpdate = "";
            eventListToUpdate = AppFirestoreConstants.playingEvents;
            await document.reference
                .update({eventListToUpdate: FieldValue.arrayRemove([eventId])});

          }
          logger.d("${document.id} has removed event $eventId");
        }
      });


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
