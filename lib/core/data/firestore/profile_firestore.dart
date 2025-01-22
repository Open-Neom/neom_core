import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';

import '../../domain/model/app_profile.dart';
import '../../domain/model/app_user.dart';
import '../../domain/model/facility.dart';
import '../../domain/model/place.dart';
import '../../domain/model/post.dart';
import '../../domain/repository/profile_repository.dart';
import '../../utils/app_utilities.dart';
import '../../utils/constants/app_constants.dart';
import '../../utils/core_utilities.dart';
import '../../utils/enums/app_currency.dart';
import '../../utils/enums/event_action.dart';
import '../../utils/enums/facilitator_type.dart';
import '../../utils/enums/place_type.dart';
import '../../utils/enums/profile_type.dart';
import '../../utils/enums/request_type.dart';
import '../../utils/enums/usage_reason.dart';
import '../../utils/enums/verification_level.dart';
import 'constants/app_firestore_collection_constants.dart';
import 'constants/app_firestore_constants.dart';
import 'facility_firestore.dart';
import 'genre_firestore.dart';
import 'instrument_firestore.dart';
import 'itemlist_firestore.dart';
import 'mate_firestore.dart';
import 'place_firestore.dart';
import 'post_firestore.dart';

class ProfileFirestore implements ProfileRepository {

  final usersReference = FirebaseFirestore.instance.collection(AppFirestoreCollectionConstants.users);
  final profileReference = FirebaseFirestore.instance.collectionGroup(AppFirestoreCollectionConstants.profiles);

  List<QueryDocumentSnapshot> _profileDocuments = [];
  Map<dynamic, AppProfile> sortedProfiles = {};
  List<String> currentProfileIds = [];

  @override
  Future<String> insert(String userId, AppProfile profile) async {

    AppUtilities.logger.i("Inserting profile ${profile.id} to Firestore");
    String profileId = "";

    try {

      AppUtilities.logger.i(profile.toJSON());

      DocumentReference documentReference = await usersReference
          .doc(userId)
          .collection(AppFirestoreCollectionConstants.profiles)
          .add(profile.toJSON());

      profileId = documentReference.id;

      if(profile.instruments != null) {
        profile.instruments!.forEach((name, instrument) async {
          await InstrumentFirestore().addInstrument(
              profileId: profileId,
              instrumentId: name);
        });
      }

      if(profile.genres != null) {
        profile.genres!.forEach((name, genre) async {
          await GenreFirestore().addGenre(
              profileId: profileId,
              genreId: name);
        });
      }

      if(profile.genres != null) {
        profile.genres!.forEach((name, genre) async {
          Map<String,dynamic> genresJSON = genre.toJSON();
          AppUtilities.logger.d(genresJSON.toString());
          await GenreFirestore().addGenre(
              profileId: profileId,
              genreId: name);
        });
      }

      if(profile.places != null) {
        profile.places!.forEach((name, place) async {
          await PlaceFirestore().addPlace(
              profileId: profileId,
              placeType: place.type);
        });
      }

      if(profile.facilities != null) {
        profile.facilities!.forEach((name, facility) async {
          await FacilityFirestore().addFacility(
              profileId: profileId,
              facilityType: facility.type);
        });
      }

      ///DEPRECATED
      // Itemlist firstlist = profile.itemlists!.values.first;
      // firstlist.ownerId = profileId;
      // await ItemlistFirestore().insert(firstlist);
      // AppUtilities.logger.i("Profile ${profile.toString()} inserted successfully.");
    } catch (e) {
      if(await remove(userId: userId, profileId: profileId)){
        AppUtilities.logger.i("Profile Rollback");
        profileId = "";
      } else {
        AppUtilities.logger.e(e.toString());
      }
    }

    return profileId;
  }

  @override
  Future<AppProfile> retrieve(String profileId) async {
    AppUtilities.logger.t("Retrieving Profile $profileId");
    AppProfile profile = AppProfile();

    try {
        QuerySnapshot querySnapshot = await profileReference.get();

        for (var profileSnapshot in querySnapshot.docs) {
          if(profileSnapshot.id == profileId) {
            profile = AppProfile.fromJSON(profileSnapshot.data());
            profile.id = profileSnapshot.id;
          }
        }

        AppUtilities.logger.t(profile.id.isNotEmpty
            ? "Profile ${profile.toString()}"
            : "Profile not found"
        );

    } catch (e) {
      AppUtilities.logger.e(e.toString());
      rethrow;
    }

    return profile;
  }


  @override
  Future<AppProfile> retrieveSimple(String profileId) async {
    AppUtilities.logger.d("Retrieving Profile $profileId");
    AppProfile profile = AppProfile();

    try {
      QuerySnapshot querySnapshot = await profileReference.get();

      for (var profileDocument in querySnapshot.docs) {
        if(profileDocument.id == profileId) {
          profile = AppProfile.fromJSON(profileDocument.data());
          profile.id = profileDocument.id;
        }
      }

      if(profile.id.isNotEmpty) {
        AppUtilities.logger.d("Profile ${profile.toString()}");
      } else {
        AppUtilities.logger.d("Profile not found");
      }
    } catch (e) {
      AppUtilities.logger.e(e.toString());
      rethrow;
    }

    return profile;
  }

  @override
  Future<List<AppProfile>> getWithParameters({
    bool needsPhone  = false, bool needsPosts = false,
    List<ProfileType>? profileTypes, FacilityType? facilityType, PlaceType? placeType,
    List<UsageReason>? usageReasons, Position? currentPosition, int maxDistance = 150, int? limit, bool isFirstCall = true}) async {

    AppUtilities.logger.d("Get profiles by parameters");

    List<AppProfile> profiles = [];

    Map<String,AppProfile> facilityProfiles = <String, AppProfile>{};
    Map<String,AppProfile> placeProfiles = <String, AppProfile>{};
    Map<String,AppProfile> noMainFacilityProfiles = <String, AppProfile>{};
    Map<String,AppProfile> noMainPlaceProfiles = <String, AppProfile>{};

    try {
      if(isFirstCall) {
        QuerySnapshot profileQuerySnapshot = await profileReference.get();
        _profileDocuments = profileQuerySnapshot.docs;
        List<AppProfile> unsortedProfiles = [];
        for (var queryDocumentSnapshot in _profileDocuments) {
          if (!queryDocumentSnapshot.exists) continue;
          AppProfile profile = AppProfile.fromJSON(queryDocumentSnapshot.data());
          profile.id = queryDocumentSnapshot.id;
          unsortedProfiles.add(profile);
        }

        if(currentPosition != null) {
          sortedProfiles = CoreUtilities.sortProfilesByLocation(currentPosition, unsortedProfiles);
        } else {
          sortedProfiles = CoreUtilities.sortProfilesByName(unsortedProfiles);
        }
        
      }

      for (var profile in sortedProfiles.values) {
      // for (var queryDocumentSnapshot in _profileDocuments) {
      //   if(!queryDocumentSnapshot.exists) continue;
        if(currentProfileIds.contains(profile.id)) continue;
        // AppProfile profile = AppProfile.fromJSON(queryDocumentSnapshot.data());
        // profile.id = queryDocumentSnapshot.id;

        if(needsPhone && profile.phoneNumber.isEmpty) {
          AppUtilities.logger.t("Profile ${profile.id} ${profile.name} - ${profile.type.name} has no phoneNumber");
          continue;
        }

        if(profileTypes != null && !profileTypes.contains(profile.type)) {
          AppUtilities.logger.t("Profile ${profile.id} ${profile.name} - ${profile.type.name} is not profile type ${profileTypes.toString()} required");
          continue;
        }

        if(usageReasons != null && (!usageReasons.contains(profile.reason) && profile.reason != UsageReason.any)) {
          AppUtilities.logger.t("Profile ${profile.id} ${profile.name} - ${profile.reason.name} has not the usage reason ${usageReasons.toString()} required");
          continue;
        }

        if(needsPosts && (profile.posts?.isEmpty ?? true)) {
          AppUtilities.logger.t("Profile ${profile.id} ${profile.name} has not posts");
          continue;
        }

        if(currentPosition != null && (profile.position != null
            && AppUtilities.distanceBetweenPositionsRounded(profile.position!, currentPosition) > maxDistance)) {
          AppUtilities.logger.t("Profile ${profile.id} ${profile.name} is out of max distance");
          continue;
        }

        List<String> postImgUrls = [];
        if(needsPosts) {
          List<Post> profilePosts = await PostFirestore().getProfilePosts(profile.id);
          for (var profilePost in profilePosts) {
            if(postImgUrls.length < 6 && profilePost.mediaUrl.isNotEmpty) {
              postImgUrls.add(profilePost.mediaUrl);
            }
          }
        }

        if(facilityType != null) {
          AppUtilities.logger.d("Retrieving Facility for ${profile.name} - ${profile.id}");
          profile.facilities = await FacilityFirestore().retrieveFacilities(profile.id);
          if(profile.facilities!.keys.contains(facilityType.value)) {
            if((profile.facilities?[facilityType.value]?.isMain == true)) {
              facilityProfiles[profile.id] = profile;
            } else {
              noMainFacilityProfiles[profile.id] = profile;
            }
          }
        } else {
          profile.facilities = {};
          profile.facilities![profile.id] = Facility();
          profile.facilities!.values.first.galleryImgUrls  = postImgUrls;
          facilityProfiles[profile.id] = profile;
        }

        if(placeType != null) {
          AppUtilities.logger.d("Retrieving Places for ${profile.name} - ${profile.id}");
          profile.places = await PlaceFirestore().retrievePlaces(profile.id);
          if(profile.places!.keys.contains(placeType.value)) {
            if((profile.places?[placeType.value]?.isMain == true)) {
              placeProfiles[profile.id] = profile;
            } else {
              noMainPlaceProfiles[profile.id] = profile;
            }
          }
        } else {
          profile.places = {};
          profile.places![profile.id] = Place();
          profile.places!.values.first.galleryImgUrls  = postImgUrls;
          placeProfiles[profile.id] = profile;
        }

        if(profile.address.isEmpty) {
          profile.address = await AppUtilities.getAddressFromPlacerMark(profile.position!);
          if(profile.address.isNotEmpty) ProfileFirestore().updateAddress(profile.id, profile.address);
        }

        currentProfileIds.add(profile.id);
        profiles.add(profile);
        if(limit != null && profiles.length >= limit) break;
      }
    } catch (e) {
      AppUtilities.logger.e(e.toString());
    }

    return profiles;
  }

  @override
  Future<bool> remove({required String userId, required String profileId}) async {
    AppUtilities.logger.d("Removing profile $profileId from Firestore");

    try {
      await usersReference.doc(userId).collection(AppFirestoreCollectionConstants.profiles).doc(profileId).delete();
      AppUtilities.logger.d("Profile $profileId removed successfully from User $userId.");
    } catch (e) {
      AppUtilities.logger.e(e);
      return false;
    }

    return true;
  }

  @override
  Future<AppProfile> retrieveFull(String profileId) async {
    AppUtilities.logger.d("Retrieving Profile $profileId");
    AppProfile profile = AppProfile();

    try {
      QuerySnapshot querySnapshot = await profileReference.get();

      for (var profileSnapshot in querySnapshot.docs) {

        if(profileId == profileSnapshot.id) {
          profile = AppProfile.fromJSON(profileSnapshot.data());
          profile.id = profileId;
        }
      }

      if(profile.id.isNotEmpty) {
        profile = await getProfileFeatures(profile);
      } else {
        AppUtilities.logger.d("Profile not found");
      }

    } catch (e) {
      AppUtilities.logger.e(e.toString());
      rethrow;
    }

    return profile;
  }

  @override
  Future<List<AppProfile>> retrieveProfiles(String userId, {ProfileType? profileType}) async {
    AppUtilities.logger.d("RetrievingProfiles");
    List<AppProfile> profiles = <AppProfile>[];

    try {
      QuerySnapshot querySnapshot = await usersReference.doc(userId)
          .collection(AppFirestoreCollectionConstants.profiles).get();

      if (querySnapshot.docs.isNotEmpty) {
        AppUtilities.logger.t("Snapshot is not empty");
        for (var profileSnapshot in querySnapshot.docs) {
          AppProfile profile = AppProfile.fromJSON(profileSnapshot.data());
          if(profileType == null || profile.type == profileType) {
            profile.id = profileSnapshot.id;
            AppUtilities.logger.t(profile.toString());
            profiles.add(profile);
          }
        }
      }
    } catch (e) {
      AppUtilities.logger.e(e.toString());
    }

    AppUtilities.logger.t("${profiles .length} profiles found");
    return profiles;
  }


  @override
  Future<Map<String,AppProfile>> retrieveProfilesByInstrument({
    String selfProfileId = "",
    Position? currentPosition,
    String instrumentId = "",
    int maxDistance = 20,
    int maxProfiles = 10,
  }) async {

    AppUtilities.logger.d("RetrievingProfiles by instrument");

    Map<String,AppProfile> mainInstrumentProfiles = <String, AppProfile>{};
    Map<String,AppProfile> noMainInstrumentProfiles = <String, AppProfile>{};

    try {
      await profileReference
          //.limit(12)
          .get().then((querySnapshot) async {
        for (var document in querySnapshot.docs) {
          AppProfile profile = AppProfile.fromJSON(document.data());
          profile.id = document.id;
          if(profile.id != selfProfileId && profile.type == ProfileType.artist
              && mainInstrumentProfiles.length < maxProfiles
          ) {

            if(AppUtilities.distanceBetweenPositionsRounded(profile.position!, currentPosition!) < maxDistance) {
              profile.instruments = await InstrumentFirestore().retrieveInstruments(profile.id);
              if(profile.instruments!.keys.contains(instrumentId)) {
                if((profile.instruments?[instrumentId]?.isMain == true)) {
                  mainInstrumentProfiles[profile.id] = profile;
                } else {
                  noMainInstrumentProfiles[profile.id] = profile;
                }
              }
            } else {
              AppUtilities.logger.d("Profile ${profile.id} is out of max distance");
            }
          }
        }

        if(mainInstrumentProfiles.length < maxProfiles && noMainInstrumentProfiles.isNotEmpty) {
          noMainInstrumentProfiles.forEach((profileId, profile) {
            if(mainInstrumentProfiles.length < maxProfiles) {
              mainInstrumentProfiles[profileId] = profile;
            }
          });
        }
      });
    } catch (e) {
    AppUtilities.logger.e(e.toString());
    }

    AppUtilities.logger.d("${mainInstrumentProfiles.length} Profiles found");
    return mainInstrumentProfiles;
  }


  @override
  Future<List<AppProfile>> retrieveProfilesFromList(List<String> profileIds) async {
    AppUtilities.logger.t("RetrievingProfiles");
    List<AppProfile> profiles = <AppProfile>[];

    try {

      QuerySnapshot querySnapshot = await profileReference.get();
      for (var profileSnapshot in querySnapshot.docs) {
        if(profileIds.contains(profileSnapshot.id)) {
          AppProfile profile = AppProfile.fromJSON(profileSnapshot.data());
          profile.id = profileSnapshot.id;
          profiles.add(profile);
        }
      }

    } catch (e) {
      AppUtilities.logger.e(e.toString());
    }


    AppUtilities.logger.d("${profiles .length} profiles found");
    return profiles;
  }

  @override
  Future<bool> followProfile({required String profileId, required String followedProfileId}) async {
    AppUtilities.logger.t("$profileId would be following $followedProfileId");

    try {
      await profileReference.get().then((querySnapshot) async {
          for (var document in querySnapshot.docs) {
            if(document.id == profileId) {
              await document.reference.update({AppFirestoreConstants.following: FieldValue.arrayUnion([followedProfileId])});
              AppUtilities.logger.d("$profileId is now following $followedProfileId");
            }

            if(document.id == followedProfileId) {
              await document.reference.update({AppFirestoreConstants.followers: FieldValue.arrayUnion([profileId])});
              AppUtilities.logger.d("$followedProfileId is now followed by $profileId");
            }
          }
        }
      );

      return true;
    } catch (e) {
      AppUtilities.logger.e(e.toString());
    }
    return false;
  }


  @override
  Future<bool> unfollowProfile({required String profileId, required String unfollowProfileId}) async {
    AppUtilities.logger.t("$profileId would be unfollowing $unfollowProfileId");

    try {
      await profileReference.get().then((querySnapshot) async {
          for (var document in querySnapshot.docs) {
            if(document.id == profileId) {
              await document.reference.update({
                AppFirestoreConstants.following: FieldValue.arrayRemove([unfollowProfileId])
              });
              AppUtilities.logger.d("$profileId is now unfollowing $unfollowProfileId");
            }

            if(document.id == unfollowProfileId) {
              await document.reference.update({
                AppFirestoreConstants.followers: FieldValue.arrayRemove([profileId])
              });
              AppUtilities.logger.d("$unfollowProfileId is now unfollowed by $profileId");
            }
          }
        }
      );

      return true;
    } catch (e) {
      AppUtilities.logger.e(e.toString());
    }
    return false;
  }


  @override
  Future<bool> blockProfile({required String profileId, required String profileToBlock}) async {
    AppUtilities.logger.d("$profileId would be unfollowing $profileToBlock");

    try {
      await profileReference.get().then((querySnapshot) async {
          for (var document in querySnapshot.docs) {
            if (document.id == profileId) {
              await document.reference.update({
                AppFirestoreConstants.following: FieldValue.arrayRemove(
                    [profileToBlock]),
                AppFirestoreConstants.blockTo: FieldValue.arrayUnion(
                    [profileToBlock])
              });
              AppUtilities.logger.d("$profileId has blocked $profileToBlock");
            }

            if (document.id == profileToBlock) {
              await document.reference.update({
                AppFirestoreConstants.followers: FieldValue.arrayRemove(
                    [profileId]),
                AppFirestoreConstants.blockedBy: FieldValue.arrayUnion(
                    [profileId])
              });
              AppUtilities.logger.d("$profileToBlock is now blocked by $profileId");
            }
          }
        }
      );

      return true;
    } catch (e) {
      AppUtilities.logger.e(e.toString());
    }
    return false;
  }


  @override
  Future<bool> unblockProfile({required String profileId, required String profileToUnblock}) async {
    AppUtilities.logger.d("$profileId would unblock $profileToUnblock");

    try {
      await profileReference.get().then((querySnapshot) async {
          for (var document in querySnapshot.docs) {
            if (document.id == profileId) {
              await document.reference.update({
                AppFirestoreConstants.blockTo: FieldValue.arrayRemove(
                    [profileToUnblock]),
              });
              AppUtilities.logger.d("$profileId has unblocked $profileToUnblock");
            }

            if (document.id == profileToUnblock) {
              await document.reference.update({
                AppFirestoreConstants.blockedBy: FieldValue.arrayRemove(
                    [profileId])
              });
              AppUtilities.logger.d("$profileToUnblock is now unblocked by $profileId");
            }
          }
        }
      );

      return true;
    } catch (e) {
      AppUtilities.logger.e(e.toString());
    }
    return false;
  }


  @override
  Future<bool> updatePosition(String profileId, Position newPosition) async {
    AppUtilities.logger.d("$profileId updating location");

    String address = await AppUtilities.getAddressFromPlacerMark(newPosition);

    try {
      await profileReference.get().then((querySnapshot) async {
        for (var document in querySnapshot.docs) {
          if (document.id == profileId) {
            await document.reference.update({
              AppFirestoreConstants.position: jsonEncode(newPosition),
              AppFirestoreConstants.address: address,
            });
          }
        }
      });

      AppUtilities.logger.d("$profileId location updated");
      return true;
    } catch (e) {
      AppUtilities.logger.e(e.toString());
    }

    return false;
  }


  @override
  Future<bool> addPost(String profileId, String postId) async {
    AppUtilities.logger.d("$profileId would add $postId");

    try {

      await profileReference.get()
          .then((querySnapshot) async {
        for (var document in querySnapshot.docs) {
          if(document.id == profileId) {
            await document.reference.update({
              AppFirestoreConstants.posts: FieldValue.arrayUnion([postId])
            });
          }
        }
      });

      AppUtilities.logger.d("Profile $profileId has post $postId");
      return true;
    } catch (e) {
      AppUtilities.logger.e(e.toString());
    }
    return false;
  }


  @override
  Future<bool> removePost(String profileId, String postId) async {
    AppUtilities.logger.t("$profileId would remove $postId");

    try {

      await profileReference.get()
          .then((querySnapshot) async {
        for (var document in querySnapshot.docs) {
          if(document.id == profileId) {
            await document.reference.update({
              AppFirestoreConstants.posts: FieldValue.arrayRemove([postId])
            });
          }
        }
      });

      AppUtilities.logger.d("$profileId has removed post $postId");
      return true;
    } catch (e) {
      AppUtilities.logger.e(e.toString());
    }
    return false;
  }


  @override
  Future<bool> hidePost(String profileId, String postId) async {
    AppUtilities.logger.d("$profileId would hide $postId");

    try {

      await profileReference.get()
          .then((querySnapshot) async {
        for (var document in querySnapshot.docs) {
          if(document.id == profileId) {
            await document.reference
              .update({
                  AppFirestoreConstants.hiddenPosts: FieldValue.arrayUnion([postId])
              });
          }
        }
      });

      AppUtilities.logger.d("Profile $profileId has hidden $postId");

    } catch (e) {
      AppUtilities.logger.e.toString();
      return false;
    }

    return true;
  }


  @override
  Future<bool> addComment(String profileId, String commentId) async {
    AppUtilities.logger.d("$profileId would add $commentId");

    try {

      await profileReference.get()
          .then((querySnapshot) async {
        for (var document in querySnapshot.docs) {
          if(document.id == profileId) {
            await document.reference
                .update(
                {
                  AppFirestoreConstants.comments: FieldValue.arrayUnion([commentId])
                }
            );
          }
        }
      });

      AppUtilities.logger.d("Profile $profileId has added $commentId");

    } catch (e) {
      AppUtilities.logger.e.toString();
      return false;
    }

    return true;
  }


  @override
  Future<bool> removeComment(String profileId, String commentId) async {
    AppUtilities.logger.d("$profileId would remove $commentId");

    try {

      await profileReference.get()
          .then((querySnapshot) async {
        for (var document in querySnapshot.docs) {
          if(document.id == profileId) {
            await document.reference
                .update(
                {
                  AppFirestoreConstants.comments: FieldValue.arrayRemove([commentId])
                }
            );
          }
        }
      });

      AppUtilities.logger.d("Profile $profileId has removed $commentId");

    } catch (e) {
      AppUtilities.logger.e.toString();
      return false;
    }

    return true;
  }


  @override
  Future<bool> hideComment(String profileId, String commentId) async {
    AppUtilities.logger.d("$profileId would hide $commentId");

    try {

      await profileReference.get()
          .then((querySnapshot) async {
        for (var document in querySnapshot.docs) {
          if(document.id == profileId) {
            await document.reference
                .update(
                {
                  AppFirestoreConstants.hiddenComments: FieldValue.arrayUnion([commentId])
                }
            );
          }
        }
      });

      AppUtilities.logger.d("Profile $profileId has hidden $commentId");

    } catch (e) {
      AppUtilities.logger.e.toString();
      return false;
    }

    return true;
  }


  @override
  Future<bool> updateName(String profileId, String profileName) async {
    AppUtilities.logger.d("Updating profile $profileId to name $profileName}");

    try {

      await profileReference.get()
          .then((querySnapshot) async {
        for (var document in querySnapshot.docs) {
          if(document.id == profileId) {
            await document.reference.update({
              AppFirestoreConstants.name: profileName,
              AppFirestoreConstants.lastNameUpdate: DateTime.now().millisecondsSinceEpoch,
            });
          }
        }
      });
      return true;
    } catch (e) {
      AppUtilities.logger.e(e.toString());
    }

    return false;
  }


  @override
  Future<bool> updateAboutMe(String profileId, String aboutMe) async {
    AppUtilities.logger.d("Updating profile $profileId to description $aboutMe}");

    try {

      await profileReference.get()
          .then((querySnapshot) async {
        for (var document in querySnapshot.docs) {
          if(document.id == profileId) {
            await document.reference.update({
              AppFirestoreConstants.aboutMe : aboutMe
            });
          }
        }
      });
      return true;
    } catch (e) {
      AppUtilities.logger.e(e.toString());

    }

    return false;
  }

  @override
  Future<bool> updateAddress(String profileId, String address) async {
    AppUtilities.logger.i("Updating Profile $profileId with new address as $address");

    try {
      await profileReference.get()
          .then((querySnapshot) async {
        for (var document in querySnapshot.docs) {
          if(document.id == profileId) {
            await document.reference.update({
              AppFirestoreConstants.address: address,
            });
          }
        }
      });
      return true;
    } catch (e) {
      AppUtilities.logger.e(e.toString());
    }

    return false;
  }

  @override
  Future<bool> updatePhoneNumber(String profileId, String phoneNumber) async {
    AppUtilities.logger.i("Updating Profile $profileId with new phoneNumber as $phoneNumber");

    try {
      await profileReference.get()
          .then((querySnapshot) async {
        for (var document in querySnapshot.docs) {
          if(document.id == profileId) {
            await document.reference.update({
              AppFirestoreConstants.phoneNumber: phoneNumber,
            });
          }
        }
      });
      return true;
    } catch (e) {
      AppUtilities.logger.e(e.toString());
    }

    return false;
  }

  @override
  Future<bool> updateType(String profileId, ProfileType type) async {
    AppUtilities.logger.i("Updating Profile $profileId with new type as ${type.name}");

    try {
      await profileReference.get()
          .then((querySnapshot) async {
        for (var document in querySnapshot.docs) {
          if(document.id == profileId) {
            await document.reference.update({
              AppFirestoreConstants.type: type.value,
            });
          }
        }
      });
      return true;
    } catch (e) {
      AppUtilities.logger.e(e.toString());
    }

    return false;
  }

  @override
  Future<bool> updateVerificationLevel(String profileId, VerificationLevel verificationLevel) async {
    AppUtilities.logger.i("Updating Profile $profileId with VerificationLevel as ${verificationLevel.name}");

    try {
      await profileReference.get()
          .then((querySnapshot) async {
        for (var document in querySnapshot.docs) {
          if(document.id == profileId) {
            await document.reference.update({
              AppFirestoreConstants.verificationLevel: verificationLevel.name,
            });
          }
        }
      });
      return true;
    } catch (e) {
      AppUtilities.logger.e(e.toString());
    }

    return false;
  }


  @override
  Future<bool> addEvent(String profileId, String eventId, EventAction eventAction) async {
    AppUtilities.logger.t("$profileId would add $eventId");

    try {

      await profileReference.get()
          .then((querySnapshot) async {
        for (var document in querySnapshot.docs) {
          if(document.id == profileId) {
            String eventListToUpdate = "";
            switch(eventAction) {
              case(EventAction.organize):
                eventListToUpdate = AppFirestoreConstants.events;
                break;
              case(EventAction.watch):
                eventListToUpdate = AppFirestoreConstants.watchingEvents;
                break;
              case(EventAction.assist):
                eventListToUpdate = AppFirestoreConstants.goingEvents;
                break;
              case(EventAction.play):
                eventListToUpdate = AppFirestoreConstants.playingEvents;
                break;
            }

            await document.reference
                .update({eventListToUpdate: FieldValue.arrayUnion([eventId])});

          }
        }
      });

      AppUtilities.logger.d("$profileId has added event $eventId");
      return true;
    } catch (e) {
      AppUtilities.logger.e(e.toString());
    }
    return false;
  }


  @override
  Future<bool> removeEvent(String profileId, String eventId, EventAction eventAction) async {
    AppUtilities.logger.t("$profileId would remove $eventId");

    try {

      await profileReference.get()
          .then((querySnapshot) async {
        for (var document in querySnapshot.docs) {

          String eventListToUpdate = "";
          switch(eventAction) {
            case(EventAction.organize):
              eventListToUpdate = AppFirestoreConstants.events;
              break;
            case(EventAction.watch):
              eventListToUpdate = AppFirestoreConstants.watchingEvents;
              break;
            case(EventAction.assist):
              eventListToUpdate = AppFirestoreConstants.goingEvents;
              break;
            case(EventAction.play):
              eventListToUpdate = AppFirestoreConstants.playingEvents;
              break;
          }

          if(document.id == profileId) {
            await document.reference.update({
              eventListToUpdate: FieldValue.arrayRemove([eventId])
            });
          }
        }
      });

      AppUtilities.logger.t("$profileId has removed event $eventId");
      return true;
    } catch (e) {
      AppUtilities.logger.e(e.toString());
    }
    return false;
  }


  @override
  Future<bool> addFavoriteItem(String profileId, String itemId) async {
    AppUtilities.logger.t("Adding item $itemId to Profile $profileId favorites");
    try {

      await profileReference.get()
          .then((querySnapshot) async {
        for (var document in querySnapshot.docs) {
          if(document.id == profileId) {
            await document.reference.update({
              AppFirestoreConstants.favoriteItems: FieldValue.arrayUnion([itemId])
            });
          }
        }
      });

    } catch (e) {
      AppUtilities.logger.e(e.toString());
      return false;
    }

    return true;
  }

  @override
  Future<bool> addFavoriteItems(String profileId, List<String> itemIds) async {
    AppUtilities.logger.t("Adding ${itemIds.length} items to Profile $profileId favorites");

    try {

      await profileReference.get()
          .then((querySnapshot) async {
        for (var document in querySnapshot.docs)  {
          if(document.id == profileId) {
            List<dynamic> currentFavorites = document.data()[AppFirestoreConstants.favoriteItems];
            List<String> updatedFavorites = List<String>.from(currentFavorites);
            for (String itemId in itemIds) {
              updatedFavorites.add(itemId);
            }
            await document.reference.update({
              AppFirestoreConstants.favoriteItems: updatedFavorites,
            });
          }
        }
      });

    } catch (e) {
      AppUtilities.logger.e(e.toString());
      return false;
    }

    return true;
  }

  @override
  Future<bool> removeFavoriteItem(String profileId, String itemId) async {
    AppUtilities.logger.t("Removing item $itemId from Profile $profileId favorites");

    try {

      await profileReference.get()
          .then((querySnapshot) async {
        for (var document in querySnapshot.docs)  {
          if(document.id == profileId) {
            await document.reference.update({
              AppFirestoreConstants.favoriteItems: FieldValue.arrayRemove([itemId])
            });
          }
        }
      });

    } catch (e) {
      AppUtilities.logger.e(e.toString());
      return false;
    }

    return true;
  }

  @override
  Future<bool> removeFavoriteItems(String profileId, List<String> itemIds) async {
    AppUtilities.logger.t("Removing ${itemIds.length} items from Profile $profileId favorites");

    try {

      await profileReference.get()
          .then((querySnapshot) async {
        for (var document in querySnapshot.docs)  {
          if(document.id == profileId) {
            // await document.reference.update({
            //   AppFirestoreConstants.favoriteItems: FieldValue.arrayRemove([itemId])
            // });

            List<dynamic> currentFavorites = document.data()[AppFirestoreConstants.favoriteItems];
            List<String> updatedFavorites = List<String>.from(currentFavorites);
            for (String itemId in itemIds) {
              updatedFavorites.remove(itemId);
            }
            await document.reference.update({
              AppFirestoreConstants.favoriteItems: updatedFavorites,
            });
          }
        }
      });

    } catch (e) {
      AppUtilities.logger.e(e.toString());
      return false;
    }

    return true;
  }
  
  @override
  Future<bool> addChamberPreset({required String profileId, required String chamberPresetId}) async {
    AppUtilities.logger.d("Adding preset $chamberPresetId to Profile $profileId");
    try {

      await profileReference.get()
          .then((querySnapshot) async {
        for (var document in querySnapshot.docs) {
          if(document.id == profileId) {
            await document.reference.update({
              AppFirestoreConstants.chamberPresets: FieldValue.arrayUnion([chamberPresetId])
            });
          }
        }
      });

    } catch (e) {
      AppUtilities.logger.e(e.toString());
      return false;
    }

    return true;
  }

  @override
  Future<bool> addBand({required String profileId, required String bandId}) async {
    AppUtilities.logger.t("Add band $bandId for profile $profileId from firestore");
    try {

      await profileReference.get()
          .then((querySnapshot) async {
        for (var document in querySnapshot.docs) {
          if(document.id == profileId) {
            await document.reference.update({
              AppFirestoreConstants.bands: FieldValue.arrayUnion([bandId])
            });
          }
        }
      });

    } catch (e) {
      AppUtilities.logger.e(e.toString());
      return false;
    }

    return true;
  }


  @override
  Future<bool> removeBand({required String profileId, required String bandId}) async {
    AppUtilities.logger.t("Remove band $bandId for profile $profileId from firestore");

    try {

      await profileReference.get()
          .then((querySnapshot) async {
        for (var document in querySnapshot.docs)  {
          if(document.id == profileId) {
            await document.reference.update({
              AppFirestoreConstants.bands: FieldValue.arrayRemove([bandId])
            });
          }
        }
      });

    } catch (e) {
      AppUtilities.logger.e(e.toString());
      return false;
    }

    return true;
  }

  ///DEPRECATED
  // @override
  // Future<bool> addAllAppMediaItemIds(String profileId, List<String> itemIds) async {
  //   AppUtilities.logger.d("");
  //   try {
  //
  //     await profileReference.get()
  //         .then((querySnapshot) async {
  //       for (var document in querySnapshot.docs) {
  //         if(document.id == profileId) {
  //           await document.reference.update({
  //             AppFirestoreConstants.appMediaItems: itemIds
  //           });
  //         }
  //       }
  //     });
  //
  //   } catch (e) {
  //     AppUtilities.logger.e(e.toString());
  //     return false;
  //   }
  //
  //   return true;
  // }


  @override
  Future<Map<String,AppProfile>> retrieveAllProfiles({int limit = 0}) async {
    AppUtilities.logger.d("RetrievingProfiles");
    Map<String,AppProfile> profiles = <String, AppProfile>{};

    try {
      if(limit <= 0) limit = AppConstants.profilesLimit;
      final querySnapshot = await profileReference.limit(limit).get();

      profiles = {
        for (var document in querySnapshot.docs)
          if (document.data().containsKey('name')) document.id: AppProfile.fromJSON(document.data())..id = document.id
      };
      //
      // for (var document in querySnapshot.docs) {
      //   if(document.data()['name'] != null) {
      //     AppProfile profile = AppProfile.fromJSON(document.data());
      //     profile.id = document.id;
      //     profiles[profile.id] = profile;
      //   }
      // }

    } catch (e) {
      AppUtilities.logger.e(e.toString());
    }

    AppUtilities.logger.d("${profiles .length} profiles found");
    return profiles;
  }


  @override
  Future<bool> addRequest(String profileId, String requestId, RequestType requestType) async {
    AppUtilities.logger.t("$profileId would add $requestId");

    try {

      await profileReference.get()
          .then((querySnapshot) async {
        for (var document in querySnapshot.docs) {
          if(document.id == profileId) {
              String requestsToUpdate = "";

              switch(requestType) {
                case(RequestType.received):
                  requestsToUpdate = AppFirestoreConstants.requests;
                  break;
                case(RequestType.sent):
                  requestsToUpdate = AppFirestoreConstants.sentRequests;
                  break;
                case(RequestType.invitation):
                  requestsToUpdate = AppFirestoreConstants.invitationRequests;
                  break;
              }

            await document.reference
                .update({
                  requestsToUpdate: FieldValue.arrayUnion([requestId])
                });
          }
        }
      });

      AppUtilities.logger.d("Profile $profileId has added request $requestId as type ${requestType.name}");

    } catch (e) {
      AppUtilities.logger.e.toString();
      return false;
    }

    return true;
  }


  @override
  Future<bool> removeRequest(String profileId, String requestId, RequestType requestType) async {
    AppUtilities.logger.d("$profileId would remove $requestId");

    try {

      await profileReference.get()
          .then((querySnapshot) async {
        for (var document in querySnapshot.docs) {
          if(document.id == profileId) {
            String requestsToRemove = "";

            switch(requestType) {
              case(RequestType.received):
                requestsToRemove = AppFirestoreConstants.requests;
                break;
              case(RequestType.sent):
                requestsToRemove = AppFirestoreConstants.sentRequests;
                break;
              case(RequestType.invitation):
                requestsToRemove = AppFirestoreConstants.invitationRequests;
                break;
            }
            await document.reference
                .update({
                  requestsToRemove: FieldValue.arrayRemove([requestId])
                });
          }
        }
      });

      AppUtilities.logger.d("Profile $profileId has removed request $requestId");

    } catch (e) {
      AppUtilities.logger.e(e.toString());
      return false;
    }

    return true;
  }


  @override
  Future<Map<String, AppProfile>> getFollowers(String profileId) async {
    AppUtilities.logger.d("Start getFollowers for $profileId");

    AppProfile profile = AppProfile();
    Map<String, AppProfile> followersMap = {};
    try {
      await profileReference.get().then((querySnapshot) async {
        for (var document in querySnapshot.docs) {
          if (document.id == profileId) {
            profile = AppProfile.fromJSON(document.data());
            profile.id = document.id;
          }
        }
      });

      for (var followerId in profile.followers!) {
        AppProfile follower = await MateFirestore().getMateSimple(followerId)!;
        follower.instruments = await InstrumentFirestore().retrieveInstruments(followerId);
        followersMap[followerId] = follower;
      }

      AppUtilities.logger.d("${followersMap.length} Followers found");

    } catch (e) {
      AppUtilities.logger.e(e.toString());
      rethrow;
    }
    return followersMap;
  }


  @override
  Future<Map<String, AppProfile>> getFollowed(String profileId) async {
    AppUtilities.logger.d("Start getFollowed for $profileId");

    AppProfile profile = AppProfile();
    Map<String, AppProfile> followedMap = {};
    try {
      await profileReference.get().then((querySnapshot) async {
        for (var document in querySnapshot.docs) {
          if (document.id == profileId) {
            profile = AppProfile.fromJSON(document.data());
            profile.id = document.id;
          }
        }
      });

      for (var followedId in profile.following!) {
        AppProfile followed = await MateFirestore().getMateSimple(followedId)!;
        followed.instruments = await InstrumentFirestore().retrieveInstruments(followedId);
        followedMap[followedId] = followed;
      }

      AppUtilities.logger.d("${followedMap.length} Followed found");

    } catch (e) {
      AppUtilities.logger.e(e.toString());
      rethrow;
    }
    return followedMap;
  }


  @override
  Future<bool> addToWallet(String profileId, double amount, {AppCurrency appCurrency = AppCurrency.appCoin}) async {

    AppUtilities.logger.d("addToWallet from ProfileFirestore for profileID $profileId");
    String userId = "";
    AppUser user = AppUser();
    QuerySnapshot userQuerySnapshot;
    QueryDocumentSnapshot? userQueryDocumentSnapshot;

    try {

      QuerySnapshot querySnapshot = await profileReference.get();

      for (var profile in querySnapshot.docs) {
        if(profile.id == profileId) {
          AppUtilities.logger.i("Reference id: ${profile.reference.parent.parent!.id}");
          DocumentReference documentReference = profile.reference;
          userId = documentReference.parent.parent!.id;

          userQuerySnapshot = await usersReference.where(FieldPath.documentId, isEqualTo: userId).get();
          AppUtilities.logger.i("${userQuerySnapshot.docs.length} users found");

          for (var doc in userQuerySnapshot.docs) {
            user = AppUser.fromJSON(doc.data());
            user.id = doc.id;
            userQueryDocumentSnapshot = doc;
          }
        }
      }

      if(!userQueryDocumentSnapshot!.exists) {
        userQuerySnapshot = await usersReference.get();
        for (var doc in userQuerySnapshot.docs) {
          if(doc.exists) {
            QuerySnapshot profileQuerySnapshot = await doc.reference
                .collection(AppFirestoreCollectionConstants.profiles)
                .get();

            if (profileQuerySnapshot.docs.isNotEmpty) {
              AppUtilities.logger.d("Profiles were found for userId ${doc.id}");

              for (var profileSnapshot in profileQuerySnapshot.docs) {
                if (profileSnapshot.id == profileId) {
                  AppUtilities.logger.d("Profile $profileId was found for userId ${doc.id} ");
                  user = AppUser.fromJSON(doc.data());
                  user.id = doc.id;
                  userQueryDocumentSnapshot = doc;
                }
              }
            } else {
              AppUtilities.logger.i("No user found");
            }
          }
        }
      }

      if (userQueryDocumentSnapshot?.exists ?? false) {
        if (user.id.isNotEmpty) {
          double newAmount = user.wallet.amount + amount;
          AppUtilities.logger.i("Updating UserWallet from ${user.wallet.amount} to $newAmount");
          user.wallet.amount = newAmount;
          await userQueryDocumentSnapshot!.reference.update({
            AppFirestoreConstants.wallet: user.wallet.toJSON()
          });
          AppUtilities.logger.d("User Wallet updated");
          return true;
        }
      }
    } catch (e) {
      AppUtilities.logger.e(e.toString());
    }

    return false;
  }


  @override
  Future<bool> subtractFromWallet(String profileId, double amount, {AppCurrency appCurrency = AppCurrency.appCoin}) async {

    AppUtilities.logger.d("Entering substractToWallet method from ProfileFirestore");
    String userId = "";
    AppUser user = AppUser();
    QuerySnapshot userQuerySnapshot;
    QueryDocumentSnapshot? userQueryDocumentSnapshot;

    try {

      QuerySnapshot querySnapshot = await profileReference.get();

      for (var profile in querySnapshot.docs) {
        if(profile.id == profileId) {
          AppUtilities.logger.i("Reference id: ${profile.reference.parent.parent!.id}");
          DocumentReference documentReference = profile.reference;
          userId = documentReference.parent.parent!.id;

          userQuerySnapshot = await usersReference.where(FieldPath.documentId, isEqualTo: userId).get();
          AppUtilities.logger.i("${userQuerySnapshot.docs.length} users found");

          for (var doc in userQuerySnapshot.docs) {
            user = AppUser.fromJSON(doc.data());
            user.id = doc.id;
            userQueryDocumentSnapshot = doc;
          }

        }
      }

      if(!userQueryDocumentSnapshot!.exists) {
        userQuerySnapshot = await usersReference.get();
        for (var doc in userQuerySnapshot.docs) {
          if (doc.exists) {
            QuerySnapshot profileQuerySnapshot = await doc.reference
                .collection(AppFirestoreCollectionConstants.profiles)
                .get();

            if (profileQuerySnapshot.docs.isNotEmpty) {
              AppUtilities.logger.d("Profiles were found for userId ${doc.id}");

              for (var profileSnapshot in profileQuerySnapshot.docs) {
                if (profileSnapshot.id == profileId) {
                  AppUtilities.logger.d("Profile $profileId was found for userId ${doc.id} ");
                  user = AppUser.fromJSON(doc.data());
                  user.id = doc.id;
                  userQueryDocumentSnapshot = doc;
                }
              }
            } else {
              AppUtilities.logger.i("No user found");
            }
          }
        }
      }

      if (userQueryDocumentSnapshot?.exists ?? false) {
        if (user.id.isNotEmpty) {
          user.wallet.amount = user.wallet.amount - amount;
          await userQueryDocumentSnapshot!.reference.update({
            AppFirestoreConstants.wallet: user.wallet.toJSON()
          });
          AppUtilities.logger.d("User Wallet updated");
          return true;
        }
      }
    } catch (e) {
      AppUtilities.logger.e(e.toString());
    }

    return false;
  }


  @override
  Future<bool> updatePhotoUrl(String profileId, String photoUrl) async {
    AppUtilities.logger.d("");

    try {

      await profileReference.get()
          .then((querySnapshot) async {
        for (var document in querySnapshot.docs) {
          if(document.id == profileId) {
            await document.reference.update({
              AppFirestoreConstants.photoUrl: photoUrl
            });
          }
        }
      });

    } catch (e) {
      AppUtilities.logger.e(e.toString());
      return false;
    }

    return true;
  }


  @override
  Future<bool> updateCoverImgUrl(String profileId, String coverImgUrl) async {
    AppUtilities.logger.d("");

    try {

      await profileReference.get()
          .then((querySnapshot) async {
        for (var document in querySnapshot.docs) {
          if(document.id == profileId) {
            await document.reference.update({
              AppFirestoreConstants.coverImgUrl: coverImgUrl
            });
          }
        }
      });

    } catch (e) {
      AppUtilities.logger.e(e.toString());
      return false;
    }

    return true;
  }

  @override
  Future<QuerySnapshot<Object?>> handleSearch(String query) {
    // TODO: implement handleSearch
    throw UnimplementedError();
  }


  Future<String> retrievedFcmToken(String profileId) async {
    AppUtilities.logger.t("Retrieving FCM Token for Profile $profileId");

    String userId = "";
    String fcmToken = "";
    QuerySnapshot userQuerySnapshot;

    try {

      QuerySnapshot querySnapshot = await profileReference.get();

      for (var profile in querySnapshot.docs) {
        if(profile.id == profileId) {
          AppUtilities.logger.t("Reference id: ${profile.reference.parent.parent?.id ?? ""}");
          DocumentReference documentReference = profile.reference;
          userId = documentReference.parent.parent?.id ?? "";

          if(userId.isNotEmpty) {
            userQuerySnapshot = await usersReference.where(
                FieldPath.documentId, isEqualTo: userId).get();
            if(userQuerySnapshot.docs.isNotEmpty) {
              AppUtilities.logger.t("${userQuerySnapshot.docs.length} users found");
              fcmToken = AppUser.fromJSON(userQuerySnapshot.docs.first.data()).fcmToken;
              AppUtilities.logger.t("FCM Token $fcmToken");
            } else {
              AppUtilities.logger.w("No user found for id $userId");
            }

          }
        }
      }
    } catch (e) {
      AppUtilities.logger.e(e.toString());
    }

    if(fcmToken.isEmpty) {
      AppUtilities.logger.w("Push Notification not send as FCM Token was not found for users device");
    }

    return fcmToken;
  }


  @override
  Future<bool> isAvailableName(String profileName) async {
    AppUtilities.logger.d("Verify if name $profileName is available to create this profile");

    try {
      QuerySnapshot querySnapshot = await profileReference.get();

      if (querySnapshot.docs.isNotEmpty) {
        for(QueryDocumentSnapshot doc in querySnapshot.docs) {
          if(profileName == AppProfile.fromJSON(doc.data()).name) {
            AppUtilities.logger.w("Profile Name already in use");
            return false;
          }
        }
      }

    } catch (e) {
      AppUtilities.logger.e(e.toString());
      return false;
    }

    AppUtilities.logger.d("No profiles found");
    return true;
  }

  Future<AppProfile> getProfileFeatures(AppProfile profile) async {

    try {
      if(profile.type == ProfileType.artist) {
        profile.instruments = await InstrumentFirestore().retrieveInstruments(profile.id);
        if(profile.instruments!.isEmpty) {
          AppUtilities.logger.w("Instruments not found");
        }
      }

      if(profile.type == ProfileType.host) {
        profile.places = await PlaceFirestore().retrievePlaces(profile.id);
        if(profile.places!.isEmpty) {
          AppUtilities.logger.t("Places not found");
        }
      }

      if(profile.type == ProfileType.facilitator) {
        profile.facilities = await FacilityFirestore().retrieveFacilities(profile.id);
        if(profile.facilities!.isEmpty) {
          AppUtilities.logger.w("Facilities not found");
        }
      }

      profile.genres = await GenreFirestore().retrieveGenres(profile.id);
      profile.itemlists = await ItemlistFirestore().getByOwnerId(profile.id);
      if(profile.genres!.isEmpty) AppUtilities.logger.t("Genres not found");
      if(profile.itemlists!.isEmpty) AppUtilities.logger.t("Itemlists not found");

    } catch(e) {
      AppUtilities.logger.e(e.toString());
    }

    return profile;
  }
  
  @override
  Future<bool> updateLastSpotifySync(String profileId) async {
    AppUtilities.logger.d("Updating Spotify Last Sync for profile $profileId");

    try {
      await profileReference.get()
          .then((querySnapshot) async {
          for (var document in querySnapshot.docs) {
            if(document.id == profileId) {
              await document.reference.update({
                AppFirestoreConstants.lastSpotifySync : DateTime.now().millisecondsSinceEpoch
              });
            }
          }
        });
      return true;
    } catch (e) {
      AppUtilities.logger.e(e.toString());
    }

    return false;
  }

  @override
  Future<bool> addBlogEntry(String profileId, String blogEntryId) async {
    AppUtilities.logger.d("$profileId would add $blogEntryId");

    try {

      await profileReference.get()
          .then((querySnapshot) async {
        for (var document in querySnapshot.docs) {
          if(document.id == profileId) {
            await document.reference.update({
              AppFirestoreConstants.blogEntries: FieldValue.arrayUnion([blogEntryId])
            });
          }
        }
      });

      AppUtilities.logger.d("Profile $profileId has blogEntry $blogEntryId");
      return true;
    } catch (e) {
      AppUtilities.logger.e(e.toString());
    }
    return false;
  }


  @override
  Future<bool> removeBlogEntry(String profileId, String blogEntryId) async {
    AppUtilities.logger.d("$profileId would remove $blogEntryId");

    try {

      await profileReference.get()
          .then((querySnapshot) async {
        for (var document in querySnapshot.docs) {
          if(document.id == profileId) {
            await document.reference.update({
              AppFirestoreConstants.blogEntries: FieldValue.arrayRemove([blogEntryId])
            });
          }
        }
      });

      AppUtilities.logger.d("$profileId has removed blogEntry $blogEntryId");
      return true;
    } catch (e) {
      AppUtilities.logger.e(e.toString());
    }
    return false;
  }

  @override
  Future<bool> removeAllFavoriteItems(String profileId) async {
    AppUtilities.logger.d("");

    try {
      await profileReference.get()
          .then((querySnapshot) async {
        for (var document in querySnapshot.docs)  {
          // if(document.id == profileId) {
            await document.reference.update({
              AppFirestoreConstants.favoriteItems: FieldValue.delete()
            });
            AppUtilities.logger.w("Deleting");
          // }
        }
      });

    } catch (e) {
      AppUtilities.logger.e(e.toString());
      return false;
    }

    return true;
  }


  @override
  Future<Map<String, AppProfile>> retrieveProfilesByFacility({
    required String selfProfileId,
    required Position? currentPosition,

    FacilityType? facilityType,
    int maxDistance = 30,
    int maxProfiles = 30}) async {

    AppUtilities.logger.d("RetrievingProfiles by facility");

    Map<String,AppProfile> facilityProfiles = <String, AppProfile>{};
    Map<String,AppProfile> noMainFacilityProfiles = <String, AppProfile>{};

    try {
      await profileReference.get().then((querySnapshot) async {
        for (var document in querySnapshot.docs) {
          AppProfile profile = AppProfile.fromJSON(document.data());
          profile.id = document.id;
          if(profile.id != selfProfileId && profile.type == ProfileType.facilitator
              && facilityProfiles.length < maxProfiles
          ) {
            if(AppUtilities.distanceBetweenPositionsRounded(profile.position!, currentPosition!) < maxDistance) {
              if(profile.address.isEmpty && profile.position != null) {
                profile.address = await AppUtilities.getAddressFromPlacerMark(profile.position!);
              }
              if(profile.posts?.isNotEmpty ?? false) {
                List<Post> profilePosts = await PostFirestore().getProfilePosts(profile.id);
                List<String> postImgUrls = [];
                for (var element in profilePosts) {
                  if(postImgUrls.length < 6) {
                    postImgUrls.add(element.mediaUrl);
                  }
                }

                if(facilityType != null) {
                  profile.facilities = await FacilityFirestore().retrieveFacilities(profile.id);
                  if(profile.facilities!.keys.contains(facilityType.value)) {
                    if((profile.facilities?[facilityType.value]?.isMain == true)) {
                      facilityProfiles[profile.id] = profile;
                    } else {
                      noMainFacilityProfiles[profile.id] = profile;
                    }
                  }
                } else {
                  profile.facilities = {};
                  profile.facilities![profile.id] = Facility();
                  profile.facilities!.values.first.galleryImgUrls  = postImgUrls;
                  facilityProfiles[profile.id] = profile;
                }
              } else {
                AppUtilities.logger.d("Profile ${profile.id} ${profile.name} has not posts");
              }

            } else {
              AppUtilities.logger.d("Profile ${profile.id} ${profile.name} is out of max distance");
            }
          }
        }

        if(facilityProfiles.length < maxProfiles && noMainFacilityProfiles.isNotEmpty) {
          noMainFacilityProfiles.forEach((profileId, profile) {
            if(facilityProfiles.length < maxProfiles) {
              facilityProfiles[profileId] = profile;
            }
          });
        }
      });
    } catch (e) {
      AppUtilities.logger.e(e.toString());
    }

    AppUtilities.logger.d("${facilityProfiles.length} Profiles found");
    return facilityProfiles;
  }

  @override
  Future<Map<String, AppProfile>> retrieveProfilesByPlace({
    required String selfProfileId,
    required Position? currentPosition,

    PlaceType? placeType,
    int maxDistance = 30,
    int maxProfiles = 30}) async {

    AppUtilities.logger.d("RetrievingProfiles by place");

    Map<String,AppProfile> hostProfiles = <String, AppProfile>{};
    Map<String,AppProfile> noMainPlaceProfiles = <String, AppProfile>{};

    try {
      await profileReference.get().then((querySnapshot) async {
        for (var document in querySnapshot.docs) {
          AppProfile profile = AppProfile.fromJSON(document.data());
          profile.id = document.id;
          if(profile.id != selfProfileId && profile.type == ProfileType.host
              && hostProfiles.length < maxProfiles
          ) {
            if(AppUtilities.distanceBetweenPositionsRounded(profile.position!, currentPosition!) < maxDistance) {
              if(profile.address.isEmpty && profile.position != null) {
                profile.address = await AppUtilities.getAddressFromPlacerMark(profile.position!);
              }
              if(profile.posts?.isNotEmpty ?? false) {
                List<Post> profilePosts = await PostFirestore().getProfilePosts(profile.id);
                List<String> postImgUrls = [];
                for (var element in profilePosts) {
                  if(postImgUrls.length < 6) {
                    postImgUrls.add(element.mediaUrl);
                  }
                }

                if(placeType != null) {
                  profile.facilities = await FacilityFirestore().retrieveFacilities(profile.id);
                  if(profile.facilities!.keys.contains(placeType.value)) {
                    if((profile.facilities?[placeType.value]?.isMain == true)) {
                      hostProfiles[profile.id] = profile;
                    } else {
                      noMainPlaceProfiles[profile.id] = profile;
                    }
                  }
                } else {
                  profile.facilities = {};
                  profile.facilities![profile.id] = Facility();
                  profile.facilities!.values.first.galleryImgUrls  = postImgUrls;
                  hostProfiles[profile.id] = profile;
                }
              } else {
                AppUtilities.logger.d("Profile ${profile.id} ${profile.name} has not posts");
              }

            } else {
              AppUtilities.logger.d("Profile ${profile.id} ${profile.name} is out of max distance");
            }
          }
        }

        if(hostProfiles.length < maxProfiles && noMainPlaceProfiles.isNotEmpty) {
          noMainPlaceProfiles.forEach((profileId, profile) {
            if(hostProfiles.length < maxProfiles) {
              hostProfiles[profileId] = profile;
            }
          });
        }
      });
    } catch (e) {
      AppUtilities.logger.e(e.toString());
    }

    AppUtilities.logger.d("${hostProfiles.length} Profiles found");
    return hostProfiles;
  }

}
