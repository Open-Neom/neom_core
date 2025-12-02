import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';

import '../../app_config.dart';
import '../../domain/model/app_profile.dart';
import '../../domain/model/app_user.dart';
import '../../domain/model/facility.dart';
import '../../domain/model/place.dart';
import '../../domain/model/post.dart';
import '../../domain/repository/chamber_repository.dart';
import '../../domain/repository/profile_repository.dart';
import '../../utils/constants/core_constants.dart';
import '../../utils/core_utilities.dart';
import '../../utils/enums/app_in_use.dart';
import '../../utils/enums/event_action.dart';
import '../../utils/enums/facilitator_type.dart';
import '../../utils/enums/place_type.dart';
import '../../utils/enums/profile_type.dart';
import '../../utils/enums/request_type.dart';
import '../../utils/enums/usage_reason.dart';
import '../../utils/enums/verification_level.dart';
import '../../utils/position_utilities.dart';
import 'constants/app_firestore_collection_constants.dart';
import 'constants/app_firestore_constants.dart';
import 'facility_firestore.dart';
import 'genre_firestore.dart';
import 'instrument_firestore.dart';
import 'itemlist_firestore.dart';
import 'mate_firestore.dart';
import 'place_firestore.dart';
import 'post_firestore.dart';
import 'user_firestore.dart';

class ProfileFirestore implements ProfileRepository {

  final usersReference = FirebaseFirestore.instance.collection(
      AppFirestoreCollectionConstants.users);
  final profileReference = FirebaseFirestore.instance.collectionGroup(
      AppFirestoreCollectionConstants.profiles);

  List<QueryDocumentSnapshot> _profileDocuments = [];
  Map<dynamic, AppProfile> sortedProfiles = {};
  List<String> currentProfileIds = [];
  Map<String, AppProfile> profiles = <String, AppProfile>{};

  @override
  Future<String> insert(String userId, AppProfile profile) async {
    AppConfig.logger.d("Inserting profile ${profile.id} to Firestore");
    String profileId = "";

    try {
      AppConfig.logger.t(profile.toJSON());

      DocumentReference documentReference = await usersReference
          .doc(userId)
          .collection(AppFirestoreCollectionConstants.profiles)
          .add(profile.toJSON());

      profileId = documentReference.id;

      if (profile.instruments != null) {
        profile.instruments!.forEach((name, instrument) async {
          await InstrumentFirestore().addInstrument(
              profileId: profileId,
              instrumentId: name);
        });
      }

      if (profile.genres != null) {
        profile.genres!.forEach((name, genre) async {
          await GenreFirestore().addGenre(
              profileId: profileId,
              genreId: name);
        });
      }

      if (profile.genres != null) {
        profile.genres!.forEach((name, genre) async {
          Map<String, dynamic> genresJSON = genre.toJSON();
          AppConfig.logger.d(genresJSON.toString());
          await GenreFirestore().addGenre(
              profileId: profileId,
              genreId: name);
        });
      }

      if (profile.places != null) {
        profile.places!.forEach((name, place) async {
          await PlaceFirestore().addPlace(
              profileId: profileId,
              placeType: place.type);
        });
      }

      if (profile.facilities != null) {
        profile.facilities!.forEach((name, facility) async {
          await FacilityFirestore().addFacility(
              profileId: profileId,
              facilityType: facility.type);
        });
      }
    } catch (e) {
      if (await remove(userId: userId, profileId: profileId)) {
        AppConfig.logger.i("Profile Rollback");
        profileId = "";
      } else {
        AppConfig.logger.e(e.toString());
      }
    }

    return profileId;
  }

  @override
  Future<AppProfile> retrieve(String profileId) async {
    AppConfig.logger.t("Retrieving Profile $profileId");
    AppProfile profile = AppProfile();

    try {
      QuerySnapshot querySnapshot = await profileReference.get();

      for (var profileSnapshot in querySnapshot.docs) {
        if (profileSnapshot.id == profileId) {
          profile = AppProfile.fromJSON(profileSnapshot.data());
          profile.id = profileSnapshot.id;
          break;
        }
      }

      AppConfig.logger.t(profile.id.isNotEmpty
          ? "Profile ${profile.toString()}"
          : "Profile not found"
      );
    } catch (e) {
      AppConfig.logger.e(e.toString());
      rethrow;
    }

    return profile;
  }


  @override
  Future<AppProfile?> retrieveSimple(String profileId) async {
    AppConfig.logger.d("Retrieving Profile $profileId");
    AppProfile? profile;

    try {
      QuerySnapshot querySnapshot = await profileReference.get();

      for (var profileDocument in querySnapshot.docs) {
        AppConfig.logger.d("Profile Document: ${profileDocument.id}");
        if (profileDocument.id == profileId) {
          profile = AppProfile.fromJSON(profileDocument.data());
          profile.id = profileDocument.id;
        }
        break;
      }

      if (profile?.id.isNotEmpty ?? false) {
        AppConfig.logger.d("Profile ${profile.toString()}");
      } else {
        AppConfig.logger.d("Profile not found $profileId");
      }
    } catch (e) {
      AppConfig.logger.e(e.toString());
      rethrow;
    }

    return profile;
  }

  @override
  Future<List<AppProfile>> getWithParameters({
    bool needsPhone = false, bool needsPosts = false,
    List<ProfileType>? profileTypes, FacilityType? facilityType, PlaceType? placeType,
    List<UsageReason>? usageReasons, Position? currentPosition, int maxDistance = 150, int? limit, bool isFirstCall = true}) async {
    AppConfig.logger.d("Get profiles by parameters");

    List<AppProfile> profiles = [];

    Map<String, AppProfile> facilityProfiles = <String, AppProfile>{};
    Map<String, AppProfile> placeProfiles = <String, AppProfile>{};
    Map<String, AppProfile> noMainFacilityProfiles = <String, AppProfile>{};
    Map<String, AppProfile> noMainPlaceProfiles = <String, AppProfile>{};

    try {
      List<Post> posts = [];
      if (needsPosts) posts = await PostFirestore().retrievePosts();

      if (isFirstCall) {
        QuerySnapshot profileQuerySnapshot = await profileReference.get();
        _profileDocuments = profileQuerySnapshot.docs;
        List<AppProfile> unsortedProfiles = [];
        for (var queryDocumentSnapshot in _profileDocuments) {
          if (!queryDocumentSnapshot.exists) continue;
          AppProfile profile = AppProfile.fromJSON(
              queryDocumentSnapshot.data());
          profile.id = queryDocumentSnapshot.id;
          unsortedProfiles.add(profile);
        }

        if (currentPosition != null) {
          sortedProfiles = CoreUtilities.sortProfilesByLocation(
              currentPosition, unsortedProfiles);
        } else {
          sortedProfiles = CoreUtilities.sortProfilesByName(unsortedProfiles);
        }
      }

      for (var profile in sortedProfiles.values) {
        if (currentProfileIds.contains(profile.id)) continue;
        if (needsPhone && profile.phoneNumber.isEmpty) {
          AppConfig.logger.t("Profile ${profile.id} ${profile.name} - ${profile.type.name} has no phoneNumber");
          continue;
        }

        if (profileTypes != null && !profileTypes.contains(profile.type)) {
          AppConfig.logger.t("Profile ${profile.id} ${profile.name} - ${profile.type
              .name} is not profile type ${profileTypes.toString()} required");
          continue;
        }

        if (usageReasons != null &&
            (!usageReasons.contains(profile.usageReason) &&
                profile.usageReason != UsageReason.any)) {
          AppConfig.logger.t(
              "Profile ${profile.id} ${profile.name} - ${profile.usageReason
                  .name} has not the usage reason ${usageReasons.toString()} required");
          continue;
        }

        if (needsPosts && (profile.posts?.isEmpty ?? true)) {
          AppConfig.logger.t("Profile ${profile.id} ${profile.name} has not posts");
          continue;
        }

        if (currentPosition != null && (profile.position != null
            && PositionUtilities.distanceBetweenPositionsRounded(
                profile.position!, currentPosition) > maxDistance)) {
          AppConfig.logger.t("Profile ${profile.id} ${profile.name} is out of max distance");
          continue;
        }

        List<String> postImgUrls = [];
        if (needsPosts && (profile.posts?.isNotEmpty ?? false)) {
          for (String postId in profile.posts!) {
            Post post = posts.firstWhere((p) => p.id == postId);
            if (post.mediaUrl.isNotEmpty &&
                post.mediaUrl.contains('.jpg')) {
              postImgUrls.add(post.mediaUrl);
            }
          }

        }

        if (facilityType != null) {
          AppConfig.logger.d(
              "Retrieving Facility for ${profile.name} - ${profile.id}");
          profile.facilities =
          await FacilityFirestore().retrieveFacilities(profile.id);
          if (profile.facilities!.keys.contains(facilityType.value)) {
            if ((profile.facilities?[facilityType.value]?.isMain == true)) {
              facilityProfiles[profile.id] = profile;
            } else {
              noMainFacilityProfiles[profile.id] = profile;
            }
          }
        } else {
          profile.facilities = {};
          profile.facilities![profile.id] = Facility();
          profile.facilities!.values.first.galleryImgUrls = postImgUrls;
          facilityProfiles[profile.id] = profile;
        }

        if (placeType != null) {
          AppConfig.logger.d(
              "Retrieving Places for ${profile.name} - ${profile.id}");
          profile.places = await PlaceFirestore().retrievePlaces(profile.id);
          if (profile.places!.keys.contains(placeType.value)) {
            if ((profile.places?[placeType.value]?.isMain == true)) {
              placeProfiles[profile.id] = profile;
            } else {
              noMainPlaceProfiles[profile.id] = profile;
            }
          }
        } else {
          profile.places = {};
          profile.places![profile.id] = Place();
          profile.places!.values.first.galleryImgUrls = postImgUrls;
          placeProfiles[profile.id] = profile;
        }

        if (profile.address.isEmpty) {
          profile.address =
          await PositionUtilities.getFormattedAddressFromPosition(profile.position!);
          if (profile.address.isNotEmpty) {
            ProfileFirestore().updateAddress(
              profile.id, profile.address);
          }
        }

        currentProfileIds.add(profile.id);
        profiles.add(profile);
        if (limit != null && profiles.length >= limit) break;
      }
    } catch (e) {
      AppConfig.logger.e(e.toString());
    }

    return profiles;
  }

  @override
  Future<bool> remove(
      {required String userId, required String profileId}) async {
    AppConfig.logger.d("Removing profile $profileId from Firestore");

    try {
      await usersReference.doc(userId).collection(
          AppFirestoreCollectionConstants.profiles).doc(profileId).delete();
      AppConfig.logger.d(
          "Profile $profileId removed successfully from User $userId.");
    } catch (e) {
      AppConfig.logger.e(e);
      return false;
    }

    return true;
  }

  @override
  Future<AppProfile> retrieveFull(String profileId) async {
    AppConfig.logger.d("Retrieving Profile $profileId");
    AppProfile profile = AppProfile();

    try {
      QuerySnapshot querySnapshot = await profileReference.get();

      for (var profileSnapshot in querySnapshot.docs) {
        if (profileId == profileSnapshot.id) {
          profile = AppProfile.fromJSON(profileSnapshot.data());
          profile.id = profileId;
        }
      }

      if (profile.id.isNotEmpty) {
        profile = await getProfileFeatures(profile);
      } else {
        AppConfig.logger.d("Profile not found");
      }
    } catch (e) {
      AppConfig.logger.e(e.toString());
      rethrow;
    }

    return profile;
  }

  @override
  Future<List<AppProfile>> retrieveByUserId(String userId,
      {ProfileType? profileType}) async {
    AppConfig.logger.d("RetrievingProfiles for $userId");
    List<AppProfile> profiles = <AppProfile>[];

    try {
      QuerySnapshot querySnapshot = await usersReference.doc(userId)
          .collection(AppFirestoreCollectionConstants.profiles).get();

      if (querySnapshot.docs.isNotEmpty) {
        AppConfig.logger.t("Snapshot is not empty");
        for (var profileSnapshot in querySnapshot.docs) {
          AppProfile profile = AppProfile.fromJSON(profileSnapshot.data());
          if (profileType == null || profile.type == profileType) {
            profile.id = profileSnapshot.id;
            AppConfig.logger.t(profile.toString());
            profiles.add(profile);
          }
        }
      }
    } catch (e) {
      AppConfig.logger.e(e.toString());
    }

    AppConfig.logger.t("${profiles.length} profiles found");
    return profiles;
  }


  @override
  Future<Map<String, AppProfile>> retrieveProfilesByInstrument({
    String selfProfileId = "",
    Position? currentPosition,
    String instrumentId = "",
    int maxDistance = 20,
    int maxProfiles = 10,
  }) async {
    AppConfig.logger.d("RetrievingProfiles by instrument");

    Map<String, AppProfile> mainInstrumentProfiles = <String, AppProfile>{};
    Map<String, AppProfile> noMainInstrumentProfiles = <String, AppProfile>{};

    try {
      await profileReference
      //.limit(12)
          .get().then((querySnapshot) async {
        for (var document in querySnapshot.docs) {
          AppProfile profile = AppProfile.fromJSON(document.data());
          profile.id = document.id;
          if (profile.id != selfProfileId &&
              profile.type == ProfileType.appArtist
              && mainInstrumentProfiles.length < maxProfiles
          ) {
            if (PositionUtilities.distanceBetweenPositionsRounded(
                profile.position!, currentPosition!) < maxDistance) {
              profile.instruments =
              await InstrumentFirestore().retrieveInstruments(profile.id);
              if (profile.instruments!.keys.contains(instrumentId)) {
                if ((profile.instruments?[instrumentId]?.isMain == true)) {
                  mainInstrumentProfiles[profile.id] = profile;
                } else {
                  noMainInstrumentProfiles[profile.id] = profile;
                }
              }
            } else {
              AppConfig.logger.d(
                  "Profile ${profile.id} is out of max distance");
            }
          }
        }

        if (mainInstrumentProfiles.length < maxProfiles &&
            noMainInstrumentProfiles.isNotEmpty) {
          noMainInstrumentProfiles.forEach((profileId, profile) {
            if (mainInstrumentProfiles.length < maxProfiles) {
              mainInstrumentProfiles[profileId] = profile;
            }
          });
        }
      });
    } catch (e) {
      AppConfig.logger.e(e.toString());
    }

    AppConfig.logger.d("${mainInstrumentProfiles.length} Profiles found");
    return mainInstrumentProfiles;
  }


  @override
  Future<Map<String, AppProfile>> retrieveFromList(
      List<String> profileIds) async {
    AppConfig.logger.t("RetrievingProfiles");

    try {
      QuerySnapshot querySnapshot = await profileReference.get();
      for (var profileSnapshot in querySnapshot.docs) {
        if (profileIds.contains(profileSnapshot.id)) {
          AppProfile profile = AppProfile.fromJSON(profileSnapshot.data());
          profile.id = profileSnapshot.id;
          profiles[profile.id] = profile;
        }
      }
    } catch (e) {
      AppConfig.logger.e(e.toString());
    }


    AppConfig.logger.d("${profiles.length} profiles found");
    return profiles;
  }

  @override
  Future<bool> followProfile(
      {required String profileId, required String followedProfileId}) async {
    AppConfig.logger.t("$profileId would be following $followedProfileId");

    try {
      await profileReference.get().then((querySnapshot) async {
        for (var document in querySnapshot.docs) {
          if (document.id == profileId) {
            await document.reference.update({
              AppFirestoreConstants.following: FieldValue.arrayUnion(
                  [followedProfileId])
            });
            AppConfig.logger.d(
                "$profileId is now following $followedProfileId");
          }

          if (document.id == followedProfileId) {
            await document.reference.update({
              AppFirestoreConstants.followers: FieldValue.arrayUnion(
                  [profileId])
            });
            AppConfig.logger.d(
                "$followedProfileId is now followed by $profileId");
          }
        }
      }
      );

      return true;
    } catch (e) {
      AppConfig.logger.e(e.toString());
    }
    return false;
  }


  @override
  Future<bool> unfollowProfile(
      {required String profileId, required String unfollowProfileId}) async {
    AppConfig.logger.t("$profileId would be unfollowing $unfollowProfileId");

    try {
      await profileReference.get().then((querySnapshot) async {
        for (var document in querySnapshot.docs) {
          if (document.id == profileId) {
            await document.reference.update({
              AppFirestoreConstants.following: FieldValue.arrayRemove(
                  [unfollowProfileId])
            });
            AppConfig.logger.d(
                "$profileId is now unfollowing $unfollowProfileId");
          }

          if (document.id == unfollowProfileId) {
            await document.reference.update({
              AppFirestoreConstants.followers: FieldValue.arrayRemove(
                  [profileId])
            });
            AppConfig.logger.d(
                "$unfollowProfileId is now unfollowed by $profileId");
          }
        }
      }
      );

      return true;
    } catch (e) {
      AppConfig.logger.e(e.toString());
    }
    return false;
  }


  @override
  Future<bool> blockProfile(
      {required String profileId, required String profileToBlock}) async {
    AppConfig.logger.d("$profileId would be unfollowing $profileToBlock");

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
            AppConfig.logger.d("$profileId has blocked $profileToBlock");
          }

          if (document.id == profileToBlock) {
            await document.reference.update({
              AppFirestoreConstants.followers: FieldValue.arrayRemove(
                  [profileId]),
              AppFirestoreConstants.blockedBy: FieldValue.arrayUnion(
                  [profileId])
            });
            AppConfig.logger.d(
                "$profileToBlock is now blocked by $profileId");
          }
        }
      }
      );

      return true;
    } catch (e) {
      AppConfig.logger.e(e.toString());
    }
    return false;
  }


  @override
  Future<bool> unblockProfile(
      {required String profileId, required String profileToUnblock}) async {
    AppConfig.logger.d("$profileId would unblock $profileToUnblock");

    try {
      await profileReference.get().then((querySnapshot) async {
        for (var document in querySnapshot.docs) {
          if (document.id == profileId) {
            await document.reference.update({
              AppFirestoreConstants.blockTo: FieldValue.arrayRemove(
                  [profileToUnblock]),
            });
            AppConfig.logger.d("$profileId has unblocked $profileToUnblock");
          }

          if (document.id == profileToUnblock) {
            await document.reference.update({
              AppFirestoreConstants.blockedBy: FieldValue.arrayRemove(
                  [profileId])
            });
            AppConfig.logger.d(
                "$profileToUnblock is now unblocked by $profileId");
          }
        }
      }
      );

      return true;
    } catch (e) {
      AppConfig.logger.e(e.toString());
    }
    return false;
  }


  @override
  Future<bool> updatePosition(String profileId, Position newPosition) async {
    AppConfig.logger.d("$profileId updating location");

    String address = await PositionUtilities.getFormattedAddressFromPosition(newPosition);

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

      AppConfig.logger.d("$profileId location updated");
      return true;
    } catch (e) {
      AppConfig.logger.e(e.toString());
    }

    return false;
  }


  @override
  Future<bool> addPost(String profileId, String postId) async {
    AppConfig.logger.d("$profileId would add $postId");

    try {
      await profileReference.get()
          .then((querySnapshot) async {
        for (var document in querySnapshot.docs) {
          if (document.id == profileId) {
            await document.reference.update({
              AppFirestoreConstants.posts: FieldValue.arrayUnion([postId])
            });
          }
        }
      });

      AppConfig.logger.d("Profile $profileId has post $postId");
      return true;
    } catch (e) {
      AppConfig.logger.e(e.toString());
    }
    return false;
  }


  @override
  Future<bool> removePost(String profileId, String postId) async {
    AppConfig.logger.t("$profileId would remove $postId");

    try {
      await profileReference.get()
          .then((querySnapshot) async {
        for (var document in querySnapshot.docs) {
          if (document.id == profileId) {
            await document.reference.update({
              AppFirestoreConstants.posts: FieldValue.arrayRemove([postId])
            });
          }
        }
      });

      AppConfig.logger.d("$profileId has removed post $postId");
      return true;
    } catch (e) {
      AppConfig.logger.e(e.toString());
    }
    return false;
  }


  @override
  Future<bool> hidePost(String profileId, String postId) async {
    AppConfig.logger.d("$profileId would hide $postId");

    try {
      await profileReference.get()
          .then((querySnapshot) async {
        for (var document in querySnapshot.docs) {
          if (document.id == profileId) {
            await document.reference
                .update({
              AppFirestoreConstants.hiddenPosts: FieldValue.arrayUnion([postId])
            });
          }
        }
      });

      AppConfig.logger.d("Profile $profileId has hidden $postId");
    } catch (e) {
      AppConfig.logger.e.toString();
      return false;
    }

    return true;
  }


  @override
  Future<bool> addComment(String profileId, String commentId) async {
    AppConfig.logger.d("$profileId would add $commentId");

    try {
      await profileReference.get()
          .then((querySnapshot) async {
        for (var document in querySnapshot.docs) {
          if (document.id == profileId) {
            await document.reference
                .update(
                {
                  AppFirestoreConstants.comments: FieldValue.arrayUnion(
                      [commentId])
                }
            );
          }
        }
      });

      AppConfig.logger.d("Profile $profileId has added $commentId");
    } catch (e) {
      AppConfig.logger.e.toString();
      return false;
    }

    return true;
  }


  @override
  Future<bool> removeComment(String profileId, String commentId) async {
    AppConfig.logger.d("$profileId would remove $commentId");

    try {
      await profileReference.get()
          .then((querySnapshot) async {
        for (var document in querySnapshot.docs) {
          if (document.id == profileId) {
            await document.reference
                .update(
                {
                  AppFirestoreConstants.comments: FieldValue.arrayRemove(
                      [commentId])
                }
            );
          }
        }
      });

      AppConfig.logger.d("Profile $profileId has removed $commentId");
    } catch (e) {
      AppConfig.logger.e.toString();
      return false;
    }

    return true;
  }


  @override
  Future<bool> hideComment(String profileId, String commentId) async {
    AppConfig.logger.d("$profileId would hide $commentId");

    try {
      await profileReference.get()
          .then((querySnapshot) async {
        for (var document in querySnapshot.docs) {
          if (document.id == profileId) {
            await document.reference
                .update(
                {
                  AppFirestoreConstants.hiddenComments: FieldValue.arrayUnion(
                      [commentId])
                }
            );
          }
        }
      });

      AppConfig.logger.d("Profile $profileId has hidden $commentId");
    } catch (e) {
      AppConfig.logger.e.toString();
      return false;
    }

    return true;
  }


  @override
  Future<bool> updateName(String profileId, String profileName) async {
    AppConfig.logger.d("Updating profile $profileId to name $profileName}");

    try {
      await profileReference.get()
          .then((querySnapshot) async {
        for (var document in querySnapshot.docs) {
          if (document.id == profileId) {
            await document.reference.update({
              AppFirestoreConstants.name: profileName,
              AppFirestoreConstants.lastNameUpdate: DateTime
                  .now()
                  .millisecondsSinceEpoch,
            });
          }
        }
      });
      return true;
    } catch (e) {
      AppConfig.logger.e(e.toString());
    }

    return false;
  }


  @override
  Future<bool> updateAboutMe(String profileId, String aboutMe) async {
    AppConfig.logger.d(
        "Updating profile $profileId to description $aboutMe}");

    try {
      await profileReference.get()
          .then((querySnapshot) async {
        for (var document in querySnapshot.docs) {
          if (document.id == profileId) {
            await document.reference.update({
              AppFirestoreConstants.aboutMe: aboutMe
            });
          }
        }
      });
      return true;
    } catch (e) {
      AppConfig.logger.e(e.toString());
    }

    return false;
  }

  @override
  Future<bool> updateAddress(String profileId, String address) async {
    AppConfig.logger.i(
        "Updating Profile $profileId with new address as $address");

    try {
      await profileReference.get()
          .then((querySnapshot) async {
        for (var document in querySnapshot.docs) {
          if (document.id == profileId) {
            await document.reference.update({
              AppFirestoreConstants.address: address,
            });
          }
        }
      });
      return true;
    } catch (e) {
      AppConfig.logger.e(e.toString());
    }

    return false;
  }

  @override
  Future<bool> updatePhoneNumber(String profileId, String phoneNumber) async {
    AppConfig.logger.i(
        "Updating Profile $profileId with new phoneNumber as $phoneNumber");

    try {
      await profileReference.get()
          .then((querySnapshot) async {
        for (var document in querySnapshot.docs) {
          if (document.id == profileId) {
            await document.reference.update({
              AppFirestoreConstants.phoneNumber: phoneNumber,
            });
          }
        }
      });
      return true;
    } catch (e) {
      AppConfig.logger.e(e.toString());
    }

    return false;
  }

  @override
  Future<bool> updateType(String profileId, ProfileType type) async {
    AppConfig.logger.i(
        "Updating Profile $profileId with new type as ${type.name}");

    try {
      await profileReference.get()
          .then((querySnapshot) async {
        for (var document in querySnapshot.docs) {
          if (document.id == profileId) {
            await document.reference.update({
              AppFirestoreConstants.type: type.value,
            });
          }
        }
      });
      return true;
    } catch (e) {
      AppConfig.logger.e(e.toString());
    }

    return false;
  }

  Future<bool> updateUsageReason(String profileId, UsageReason reason) async {
    AppConfig.logger.i(
        "Updating Profile $profileId with new type as ${reason.name}");

    try {
      await profileReference.get()
          .then((querySnapshot) async {
        for (var document in querySnapshot.docs) {
          if (document.id == profileId) {
            await document.reference.update({
              AppFirestoreConstants.usageReason: reason.name,
            });
          }
        }
      });
      return true;
    } catch (e) {
      AppConfig.logger.e(e.toString());
    }

    return false;
  }

  @override
  Future<bool> updateVerificationLevel(String profileId,
      VerificationLevel verificationLevel) async {
    AppConfig.logger.i(
        "Updating Profile $profileId with VerificationLevel as ${verificationLevel
            .name}");

    try {
      await profileReference.get()
          .then((querySnapshot) async {
        for (var document in querySnapshot.docs) {
          if (document.id == profileId) {
            await document.reference.update({
              AppFirestoreConstants.verificationLevel: verificationLevel.name,
            });
          }
        }
      });
      return true;
    } catch (e) {
      AppConfig.logger.e(e.toString());
    }

    return false;
  }


  @override
  Future<bool> addEvent(String profileId, String eventId,
      EventAction eventAction) async {
    AppConfig.logger.t("$profileId would add $eventId");

    try {
      await profileReference.get()
          .then((querySnapshot) async {
        for (var document in querySnapshot.docs) {
          if (document.id == profileId) {
            String eventListToUpdate = "";
            switch (eventAction) {
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

      AppConfig.logger.d("$profileId has added event $eventId");
      return true;
    } catch (e) {
      AppConfig.logger.e(e.toString());
    }
    return false;
  }


  @override
  Future<bool> removeEvent(String profileId, String eventId,
      EventAction eventAction) async {
    AppConfig.logger.t("$profileId would remove $eventId");

    try {
      await profileReference.get()
          .then((querySnapshot) async {
        for (var document in querySnapshot.docs) {
          String eventListToUpdate = "";
          switch (eventAction) {
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

          if (document.id == profileId) {
            await document.reference.update({
              eventListToUpdate: FieldValue.arrayRemove([eventId])
            });
          }
        }
      });

      AppConfig.logger.t("$profileId has removed event $eventId");
      return true;
    } catch (e) {
      AppConfig.logger.e(e.toString());
    }
    return false;
  }


  @override
  Future<bool> addFavoriteItem(String profileId, String itemId) async {
    AppConfig.logger.t(
        "Adding item $itemId to Profile $profileId favorites");
    try {
      await profileReference.get()
          .then((querySnapshot) async {
        for (var document in querySnapshot.docs) {
          if (document.id == profileId) {
            await document.reference.update({
              AppFirestoreConstants.favoriteItems: FieldValue.arrayUnion(
                  [itemId])
            });
          }
        }
      });
    } catch (e) {
      AppConfig.logger.e(e.toString());
      return false;
    }

    return true;
  }

  @override
  Future<bool> addFavoriteItems(String profileId, List<String> itemIds) async {
    AppConfig.logger.t(
        "Adding ${itemIds.length} items to Profile $profileId favorites");

    try {
      await profileReference.get()
          .then((querySnapshot) async {
        for (var document in querySnapshot.docs) {
          if (document.id == profileId) {
            List<dynamic> currentFavorites = document
                .data()[AppFirestoreConstants.favoriteItems];
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
      AppConfig.logger.e(e.toString());
      return false;
    }

    return true;
  }

  @override
  Future<bool> removeFavoriteItem(String profileId, String itemId) async {
    AppConfig.logger.t(
        "Removing item $itemId from Profile $profileId favorites");

    try {
      await profileReference.get()
          .then((querySnapshot) async {
        for (var document in querySnapshot.docs) {
          if (document.id == profileId) {
            await document.reference.update({
              AppFirestoreConstants.favoriteItems: FieldValue.arrayRemove(
                  [itemId])
            });
          }
        }
      });
    } catch (e) {
      AppConfig.logger.e(e.toString());
      return false;
    }

    return true;
  }

  @override
  Future<bool> removeFavoriteItems(String profileId,
      List<String> itemIds) async {
    AppConfig.logger.t(
        "Removing ${itemIds.length} items from Profile $profileId favorites");

    try {
      await profileReference.get()
          .then((querySnapshot) async {
        for (var document in querySnapshot.docs) {
          if (document.id == profileId) {
            // await document.reference.update({
            //   AppFirestoreConstants.favoriteItems: FieldValue.arrayRemove([itemId])
            // });

            List<dynamic> currentFavorites = document
                .data()[AppFirestoreConstants.favoriteItems];
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
      AppConfig.logger.e(e.toString());
      return false;
    }

    return true;
  }

  @override
  Future<bool> addChamberPreset(
      {required String profileId, required String chamberPresetId}) async {
    AppConfig.logger.d(
        "Adding preset $chamberPresetId to Profile $profileId");
    try {
      await profileReference.get()
          .then((querySnapshot) async {
        for (var document in querySnapshot.docs) {
          if (document.id == profileId) {
            await document.reference.update({
              AppFirestoreConstants.chamberPresets: FieldValue.arrayUnion(
                  [chamberPresetId])
            });
          }
        }
      });
    } catch (e) {
      AppConfig.logger.e(e.toString());
      return false;
    }

    return true;
  }

  @override
  Future<bool> addBand(
      {required String profileId, required String bandId}) async {
    AppConfig.logger.t(
        "Add band $bandId for profile $profileId from firestore");
    try {
      await profileReference.get()
          .then((querySnapshot) async {
        for (var document in querySnapshot.docs) {
          if (document.id == profileId) {
            await document.reference.update({
              AppFirestoreConstants.bands: FieldValue.arrayUnion([bandId])
            });
          }
        }
      });
    } catch (e) {
      AppConfig.logger.e(e.toString());
      return false;
    }

    return true;
  }


  @override
  Future<bool> removeBand(
      {required String profileId, required String bandId}) async {
    AppConfig.logger.t(
        "Remove band $bandId for profile $profileId from firestore");

    try {
      await profileReference.get()
          .then((querySnapshot) async {
        for (var document in querySnapshot.docs) {
          if (document.id == profileId) {
            await document.reference.update({
              AppFirestoreConstants.bands: FieldValue.arrayRemove([bandId])
            });
          }
        }
      });
    } catch (e) {
      AppConfig.logger.e(e.toString());
      return false;
    }

    return true;
  }

  @override
  Future<Map<String, AppProfile>> retrieveAllProfiles({int limit = 0}) async {
    AppConfig.logger.d("retrieveAllProfiles");

    try {
      if (limit <= 0) limit = CoreConstants.profilesLimit;
      final querySnapshot = await profileReference.limit(limit).get();

      profiles = {
        for (var document in querySnapshot.docs)
          if (document.data().containsKey('name')) document.id: AppProfile
              .fromJSON(document.data())
            ..id = document.id
      };

    } catch (e) {
      AppConfig.logger.e(e.toString());
    }

    AppConfig.logger.t("${profiles.length} profiles found");
    return profiles;
  }


  @override
  Future<bool> addRequest(String profileId, String requestId,
      RequestType requestType) async {
    AppConfig.logger.t("$profileId would add $requestId");

    try {
      await profileReference.get()
          .then((querySnapshot) async {
        for (var document in querySnapshot.docs) {
          if (document.id == profileId) {
            String requestsToUpdate = "";

            switch (requestType) {
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

      AppConfig.logger.d(
          "Profile $profileId has added request $requestId as type ${requestType
              .name}");
    } catch (e) {
      AppConfig.logger.e.toString();
      return false;
    }

    return true;
  }


  @override
  Future<bool> removeRequest(String profileId, String requestId,
      RequestType requestType) async {
    AppConfig.logger.d("$profileId would remove $requestId");

    try {
      await profileReference.get()
          .then((querySnapshot) async {
        for (var document in querySnapshot.docs) {
          if (document.id == profileId) {
            String requestsToRemove = "";

            switch (requestType) {
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

      AppConfig.logger.d(
          "Profile $profileId has removed request $requestId");
    } catch (e) {
      AppConfig.logger.e(e.toString());
      return false;
    }

    return true;
  }


  @override
  Future<Map<String, AppProfile>> getFollowers(String profileId) async {
    AppConfig.logger.d("Start getFollowers for $profileId");

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
        follower.instruments =
        await InstrumentFirestore().retrieveInstruments(followerId);
        followersMap[followerId] = follower;
      }

      AppConfig.logger.d("${followersMap.length} Followers found");
    } catch (e) {
      AppConfig.logger.e(e.toString());
      rethrow;
    }
    return followersMap;
  }


  @override
  Future<Map<String, AppProfile>> getFollowed(String profileId) async {
    AppConfig.logger.d("Start getFollowed for $profileId");

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
        followed.instruments =
        await InstrumentFirestore().retrieveInstruments(followedId);
        followedMap[followedId] = followed;
      }

      AppConfig.logger.d("${followedMap.length} Followed found");
    } catch (e) {
      AppConfig.logger.e(e.toString());
      rethrow;
    }
    return followedMap;
  }

  @override
  Future<bool> updatePhotoUrl(String profileId, String photoUrl) async {
    AppConfig.logger.d("");

    try {
      await profileReference.get()
          .then((querySnapshot) async {
        for (var document in querySnapshot.docs) {
          if (document.id == profileId) {
            await document.reference.update({
              AppFirestoreConstants.photoUrl: photoUrl
            });
          }
        }
      });
    } catch (e) {
      AppConfig.logger.e(e.toString());
      return false;
    }

    return true;
  }


  @override
  Future<bool> updateCoverImgUrl(String profileId, String coverImgUrl) async {
    AppConfig.logger.d("");

    try {
      await profileReference.get()
          .then((querySnapshot) async {
        for (var document in querySnapshot.docs) {
          if (document.id == profileId) {
            await document.reference.update({
              AppFirestoreConstants.coverImgUrl: coverImgUrl
            });
          }
        }
      });
    } catch (e) {
      AppConfig.logger.e(e.toString());
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
    AppConfig.logger.t("Retrieving FCM Token for Profile $profileId");

    String userId = "";
    String fcmToken = "";
    QuerySnapshot userQuerySnapshot;

    try {
      QuerySnapshot querySnapshot = await profileReference.get();

      for (var profile in querySnapshot.docs) {
        if (profile.id == profileId) {
          AppConfig.logger.t(
              "Reference id: ${profile.reference.parent.parent?.id ?? ""}");
          DocumentReference documentReference = profile.reference;
          userId = documentReference.parent.parent?.id ?? "";

          if (userId.isNotEmpty) {
            userQuerySnapshot = await usersReference.where(
                FieldPath.documentId, isEqualTo: userId).get();
            if (userQuerySnapshot.docs.isNotEmpty) {
              AppConfig.logger.t(
                  "${userQuerySnapshot.docs.length} users found");
              fcmToken = AppUser
                  .fromJSON(userQuerySnapshot.docs.first.data())
                  .fcmToken;
              AppConfig.logger.t("FCM Token $fcmToken");
            } else {
              AppConfig.logger.w("No user found for id $userId");
            }
          }
        }
      }
    } catch (e) {
      AppConfig.logger.e(e.toString());
    }

    if (fcmToken.isEmpty) {
      AppConfig.logger.w(
          "Push Notification not send as FCM Token was not found for users device");
    }

    return fcmToken;
  }


  @override
  Future<bool> isAvailableName(String profileName) async {
    AppConfig.logger.d("Verify if name $profileName is available to create this profile");

    try {
      QuerySnapshot querySnapshot = await profileReference
          .where(AppFirestoreConstants.name, isEqualTo: profileName.trim())
          .limit(
          1) // Limitar a 1 resultado ya que solo necesitamos saber si existe
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        AppConfig.logger.w("Profile Name '$profileName' already in use");
        return false; // No disponible
      }
    } catch (e) {
      AppConfig.logger.e(e.toString());
      return false;
    }

    AppConfig.logger.d("No profiles found");
    return true;
  }

  Future<AppProfile> getProfileFeatures(AppProfile profile) async {
    try {
      if (profile.type == ProfileType.appArtist) {
        profile.instruments =
        await InstrumentFirestore().retrieveInstruments(profile.id);
        if (profile.instruments!.isEmpty) {
          AppConfig.logger.w("Instruments not found");
        }
      }

      if (profile.type == ProfileType.host) {
        profile.places = await PlaceFirestore().retrievePlaces(profile.id);
        if (profile.places!.isEmpty) {
          AppConfig.logger.t("Places not found");
        }
      }

      if (profile.type == ProfileType.facilitator) {
        profile.facilities =
        await FacilityFirestore().retrieveFacilities(profile.id);
        if (profile.facilities!.isEmpty) {
          AppConfig.logger.w("Facilities not found");
        }
      }

      if(AppConfig.instance.appInUse == AppInUse.c) {
        profile.chambers = await Get.find<ChamberRepository>().fetchAll(ownerId: profile.id);
        profile.chamberPresets?.clear();

        CoreUtilities.getTotalPresets(profile.chambers!).forEach((key, value) {
          profile.chamberPresets!.add(key);
        });
      }

      profile.genres = await GenreFirestore().retrieveGenres(profile.id);
      profile.itemlists = await ItemlistFirestore().getByOwnerId(profile.id);
      if (profile.genres!.isEmpty) AppConfig.logger.t("Genres not found");
      if (profile.itemlists!.isEmpty) {
        AppConfig.logger.t(
          "Itemlists not found");
      }
    } catch (e) {
      AppConfig.logger.e(e.toString());
    }

    return profile;
  }

  @override
  Future<bool> updateLastSpotifySync(String profileId) async {
    AppConfig.logger.d("Updating Spotify Last Sync for profile $profileId");

    try {
      await profileReference.get()
          .then((querySnapshot) async {
        for (var document in querySnapshot.docs) {
          if (document.id == profileId) {
            await document.reference.update({
              AppFirestoreConstants.lastSpotifySync: DateTime
                  .now()
                  .millisecondsSinceEpoch
            });
          }
        }
      });
      return true;
    } catch (e) {
      AppConfig.logger.e(e.toString());
    }

    return false;
  }

  @override
  Future<bool> addBlogEntry(String profileId, String blogEntryId) async {
    AppConfig.logger.d("$profileId would add $blogEntryId");

    try {
      await profileReference.get()
          .then((querySnapshot) async {
        for (var document in querySnapshot.docs) {
          if (document.id == profileId) {
            await document.reference.update({
              AppFirestoreConstants.blogEntries: FieldValue.arrayUnion(
                  [blogEntryId])
            });
          }
        }
      });

      AppConfig.logger.d("Profile $profileId has blogEntry $blogEntryId");
      return true;
    } catch (e) {
      AppConfig.logger.e(e.toString());
    }
    return false;
  }


  @override
  Future<bool> removeBlogEntry(String profileId, String blogEntryId) async {
    AppConfig.logger.d("$profileId would remove $blogEntryId");

    try {
      await profileReference.get()
          .then((querySnapshot) async {
        for (var document in querySnapshot.docs) {
          if (document.id == profileId) {
            await document.reference.update({
              AppFirestoreConstants.blogEntries: FieldValue.arrayRemove(
                  [blogEntryId])
            });
          }
        }
      });

      AppConfig.logger.d("$profileId has removed blogEntry $blogEntryId");
      return true;
    } catch (e) {
      AppConfig.logger.e(e.toString());
    }
    return false;
  }

  @override
  Future<bool> removeAllFavoriteItems(String profileId) async {
    AppConfig.logger.d("");

    try {
      await profileReference.get()
          .then((querySnapshot) async {
        for (var document in querySnapshot.docs) {
          // if(document.id == profileId) {
          await document.reference.update({
            AppFirestoreConstants.favoriteItems: FieldValue.delete()
          });
          AppConfig.logger.w("Deleting");
          // }
        }
      });
    } catch (e) {
      AppConfig.logger.e(e.toString());
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
    AppConfig.logger.d("RetrievingProfiles by facility");

    Map<String, AppProfile> facilityProfiles = <String, AppProfile>{};
    Map<String, AppProfile> noMainFacilityProfiles = <String, AppProfile>{};

    try {
      await profileReference.get().then((querySnapshot) async {
        for (var document in querySnapshot.docs) {
          AppProfile profile = AppProfile.fromJSON(document.data());
          profile.id = document.id;
          if (profile.id != selfProfileId &&
              profile.type == ProfileType.facilitator
              && facilityProfiles.length < maxProfiles
          ) {
            if (PositionUtilities.distanceBetweenPositionsRounded(
                profile.position!, currentPosition!) < maxDistance) {
              if (profile.address.isEmpty && profile.position != null) {
                profile.address =
                await PositionUtilities.getFormattedAddressFromPosition(profile.position!);
              }
              if (profile.posts?.isNotEmpty ?? false) {
                List<Post> profilePosts = await PostFirestore().getProfilePosts(
                    profile.id);
                List<String> postImgUrls = [];
                for (var element in profilePosts) {
                  if (postImgUrls.length < 6) {
                    postImgUrls.add(element.mediaUrl);
                  }
                }

                if (facilityType != null) {
                  profile.facilities =
                  await FacilityFirestore().retrieveFacilities(profile.id);
                  if (profile.facilities!.keys.contains(facilityType.value)) {
                    if ((profile.facilities?[facilityType.value]?.isMain ==
                        true)) {
                      facilityProfiles[profile.id] = profile;
                    } else {
                      noMainFacilityProfiles[profile.id] = profile;
                    }
                  }
                } else {
                  profile.facilities = {};
                  profile.facilities![profile.id] = Facility();
                  profile.facilities!.values.first.galleryImgUrls = postImgUrls;
                  facilityProfiles[profile.id] = profile;
                }
              } else {
                AppConfig.logger.d(
                    "Profile ${profile.id} ${profile.name} has not posts");
              }
            } else {
              AppConfig.logger.d("Profile ${profile.id} ${profile
                  .name} is out of max distance");
            }
          }
        }

        if (facilityProfiles.length < maxProfiles &&
            noMainFacilityProfiles.isNotEmpty) {
          noMainFacilityProfiles.forEach((profileId, profile) {
            if (facilityProfiles.length < maxProfiles) {
              facilityProfiles[profileId] = profile;
            }
          });
        }
      });
    } catch (e) {
      AppConfig.logger.e(e.toString());
    }

    AppConfig.logger.d("${facilityProfiles.length} Profiles found");
    return facilityProfiles;
  }

  @override
  Future<Map<String, AppProfile>> retrieveProfilesByPlace({
    required String selfProfileId, required Position? currentPosition,
    PlaceType? placeType, int maxDistance = 30, int maxProfiles = 30}) async {

    AppConfig.logger.d("RetrievingProfiles by place");

    Map<String, AppProfile> hostProfiles = <String, AppProfile>{};
    Map<String, AppProfile> noMainPlaceProfiles = <String, AppProfile>{};

    try {
      await profileReference.get().then((querySnapshot) async {
        for (var document in querySnapshot.docs) {
          AppProfile profile = AppProfile.fromJSON(document.data());
          profile.id = document.id;
          if (profile.id != selfProfileId && profile.type == ProfileType.host
              && hostProfiles.length < maxProfiles
          ) {
            if (PositionUtilities.distanceBetweenPositionsRounded(
                profile.position!, currentPosition!) < maxDistance) {
              if (profile.address.isEmpty && profile.position != null) {
                profile.address =
                await PositionUtilities.getFormattedAddressFromPosition(profile.position!);
              }
              if (profile.posts?.isNotEmpty ?? false) {
                List<Post> profilePosts = await PostFirestore().getProfilePosts(
                    profile.id);
                List<String> postImgUrls = [];
                for (var element in profilePosts) {
                  if (postImgUrls.length < 6) {
                    postImgUrls.add(element.mediaUrl);
                  }
                }

                if (placeType != null) {
                  profile.facilities =
                  await FacilityFirestore().retrieveFacilities(profile.id);
                  if (profile.facilities!.keys.contains(placeType.value)) {
                    if ((profile.facilities?[placeType.value]?.isMain ==
                        true)) {
                      hostProfiles[profile.id] = profile;
                    } else {
                      noMainPlaceProfiles[profile.id] = profile;
                    }
                  }
                } else {
                  profile.facilities = {};
                  profile.facilities![profile.id] = Facility();
                  profile.facilities!.values.first.galleryImgUrls = postImgUrls;
                  hostProfiles[profile.id] = profile;
                }
              } else {
                AppConfig.logger.d(
                    "Profile ${profile.id} ${profile.name} has not posts");
              }
            } else {
              AppConfig.logger.d("Profile ${profile.id} ${profile
                  .name} is out of max distance");
            }
          }
        }

        if (hostProfiles.length < maxProfiles &&
            noMainPlaceProfiles.isNotEmpty) {
          noMainPlaceProfiles.forEach((profileId, profile) {
            if (hostProfiles.length < maxProfiles) {
              hostProfiles[profileId] = profile;
            }
          });
        }
      });
    } catch (e) {
      AppConfig.logger.e(e.toString());
    }

    AppConfig.logger.d("${hostProfiles.length} Profiles found");
    return hostProfiles;
  }

  @override
  Future<AppProfile?> getByEmail(String email) async {
    AppConfig.logger.d("Retrieving profile by email $email");

    AppUser? user;
    AppProfile? profile;
    if (email.isEmpty) {
      AppConfig.logger.w("Email is empty");
      return null;
    }

    try {
      user = await UserFirestore().getByEmail(email.toLowerCase());

      if(user?.currentProfileId.isNotEmpty ?? false) {
        profile = await retrieve(user!.currentProfileId);
        if(profile.id.isNotEmpty) {
          return profile;
        } else {
          AppConfig.logger.d("Profile for userId ${user.id} not found");
        }
      } else {
        user?.profiles = await retrieveByUserId(user.id);
      }
    } catch (e) {
      AppConfig.logger.e(e.toString());
    }

    return (user?.profiles.isNotEmpty ?? false) ? user!.profiles.first : null;
  }

}
