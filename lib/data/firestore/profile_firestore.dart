import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:sint/sint.dart';

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

  /// OPTIMIZED: Helper method to get a profile document reference by ID
  /// Uses the 'id' field stored in the document instead of FieldPath.documentId
  /// (collectionGroup queries don't support FieldPath.documentId with simple IDs)
  Future<DocumentReference?> _getProfileDocumentReference(String profileId) async {
    // Validate profileId is not empty to avoid Firestore error
    if (profileId.isEmpty) {
      AppConfig.logger.w('Cannot get profile reference: profileId is empty');
      return null;
    }

    try {
      // First try: Query by 'id' field (for profiles that have this field stored)
      final querySnapshot = await profileReference
          .where('id', isEqualTo: profileId)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        return querySnapshot.docs.first.reference;
      }

      // Fallback: Search by document ID for legacy profiles
      AppConfig.logger.d('Profile not found by id field, trying document ID scan for $profileId');
      final allProfilesSnapshot = await profileReference.get();
      for (var doc in allProfilesSnapshot.docs) {
        if (doc.id == profileId) {
          AppConfig.logger.d('Profile found by document ID scan: ${doc.id}');
          return doc.reference;
        }
      }
    } catch (e) {
      AppConfig.logger.e('Error getting profile reference: $e');
    }
    return null;
  }

  /// OPTIMIZED: Helper method to update a single profile field
  Future<bool> _updateProfileField(String profileId, Map<String, dynamic> data) async {
    try {
      final docRef = await _getProfileDocumentReference(profileId);
      if (docRef != null) {
        await docRef.update(data);
        return true;
      }
      AppConfig.logger.w('Profile $profileId not found for update');
    } catch (e) {
      AppConfig.logger.e('Error updating profile: $e');
    }
    return false;
  }

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

      // FIXED: Use for-loop with await instead of forEach with async (fire-and-forget)
      if (profile.instruments != null) {
        for (final entry in profile.instruments!.entries) {
          await InstrumentFirestore().addInstrument(
              profileId: profileId,
              instrumentId: entry.key);
        }
      }

      if (profile.genres != null) {
        for (final entry in profile.genres!.entries) {
          await GenreFirestore().addGenre(
              profileId: profileId,
              genreId: entry.key);
        }
      }

      if (profile.places != null) {
        for (final entry in profile.places!.entries) {
          await PlaceFirestore().addPlace(
              profileId: profileId,
              placeType: entry.value.type);
        }
      }

      if (profile.facilities != null) {
        for (final entry in profile.facilities!.entries) {
          await FacilityFirestore().addFacility(
              profileId: profileId,
              facilityType: entry.value.type);
        }
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
    AppConfig.logger.d("Retrieving Profile $profileId");
    AppProfile profile = AppProfile();

    // Validate profileId is not empty
    if (profileId.isEmpty) {
      AppConfig.logger.w('Cannot retrieve profile: profileId is empty');
      return profile;
    }

    try {
      // First try: Query by 'id' field (for profiles that have this field stored)
      final querySnapshot = await profileReference
          .where('id', isEqualTo: profileId)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        final profileSnapshot = querySnapshot.docs.first;
        profile = AppProfile.fromJSON(profileSnapshot.data());
        profile.id = profileSnapshot.id;
        AppConfig.logger.d("Profile found by 'id' field: ${profile.name}");
      } else {
        // Fallback: Search by document ID using collectionGroup with name field
        // This handles legacy profiles that don't have 'id' field stored
        AppConfig.logger.d("Profile not found by 'id' field, trying collectionGroup scan for $profileId");

        // Get all profiles and filter by document ID (less efficient but works for legacy data)
        final allProfilesSnapshot = await profileReference.get();
        for (var doc in allProfilesSnapshot.docs) {
          if (doc.id == profileId) {
            profile = AppProfile.fromJSON(doc.data());
            profile.id = doc.id;
            AppConfig.logger.d("Profile found by document ID scan: ${profile.name}");
            break;
          }
        }
      }

      if (profile.id.isEmpty) {
        AppConfig.logger.w("Profile $profileId not found");
      }
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

    // Validate profileId is not empty
    if (profileId.isEmpty) {
      AppConfig.logger.w('Cannot retrieve profile: profileId is empty');
      return null;
    }

    try {
      // OPTIMIZED: Query by 'id' field instead of FieldPath.documentId
      // (collectionGroup queries don't support FieldPath.documentId with simple IDs)
      final querySnapshot = await profileReference
          .where('id', isEqualTo: profileId)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        final profileDocument = querySnapshot.docs.first;
        profile = AppProfile.fromJSON(profileDocument.data());
        profile.id = profileDocument.id;
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
        // OPTIMIZED: If profileTypes is specified and has a single type, use Firestore filter
        // If multiple types, use whereIn query (Firestore supports up to 30 values)
        QuerySnapshot profileQuerySnapshot;
        if (profileTypes != null && profileTypes.length == 1) {
          profileQuerySnapshot = await profileReference
              .where(AppFirestoreConstants.type, isEqualTo: profileTypes.first.name)
              .get();
        } else if (profileTypes != null && profileTypes.length <= 30) {
          profileQuerySnapshot = await profileReference
              .where(AppFirestoreConstants.type, whereIn: profileTypes.map((t) => t.name).toList())
              .get();
        } else {
          // Fallback: get all profiles when no type filter or too many types
          profileQuerySnapshot = await profileReference.get();
        }

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

    // Validate profileId is not empty
    if (profileId.isEmpty) {
      AppConfig.logger.w('Cannot retrieve profile: profileId is empty');
      return profile;
    }

    try {
      // OPTIMIZED: Query by 'id' field instead of FieldPath.documentId
      // (collectionGroup queries don't support FieldPath.documentId with simple IDs)
      final querySnapshot = await profileReference
          .where('id', isEqualTo: profileId)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        final profileSnapshot = querySnapshot.docs.first;
        profile = AppProfile.fromJSON(profileSnapshot.data());
        profile.id = profileId;
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

      AppConfig.logger.d("Profiles query returned ${querySnapshot.docs.length} documents");

      if (querySnapshot.docs.isNotEmpty) {
        for (var profileSnapshot in querySnapshot.docs) {
          AppProfile profile = AppProfile.fromJSON(profileSnapshot.data());
          if (profileType == null || profile.type == profileType) {
            profile.id = profileSnapshot.id;
            AppConfig.logger.d("Found profile: ${profile.id} - ${profile.name}");
            profiles.add(profile);
          }
        }
      } else {
        AppConfig.logger.w("No profiles found in users/$userId/profiles");
      }
    } catch (e) {
      AppConfig.logger.e(e.toString());
    }

    AppConfig.logger.d("${profiles.length} profiles found for userId $userId");
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
      // OPTIMIZED: Query only appArtist profiles instead of all profiles
      final querySnapshot = await profileReference
          .where(AppFirestoreConstants.type, isEqualTo: ProfileType.appArtist.name)
          .get();

      for (var document in querySnapshot.docs) {
        if (mainInstrumentProfiles.length >= maxProfiles) break;

        AppProfile profile = AppProfile.fromJSON(document.data());
        profile.id = document.id;

        if (profile.id == selfProfileId) continue;

        // Check distance - skip if position is null
        if (profile.position == null || currentPosition == null) continue;

        if (PositionUtilities.distanceBetweenPositionsRounded(
            profile.position!, currentPosition) >= maxDistance) {
          AppConfig.logger.t("Profile ${profile.id} is out of max distance");
          continue;
        }

        profile.instruments = await InstrumentFirestore().retrieveInstruments(profile.id);
        if (profile.instruments!.keys.contains(instrumentId)) {
          if (profile.instruments?[instrumentId]?.isMain == true) {
            mainInstrumentProfiles[profile.id] = profile;
          } else {
            noMainInstrumentProfiles[profile.id] = profile;
          }
        }
      }

      // Fill remaining slots with non-main instrument profiles
      if (mainInstrumentProfiles.length < maxProfiles && noMainInstrumentProfiles.isNotEmpty) {
        for (var entry in noMainInstrumentProfiles.entries) {
          if (mainInstrumentProfiles.length >= maxProfiles) break;
          mainInstrumentProfiles[entry.key] = entry.value;
        }
      }
    } catch (e) {
      AppConfig.logger.e(e.toString());
    }

    AppConfig.logger.d("${mainInstrumentProfiles.length} Profiles found");
    return mainInstrumentProfiles;
  }


  @override
  Future<Map<String, AppProfile>> retrieveFromList(
      List<String> profileIds) async {
    AppConfig.logger.t("RetrievingProfiles from list of ${profileIds.length} IDs");

    // Filter out empty IDs
    final validIds = profileIds.where((id) => id.isNotEmpty).toList();
    if (validIds.isEmpty) {
      AppConfig.logger.w('No valid profile IDs provided');
      return profiles;
    }

    try {
      // OPTIMIZED: Query by 'id' field using whereIn
      // (collectionGroup queries don't support FieldPath.documentId with simple IDs)
      // Firestore limits whereIn to 30 items, so we batch if needed
      const batchSize = 30;
      for (var i = 0; i < validIds.length; i += batchSize) {
        final batch = validIds.skip(i).take(batchSize).toList();
        final querySnapshot = await profileReference
            .where('id', whereIn: batch)
            .get();

        for (var profileSnapshot in querySnapshot.docs) {
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
      // OPTIMIZED: Query only the 2 profiles we need instead of ALL profiles
      final results = await Future.wait([
        _updateProfileField(profileId, {
          AppFirestoreConstants.following: FieldValue.arrayUnion([followedProfileId])
        }),
        _updateProfileField(followedProfileId, {
          AppFirestoreConstants.followers: FieldValue.arrayUnion([profileId])
        }),
      ]);

      if (results.every((success) => success)) {
        AppConfig.logger.d("$profileId is now following $followedProfileId");
        return true;
      }
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
      // OPTIMIZED: Query only the 2 profiles we need instead of ALL profiles
      final results = await Future.wait([
        _updateProfileField(profileId, {
          AppFirestoreConstants.following: FieldValue.arrayRemove([unfollowProfileId])
        }),
        _updateProfileField(unfollowProfileId, {
          AppFirestoreConstants.followers: FieldValue.arrayRemove([profileId])
        }),
      ]);

      if (results.every((success) => success)) {
        AppConfig.logger.d("$profileId is now unfollowing $unfollowProfileId");
        return true;
      }
    } catch (e) {
      AppConfig.logger.e(e.toString());
    }
    return false;
  }


  @override
  Future<bool> blockProfile(
      {required String profileId, required String profileToBlock}) async {
    AppConfig.logger.d("$profileId would be blocking $profileToBlock");

    try {
      // OPTIMIZED: Query only the 2 profiles we need instead of ALL profiles
      final results = await Future.wait([
        _updateProfileField(profileId, {
          AppFirestoreConstants.following: FieldValue.arrayRemove([profileToBlock]),
          AppFirestoreConstants.blockTo: FieldValue.arrayUnion([profileToBlock])
        }),
        _updateProfileField(profileToBlock, {
          AppFirestoreConstants.followers: FieldValue.arrayRemove([profileId]),
          AppFirestoreConstants.blockedBy: FieldValue.arrayUnion([profileId])
        }),
      ]);

      if (results.every((success) => success)) {
        AppConfig.logger.d("$profileId has blocked $profileToBlock");
        return true;
      }
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
      // OPTIMIZED: Query only the 2 profiles we need instead of ALL profiles
      final results = await Future.wait([
        _updateProfileField(profileId, {
          AppFirestoreConstants.blockTo: FieldValue.arrayRemove([profileToUnblock]),
        }),
        _updateProfileField(profileToUnblock, {
          AppFirestoreConstants.blockedBy: FieldValue.arrayRemove([profileId])
        }),
      ]);

      if (results.every((success) => success)) {
        AppConfig.logger.d("$profileId has unblocked $profileToUnblock");
        return true;
      }
    } catch (e) {
      AppConfig.logger.e(e.toString());
    }
    return false;
  }


  @override
  Future<bool> updatePosition(String profileId, Position newPosition) async {
    AppConfig.logger.d("$profileId updating location");

    String address = await PositionUtilities.getFormattedAddressFromPosition(newPosition);

    // OPTIMIZED: Use helper method instead of fetching ALL profiles
    final success = await _updateProfileField(profileId, {
      AppFirestoreConstants.position: jsonEncode(newPosition),
      AppFirestoreConstants.address: address,
    });

    if (success) {
      AppConfig.logger.d("$profileId location updated");
    }
    return success;
  }


  @override
  Future<bool> addPost(String profileId, String postId) async {
    AppConfig.logger.d("$profileId would add $postId");

    // OPTIMIZED: Use helper method instead of fetching ALL profiles
    final success = await _updateProfileField(profileId, {
      AppFirestoreConstants.posts: FieldValue.arrayUnion([postId])
    });

    if (success) {
      AppConfig.logger.d("Profile $profileId has post $postId");
    }
    return success;
  }


  @override
  Future<bool> removePost(String profileId, String postId) async {
    AppConfig.logger.t("$profileId would remove $postId");

    // OPTIMIZED: Use helper method instead of fetching ALL profiles
    final success = await _updateProfileField(profileId, {
      AppFirestoreConstants.posts: FieldValue.arrayRemove([postId])
    });

    if (success) {
      AppConfig.logger.d("$profileId has removed post $postId");
    }
    return success;
  }


  @override
  Future<bool> hidePost(String profileId, String postId) async {
    AppConfig.logger.d("$profileId would hide $postId");

    // OPTIMIZED: Use helper method instead of fetching ALL profiles
    final success = await _updateProfileField(profileId, {
      AppFirestoreConstants.hiddenPosts: FieldValue.arrayUnion([postId])
    });

    if (success) {
      AppConfig.logger.d("Profile $profileId has hidden $postId");
    }
    return success;
  }


  @override
  Future<bool> addComment(String profileId, String commentId) async {
    AppConfig.logger.d("$profileId would add $commentId");

    // OPTIMIZED: Use helper method instead of fetching ALL profiles
    final success = await _updateProfileField(profileId, {
      AppFirestoreConstants.comments: FieldValue.arrayUnion([commentId])
    });

    if (success) {
      AppConfig.logger.d("Profile $profileId has added $commentId");
    }
    return success;
  }


  @override
  Future<bool> removeComment(String profileId, String commentId) async {
    AppConfig.logger.d("$profileId would remove $commentId");

    // OPTIMIZED: Use helper method instead of fetching ALL profiles
    final success = await _updateProfileField(profileId, {
      AppFirestoreConstants.comments: FieldValue.arrayRemove([commentId])
    });

    if (success) {
      AppConfig.logger.d("Profile $profileId has removed $commentId");
    }
    return success;
  }


  @override
  Future<bool> hideComment(String profileId, String commentId) async {
    AppConfig.logger.d("$profileId would hide $commentId");

    // OPTIMIZED: Use helper method instead of fetching ALL profiles
    final success = await _updateProfileField(profileId, {
      AppFirestoreConstants.hiddenComments: FieldValue.arrayUnion([commentId])
    });

    if (success) {
      AppConfig.logger.d("Profile $profileId has hidden $commentId");
    }
    return success;
  }


  @override
  Future<bool> updateName(String profileId, String profileName) async {
    AppConfig.logger.d("Updating profile $profileId to name $profileName}");

    // OPTIMIZED: Use helper method instead of fetching ALL profiles
    return await _updateProfileField(profileId, {
      AppFirestoreConstants.name: profileName,
      AppFirestoreConstants.lastNameUpdate: DateTime.now().millisecondsSinceEpoch,
    });
  }


  @override
  Future<bool> updateAboutMe(String profileId, String aboutMe) async {
    AppConfig.logger.d("Updating profile $profileId to description $aboutMe}");

    // OPTIMIZED: Use helper method instead of fetching ALL profiles
    return await _updateProfileField(profileId, {
      AppFirestoreConstants.aboutMe: aboutMe
    });
  }

  @override
  Future<bool> updateAddress(String profileId, String address) async {
    AppConfig.logger.i("Updating Profile $profileId with new address as $address");

    // OPTIMIZED: Use helper method instead of fetching ALL profiles
    return await _updateProfileField(profileId, {
      AppFirestoreConstants.address: address,
    });
  }

  @override
  Future<bool> updatePhoneNumber(String profileId, String phoneNumber) async {
    AppConfig.logger.i("Updating Profile $profileId with new phoneNumber as $phoneNumber");

    // OPTIMIZED: Use helper method instead of fetching ALL profiles
    return await _updateProfileField(profileId, {
      AppFirestoreConstants.phoneNumber: phoneNumber,
    });
  }

  @override
  Future<bool> updateType(String profileId, ProfileType type) async {
    AppConfig.logger.i("Updating Profile $profileId with new type as ${type.name}");

    // OPTIMIZED: Use helper method instead of fetching ALL profiles
    return await _updateProfileField(profileId, {
      AppFirestoreConstants.type: type.value,
    });
  }

  Future<bool> updateUsageReason(String profileId, UsageReason reason) async {
    AppConfig.logger.i("Updating Profile $profileId with new usage reason as ${reason.name}");

    // OPTIMIZED: Use helper method instead of fetching ALL profiles
    return await _updateProfileField(profileId, {
      AppFirestoreConstants.usageReason: reason.name,
    });
  }

  @override
  Future<bool> updateVerificationLevel(String profileId,
      VerificationLevel verificationLevel) async {
    AppConfig.logger.i("Updating Profile $profileId with VerificationLevel as ${verificationLevel.name}");

    // OPTIMIZED: Use helper method instead of fetching ALL profiles
    return await _updateProfileField(profileId, {
      AppFirestoreConstants.verificationLevel: verificationLevel.name,
    });
  }


  @override
  Future<bool> addEvent(String profileId, String eventId,
      EventAction eventAction) async {
    AppConfig.logger.t("$profileId would add $eventId");

    // OPTIMIZED: Use helper method instead of fetching ALL profiles
    String eventListToUpdate = switch (eventAction) {
      EventAction.organize => AppFirestoreConstants.events,
      EventAction.watch => AppFirestoreConstants.watchingEvents,
      EventAction.assist => AppFirestoreConstants.goingEvents,
      EventAction.play => AppFirestoreConstants.playingEvents,
    };

    final success = await _updateProfileField(profileId, {
      eventListToUpdate: FieldValue.arrayUnion([eventId])
    });

    if (success) {
      AppConfig.logger.d("$profileId has added event $eventId");
    }
    return success;
  }


  @override
  Future<bool> removeEvent(String profileId, String eventId,
      EventAction eventAction) async {
    AppConfig.logger.t("$profileId would remove $eventId");

    // OPTIMIZED: Use helper method instead of fetching ALL profiles
    String eventListToUpdate = switch (eventAction) {
      EventAction.organize => AppFirestoreConstants.events,
      EventAction.watch => AppFirestoreConstants.watchingEvents,
      EventAction.assist => AppFirestoreConstants.goingEvents,
      EventAction.play => AppFirestoreConstants.playingEvents,
    };

    final success = await _updateProfileField(profileId, {
      eventListToUpdate: FieldValue.arrayRemove([eventId])
    });

    if (success) {
      AppConfig.logger.t("$profileId has removed event $eventId");
    }
    return success;
  }


  @override
  Future<bool> addFavoriteItem(String profileId, String itemId) async {
    AppConfig.logger.t("Adding item $itemId to Profile $profileId favorites");

    // OPTIMIZED: Use helper method instead of fetching ALL profiles
    return await _updateProfileField(profileId, {
      AppFirestoreConstants.favoriteItems: FieldValue.arrayUnion([itemId])
    });
  }

  @override
  Future<bool> addFavoriteItems(String profileId, List<String> itemIds) async {
    AppConfig.logger.t("Adding ${itemIds.length} items to Profile $profileId favorites");

    // OPTIMIZED: Use helper method instead of fetching ALL profiles
    return await _updateProfileField(profileId, {
      AppFirestoreConstants.favoriteItems: FieldValue.arrayUnion(itemIds)
    });
  }

  @override
  Future<bool> removeFavoriteItem(String profileId, String itemId) async {
    AppConfig.logger.t("Removing item $itemId from Profile $profileId favorites");

    // OPTIMIZED: Use helper method instead of fetching ALL profiles
    return await _updateProfileField(profileId, {
      AppFirestoreConstants.favoriteItems: FieldValue.arrayRemove([itemId])
    });
  }

  @override
  Future<bool> removeFavoriteItems(String profileId,
      List<String> itemIds) async {
    AppConfig.logger.t("Removing ${itemIds.length} items from Profile $profileId favorites");

    // OPTIMIZED: Use helper method instead of fetching ALL profiles
    return await _updateProfileField(profileId, {
      AppFirestoreConstants.favoriteItems: FieldValue.arrayRemove(itemIds)
    });
  }

  @override
  Future<bool> addChamberPreset(
      {required String profileId, required String chamberPresetId}) async {
    AppConfig.logger.d("Adding preset $chamberPresetId to Profile $profileId");

    // OPTIMIZED: Use helper method instead of fetching ALL profiles
    return await _updateProfileField(profileId, {
      AppFirestoreConstants.chamberPresets: FieldValue.arrayUnion([chamberPresetId])
    });
  }

  @override
  Future<bool> addBand(
      {required String profileId, required String bandId}) async {
    AppConfig.logger.t("Add band $bandId for profile $profileId");

    // OPTIMIZED: Use helper method instead of fetching ALL profiles
    return await _updateProfileField(profileId, {
      AppFirestoreConstants.bands: FieldValue.arrayUnion([bandId])
    });
  }


  @override
  Future<bool> removeBand(
      {required String profileId, required String bandId}) async {
    AppConfig.logger.t("Remove band $bandId for profile $profileId");

    // OPTIMIZED: Use helper method instead of fetching ALL profiles
    return await _updateProfileField(profileId, {
      AppFirestoreConstants.bands: FieldValue.arrayRemove([bandId])
    });
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

    // OPTIMIZED: Use helper method instead of fetching ALL profiles
    String requestsToUpdate = switch (requestType) {
      RequestType.received => AppFirestoreConstants.requests,
      RequestType.sent => AppFirestoreConstants.sentRequests,
      RequestType.invitation => AppFirestoreConstants.invitationRequests,
    };

    final success = await _updateProfileField(profileId, {
      requestsToUpdate: FieldValue.arrayUnion([requestId])
    });

    if (success) {
      AppConfig.logger.d("Profile $profileId has added request $requestId as type ${requestType.name}");
    }
    return success;
  }


  @override
  Future<bool> removeRequest(String profileId, String requestId,
      RequestType requestType) async {
    AppConfig.logger.d("$profileId would remove $requestId");

    // OPTIMIZED: Use helper method instead of fetching ALL profiles
    String requestsToRemove = switch (requestType) {
      RequestType.received => AppFirestoreConstants.requests,
      RequestType.sent => AppFirestoreConstants.sentRequests,
      RequestType.invitation => AppFirestoreConstants.invitationRequests,
    };

    final success = await _updateProfileField(profileId, {
      requestsToRemove: FieldValue.arrayRemove([requestId])
    });

    if (success) {
      AppConfig.logger.d("Profile $profileId has removed request $requestId");
    }
    return success;
  }


  @override
  Future<Map<String, AppProfile>> getFollowers(String profileId) async {
    AppConfig.logger.d("Start getFollowers for $profileId");

    Map<String, AppProfile> followersMap = {};
    try {
      // OPTIMIZED: Use retrieve() instead of fetching ALL profiles
      final profile = await retrieve(profileId);

      if (profile.followers != null) {
        for (var followerId in profile.followers!) {
          AppProfile? follower = await MateFirestore().getMateSimple(followerId);
          if (follower != null) {
            follower.instruments =
                await InstrumentFirestore().retrieveInstruments(followerId);
            followersMap[followerId] = follower;
          }
        }
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

    Map<String, AppProfile> followedMap = {};
    try {
      // OPTIMIZED: Use retrieve() instead of fetching ALL profiles
      final profile = await retrieve(profileId);

      if (profile.following != null) {
        for (var followedId in profile.following!) {
          AppProfile? followed = await MateFirestore().getMateSimple(followedId);
          if (followed != null) {
            followed.instruments =
                await InstrumentFirestore().retrieveInstruments(followedId);
            followedMap[followedId] = followed;
          }
        }
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
    AppConfig.logger.d("Updating photo URL for profile $profileId");

    // OPTIMIZED: Use helper method instead of fetching ALL profiles
    return await _updateProfileField(profileId, {
      AppFirestoreConstants.photoUrl: photoUrl
    });
  }


  @override
  Future<bool> updateCoverImgUrl(String profileId, String coverImgUrl) async {
    AppConfig.logger.d("Updating cover image URL for profile $profileId");

    // OPTIMIZED: Use helper method instead of fetching ALL profiles
    return await _updateProfileField(profileId, {
      AppFirestoreConstants.coverImgUrl: coverImgUrl
    });
  }

  @override
  Future<QuerySnapshot<Object?>> handleSearch(String query) {
    // TODO: implement handleSearch
    throw UnimplementedError();
  }


  Future<String> retrievedFcmToken(String profileId) async {
    AppConfig.logger.t("Retrieving FCM Token for Profile $profileId");

    String fcmToken = "";

    // Validate profileId is not empty
    if (profileId.isEmpty) {
      AppConfig.logger.w('Cannot retrieve FCM token: profileId is empty');
      return fcmToken;
    }

    try {
      // OPTIMIZED: Query by 'id' field instead of FieldPath.documentId
      // (collectionGroup queries don't support FieldPath.documentId with simple IDs)
      final querySnapshot = await profileReference
          .where('id', isEqualTo: profileId)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        final profile = querySnapshot.docs.first;
        final userId = profile.reference.parent.parent?.id ?? "";
        AppConfig.logger.t("Reference id: $userId");

        if (userId.isNotEmpty) {
          // usersReference is a regular collection, so we use doc() directly
          final userDoc = await usersReference.doc(userId).get();

          if (userDoc.exists && userDoc.data() != null) {
            fcmToken = AppUser.fromJSON(userDoc.data()!).fcmToken;
            AppConfig.logger.t("FCM Token $fcmToken");
          } else {
            AppConfig.logger.w("No user found for id $userId");
          }
        }
      }
    } catch (e) {
      AppConfig.logger.e(e.toString());
    }

    if (fcmToken.isEmpty) {
      AppConfig.logger.w("Push Notification not sent as FCM Token was not found for users device");
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
        profile.chambers = await Sint.find<ChamberRepository>().fetchAll(ownerId: profile.id);
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

    // OPTIMIZED: Use helper method instead of fetching ALL profiles
    return await _updateProfileField(profileId, {
      AppFirestoreConstants.lastSpotifySync: DateTime.now().millisecondsSinceEpoch
    });
  }

  @override
  Future<bool> addBlogEntry(String profileId, String blogEntryId) async {
    AppConfig.logger.d("$profileId would add $blogEntryId");

    // OPTIMIZED: Use helper method instead of fetching ALL profiles
    final success = await _updateProfileField(profileId, {
      AppFirestoreConstants.blogEntries: FieldValue.arrayUnion([blogEntryId])
    });

    if (success) {
      AppConfig.logger.d("Profile $profileId has blogEntry $blogEntryId");
    }
    return success;
  }


  @override
  Future<bool> removeBlogEntry(String profileId, String blogEntryId) async {
    AppConfig.logger.d("$profileId would remove $blogEntryId");

    // OPTIMIZED: Use helper method instead of fetching ALL profiles
    final success = await _updateProfileField(profileId, {
      AppFirestoreConstants.blogEntries: FieldValue.arrayRemove([blogEntryId])
    });

    if (success) {
      AppConfig.logger.d("$profileId has removed blogEntry $blogEntryId");
    }
    return success;
  }

  @override
  Future<bool> removeAllFavoriteItems(String profileId) async {
    AppConfig.logger.d("Removing all favorite items for profile $profileId");

    // OPTIMIZED: Use helper method instead of fetching ALL profiles
    // Note: Original code had a bug - it was updating ALL profiles instead of just the specified one
    return await _updateProfileField(profileId, {
      AppFirestoreConstants.favoriteItems: FieldValue.delete()
    });
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
      // OPTIMIZED: Query only facilitator profiles instead of all profiles
      final querySnapshot = await profileReference
          .where(AppFirestoreConstants.type, isEqualTo: ProfileType.facilitator.name)
          .get();

      for (var document in querySnapshot.docs) {
        if (facilityProfiles.length >= maxProfiles) break;

        AppProfile profile = AppProfile.fromJSON(document.data());
        profile.id = document.id;

        if (profile.id == selfProfileId) continue;

        // Check distance - skip if position is null
        if (profile.position == null || currentPosition == null) continue;

        if (PositionUtilities.distanceBetweenPositionsRounded(
            profile.position!, currentPosition) >= maxDistance) {
          AppConfig.logger.t("Profile ${profile.id} ${profile.name} is out of max distance");
          continue;
        }

        if (profile.address.isEmpty && profile.position != null) {
          profile.address = await PositionUtilities.getFormattedAddressFromPosition(profile.position!);
        }

        if (profile.posts?.isEmpty ?? true) {
          AppConfig.logger.t("Profile ${profile.id} ${profile.name} has no posts");
          continue;
        }

        List<Post> profilePosts = await PostFirestore().getProfilePosts(profile.id);
        List<String> postImgUrls = [];
        for (var element in profilePosts) {
          if (postImgUrls.length < 6) {
            postImgUrls.add(element.mediaUrl);
          }
        }

        if (facilityType != null) {
          profile.facilities = await FacilityFirestore().retrieveFacilities(profile.id);
          if (profile.facilities!.keys.contains(facilityType.value)) {
            if (profile.facilities?[facilityType.value]?.isMain == true) {
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
      }

      // Fill remaining slots with non-main facility profiles
      if (facilityProfiles.length < maxProfiles && noMainFacilityProfiles.isNotEmpty) {
        for (var entry in noMainFacilityProfiles.entries) {
          if (facilityProfiles.length >= maxProfiles) break;
          facilityProfiles[entry.key] = entry.value;
        }
      }
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
      // OPTIMIZED: Query only host profiles instead of all profiles
      final querySnapshot = await profileReference
          .where(AppFirestoreConstants.type, isEqualTo: ProfileType.host.name)
          .get();

      for (var document in querySnapshot.docs) {
        if (hostProfiles.length >= maxProfiles) break;

        AppProfile profile = AppProfile.fromJSON(document.data());
        profile.id = document.id;

        if (profile.id == selfProfileId) continue;

        // Check distance - skip if position is null
        if (profile.position == null || currentPosition == null) continue;

        if (PositionUtilities.distanceBetweenPositionsRounded(
            profile.position!, currentPosition) >= maxDistance) {
          AppConfig.logger.t("Profile ${profile.id} ${profile.name} is out of max distance");
          continue;
        }

        if (profile.address.isEmpty && profile.position != null) {
          profile.address = await PositionUtilities.getFormattedAddressFromPosition(profile.position!);
        }

        if (profile.posts?.isEmpty ?? true) {
          AppConfig.logger.t("Profile ${profile.id} ${profile.name} has no posts");
          continue;
        }

        List<Post> profilePosts = await PostFirestore().getProfilePosts(profile.id);
        List<String> postImgUrls = [];
        for (var element in profilePosts) {
          if (postImgUrls.length < 6) {
            postImgUrls.add(element.mediaUrl);
          }
        }

        if (placeType != null) {
          profile.facilities = await FacilityFirestore().retrieveFacilities(profile.id);
          if (profile.facilities!.keys.contains(placeType.value)) {
            if (profile.facilities?[placeType.value]?.isMain == true) {
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
      }

      // Fill remaining slots with non-main place profiles
      if (hostProfiles.length < maxProfiles && noMainPlaceProfiles.isNotEmpty) {
        for (var entry in noMainPlaceProfiles.entries) {
          if (hostProfiles.length >= maxProfiles) break;
          hostProfiles[entry.key] = entry.value;
        }
      }
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

  /// Search profiles by name (case-insensitive partial match)
  /// OPTIMIZED: Removed expensive fallback that was fetching ALL profiles
  /// NOTE: Requires 'searchName' field to be set on profiles for search to work
  Future<List<AppProfile>> searchByName(String query, {int limit = 20}) async {
    AppConfig.logger.d("Searching profiles by name: $query");

    List<AppProfile> results = [];

    if (query.trim().isEmpty) {
      return results;
    }

    try {
      // Firestore doesn't support native case-insensitive search,
      // so we use a range query with lowercased searchName field
      final searchKey = query.toLowerCase().trim();
      final endKey = '$searchKey\uf8ff'; // Unicode high character for range end

      QuerySnapshot querySnapshot = await profileReference
          .where('searchName', isGreaterThanOrEqualTo: searchKey)
          .where('searchName', isLessThanOrEqualTo: endKey)
          .limit(limit)
          .get();

      for (var doc in querySnapshot.docs) {
        if (!doc.exists) continue;
        AppProfile profile = AppProfile.fromJSON(doc.data());
        profile.id = doc.id;
        results.add(profile);
      }

      // OPTIMIZED: Also try name field with range query as secondary search
      // Try both original case and capitalized version for better matching
      if (results.isEmpty) {
        final trimmedQuery = query.trim();

        // Try with original input case first
        var nameQuerySnapshot = await profileReference
            .where(AppFirestoreConstants.name, isGreaterThanOrEqualTo: trimmedQuery)
            .where(AppFirestoreConstants.name, isLessThanOrEqualTo: '$trimmedQuery\uf8ff')
            .limit(limit)
            .get();

        for (var doc in nameQuerySnapshot.docs) {
          if (!doc.exists) continue;
          AppProfile profile = AppProfile.fromJSON(doc.data());
          profile.id = doc.id;
          results.add(profile);
        }

        // If no results, try with capitalized first letter (e.g., "yori" -> "Yori")
        if (results.isEmpty && trimmedQuery.isNotEmpty) {
          final capitalizedQuery = trimmedQuery[0].toUpperCase() + trimmedQuery.substring(1).toLowerCase();
          if (capitalizedQuery != trimmedQuery) {
            nameQuerySnapshot = await profileReference
                .where(AppFirestoreConstants.name, isGreaterThanOrEqualTo: capitalizedQuery)
                .where(AppFirestoreConstants.name, isLessThanOrEqualTo: '$capitalizedQuery\uf8ff')
                .limit(limit)
                .get();

            for (var doc in nameQuerySnapshot.docs) {
              if (!doc.exists) continue;
              AppProfile profile = AppProfile.fromJSON(doc.data());
              profile.id = doc.id;
              results.add(profile);
            }
          }
        }

        // Also try all uppercase (e.g., "yori" -> "YORI")
        if (results.isEmpty && trimmedQuery.isNotEmpty) {
          final upperQuery = trimmedQuery.toUpperCase();
          if (upperQuery != trimmedQuery) {
            nameQuerySnapshot = await profileReference
                .where(AppFirestoreConstants.name, isGreaterThanOrEqualTo: upperQuery)
                .where(AppFirestoreConstants.name, isLessThanOrEqualTo: '$upperQuery\uf8ff')
                .limit(limit)
                .get();

            for (var doc in nameQuerySnapshot.docs) {
              if (!doc.exists) continue;
              AppProfile profile = AppProfile.fromJSON(doc.data());
              profile.id = doc.id;
              results.add(profile);
            }
          }
        }
      }

      AppConfig.logger.d("Found ${results.length} profiles matching '$query'");
    } catch (e) {
      AppConfig.logger.e("Error searching profiles: $e");
    }

    return results;
  }

}
