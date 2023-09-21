import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';

import '../../domain/model/app_profile.dart';
import '../../domain/model/app_user.dart';
import '../../domain/model/facility.dart';
import '../../domain/model/place.dart';
import '../../domain/model/post.dart';
import '../../domain/repository/user_repository.dart';
import '../../utils/app_utilities.dart';
import '../../utils/enums/app_currency.dart';
import '../../utils/enums/facilitator_type.dart';
import '../../utils/enums/place_type.dart';
import '../../utils/enums/profile_type.dart';
import '../../utils/enums/usage_reason.dart';
import 'constants/app_firestore_collection_constants.dart';
import 'constants/app_firestore_constants.dart';
import 'facility_firestore.dart';
import 'place_firestore.dart';
import 'post_firestore.dart';
import 'profile_firestore.dart';

class UserFirestore implements UserRepository {

  var logger = AppUtilities.logger;
  final userReference = FirebaseFirestore.instance.collection(AppFirestoreCollectionConstants.users);
  final profileReference = FirebaseFirestore.instance.collectionGroup(AppFirestoreCollectionConstants.profiles);

  @override
  Future<bool> insert(AppUser user) async {
    String userId = user.id.toLowerCase();
    logger.i("Inserting user $userId to Firestore");

    Map<String,dynamic> userJSON = user.toJSON();
    logger.d(userJSON.toString());

    DocumentReference documentReferencer = userReference.doc(userId);

    try {
      await documentReferencer.set(userJSON)
          .whenComplete(() => logger.i('User added to the database'))
          .catchError((e) => logger.e(e));

      logger.d("User ${user.toString()} inserted successfully.");
      return true;

    } catch (e) {
      await remove(userId) ? logger.i("User rollback") : logger.e(e.toString());
      return false;
    }
  }

  @override
  Future<List<AppUser>> getAll() async {
    logger.d("Get all Users");

    List<AppUser> users = [];
    try {
      QuerySnapshot querySnapshot = await userReference.get();
      for (var queryDocumentSnapshot in querySnapshot.docs) {
        if (queryDocumentSnapshot.exists) {
          AppUser user = AppUser.fromJSON(queryDocumentSnapshot.data());
          user.id = queryDocumentSnapshot.id;
          users.add(user);
        }
      }
    } catch (e) {
      logger.e(e.toString());
    }

    return users;
  }

  @override
  Future<AppUser> getById(String userId) async {
    logger.d("Start Id $userId");
    AppUser user = AppUser();
    try {
        DocumentSnapshot documentSnapshot = await userReference.doc(userId).get();
        if (documentSnapshot.exists) {
          user = AppUser.fromJSON(documentSnapshot.data());
          user.id = documentSnapshot.id;

          AppProfile profile = AppProfile();

          if(user.currentProfileId.isNotEmpty) {
             profile = await ProfileFirestore().retrieve(user.currentProfileId);
             if(profile.id.isNotEmpty) {
               profile = await ProfileFirestore().getProfileFeatures(profile);
               user.profiles = [profile];
             } else {
               logger.d("Profile not found");
             }
          } else {
             user.profiles = await ProfileFirestore().retrieveProfiles(userId);
             if(user.profiles.isNotEmpty && user.profiles.first.id.isNotEmpty) {
               user.profiles.first = await ProfileFirestore()
                   .getProfileFeatures(user.profiles.first);
             }
          }
        } else {
          logger.i("No user found");
        }
    } catch (e) {
      logger.e(e.toString());
    }

    return user;
  }

  @override
  Future<AppUser> getByProfileId(String profileId) async {
    logger.d("Getting user for ProfileId: $profileId");
    AppUser user = AppUser();
    String userId = "";
    QuerySnapshot userQuerySnapshot;

    try {
      QuerySnapshot querySnapshot = await profileReference.get();

      for (var profile in querySnapshot.docs) {
        if(profile.id == profileId) {
          logger.w("Reference id: ${profile.reference.parent.parent!.id}");
          DocumentReference documentReference = profile.reference;
          userId = documentReference.parent.parent!.id;

          userQuerySnapshot = await userReference
              .where(FieldPath.documentId, isEqualTo: userId)
              .get();
          logger.i("${userQuerySnapshot.docs.length} users found");

          user = AppUser.fromJSON(userQuerySnapshot.docs.first.data());
        }
      }
    } catch (e) {
      logger.e(e.toString());
    }

    return user;
  }


  @override
  Future<bool> remove(String userId) async {
    logger.d("Removing User $userId from Firestore");

    try {
      await userReference.doc(userId).delete();
      logger.d("User $userId removed successfully.");
    } catch (e) {
      logger.e(e);
      return false;
    }

    return true;
  }


  @override
  Future<bool> updateAndroidNotificationToken(String userId, String token) async {
    logger.d("Updating Android Notification Token for User $userId");

    try {
      await userReference.doc(userId).update({AppFirestoreConstants.androidNotificationToken: token});
      logger.d("User $userId removed successfully.");
      return true;
    } catch (e) {
      logger.e(e);
      return false;
    }
  }


  @override
  Future<bool> isAvailableEmail(String email) async {

    logger.d("Verify if email $email is already in use");

    try {
      QuerySnapshot querySnapshot = await userReference
          .where(AppFirestoreConstants.email, isEqualTo: email)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        logger.i("Email already in use");
        return false;
      }

      logger.d("Email is available");
      return true;

    } catch (e) {
      logger.e(e.toString());
      rethrow;
    }
  }


  @override
  Future<bool> isAvailablePhone(String phoneNumber) async {

    logger.d("Verify if phoneNumber $phoneNumber is available");

    try {
      QuerySnapshot querySnapshot = await userReference.where(
          AppFirestoreConstants.phoneNumber,
          isEqualTo: phoneNumber).get();

      if (querySnapshot.docs.isNotEmpty) {
        logger.i("Phone number already in use");
        return false;
      }

      logger.d("No phoneNumber found");
      return true;

    } catch (e) {
      logger.e(e.toString());
      rethrow;
    }
  }


  @override
  Future<bool> addToWallet(String userId, double amount, {AppCurrency appCurrency = AppCurrency.appCoin}) async {
    logger.d("Entering addToWalletMethod");

    AppUser user = AppUser();
    try {
      DocumentSnapshot documentSnapshot = await userReference.doc(userId).get();
      if (documentSnapshot.exists) {
        user = AppUser.fromJSON(documentSnapshot.data());
        user.id = documentSnapshot.id;
        user.wallet.amount = user.wallet.amount + amount;

        await documentSnapshot.reference.update({
          AppFirestoreConstants.wallet: jsonEncode(user.wallet)
        });

        logger.d("User Wallet updated");
        return true;
      } else {
        logger.i("No user found");
      }
    } catch (e) {
      logger.e(e.toString());
    }

    return false;
  }


  Future<bool> subtractFromWallet(String userId, double amount, {AppCurrency appCurrency = AppCurrency.appCoin}) async {
    logger.d("Subtraction $amount Aopcoins from UserId $userId");
    AppUser user = AppUser();
    try {
      DocumentSnapshot documentSnapshot = await userReference.doc(userId).get();
      if (documentSnapshot.exists) {
        user = AppUser.fromJSON(documentSnapshot.data());
        user.id = documentSnapshot.id;
        user.wallet.amount = user.wallet.amount - amount;

        await documentSnapshot.reference.update({
          AppFirestoreConstants.wallet: user.wallet.toJSON()
        });

        logger.i("User Wallet updated for user $userId");
        return true;
      } else {
        logger.i("No user found");
      }
    } catch (e) {
      logger.e(e.toString());
    }

    return false;
  }


  @override
  Future<bool> updatePhotoUrl(String userId, String photoUrl) async {
    logger.d("");

    try {
      DocumentSnapshot documentSnapshot = await userReference.doc(userId).get();
      await documentSnapshot.reference.update({AppFirestoreConstants.photoUrl: photoUrl});

    } catch (e) {
      logger.e(e.toString());
      return false;
    }

    return true;
  }



  @override
  Future<bool> addOrderId({required String userId, required String orderId}) async {
    logger.d("Order $orderId would be added to User $userId");

    try {
      DocumentSnapshot documentSnapshot = await userReference
          .doc(userId).get();

      await documentSnapshot.reference.update({
        AppFirestoreConstants.orderIds: FieldValue.arrayUnion([orderId])
      });
      logger.d("Order $orderId is now at User $userId");
      return true;
    } catch (e) {
      logger.e(e.toString());
    }

    return false;
  }


  @override
  Future<bool> removeOrderId({required String userId, required String orderId}) async {
    logger.d("Order $orderId would be removed from User $userId");

    try {
      DocumentSnapshot documentSnapshot = await userReference
          .doc(userId).get();

      await documentSnapshot.reference.update({
        AppFirestoreConstants.orderIds: FieldValue.arrayRemove([orderId])
      });
      logger.d("Order $orderId was removed from User $userId");
      return true;
    } catch (e) {
      logger.e(e.toString());
    }

    return false;
  }


  @override
  Future<bool> updateFcmToken(String userId, String fcmToken) async {
    logger.d("updating Firebase Cloud Messaging Token for User $userId");

    try {
      DocumentSnapshot documentSnapshot = await userReference.doc(userId).get();
      await documentSnapshot.reference.update({AppFirestoreConstants.fcmToken: fcmToken});
      logger.i("FCM Token successfully updated for User $userId");
      return true;
    } catch (e) {
      logger.e(e.toString());
    }

    return false;
  }

  @override
  Future<void> updateLastTimeOn(String userId) async {
    logger.v("updating LastTimeOn for user $userId");

    try {
      DocumentSnapshot documentSnapshot = await userReference.doc(userId).get();
      await documentSnapshot.reference.update({AppFirestoreConstants.lastTimeOn: DateTime.now().millisecondsSinceEpoch});
      logger.i("LastTimeOn successfully updated for User $userId");
    } catch (e) {
      logger.e(e.toString());
    }

  }

  @override
  Future<String> retrieveFcmToken(String userId) async {
    logger.d("Retrieving Firebase Cloud Messaging Token for User $userId device");

    String fcmToken = "";
    try {
      DocumentSnapshot documentSnapshot = await userReference.doc(userId).get();
      fcmToken = AppUser.fromJSON(documentSnapshot.data()).fcmToken;
      logger.i("FCM Token $fcmToken retrieved");
    } catch (e) {
      logger.e(e.toString());
    }

    return fcmToken;
  }

  @override
  Future<bool> updateSpotifyToken(String userId, String spotifyToken) async {
    logger.d("updating Spotify Access Token for User $userId");

    try {
      DocumentSnapshot documentSnapshot = await userReference.doc(userId).get();
      await documentSnapshot.reference.update({AppFirestoreConstants.spotifyToken: spotifyToken});
      logger.i("Spotify Token successfully updated for User $userId");
      return true;
    } catch (e) {
      logger.e(e.toString());
    }

    return false;
  }

  Future<AppProfile> updateCurrentProfile(String userId, String currentProfileId) async {
    logger.d("updating current profile $userId");
    AppProfile profile = AppProfile();
    try {
      DocumentSnapshot documentSnapshot = await userReference.doc(userId).get();
      await documentSnapshot.reference.update({AppFirestoreConstants.currentProfileId: currentProfileId});
      logger.i("CurrentProfileId successfully updated for User $userId");
      profile = await ProfileFirestore().retrieveFull(currentProfileId);
    } catch (e) {
      logger.e(e.toString());
    }

    return profile;
  }

  @override
  Future<List<AppUser>> getWithParameters({
    bool needsPhone  = false, bool includeProfile = false,
    List<ProfileType>? profileTypes, FacilityType? facilityType, PlaceType? placeType,
    List<UsageReason>? usageReasons, Position? currentPosition, int maxDistance = 30,}) async {
    logger.d("Get all Users by paremeters");

    List<AppUser> users = [];
    List<AppUser> usersWOPhone = [];
    AppProfile profile = AppProfile();
    Map<String,AppProfile> facilityProfiles = <String, AppProfile>{};
    Map<String,AppProfile> placeProfiles = <String, AppProfile>{};
    Map<String,AppProfile> noMainFacilityProfiles = <String, AppProfile>{};
    Map<String,AppProfile> noMainPlaceProfiles = <String, AppProfile>{};

    try {
      QuerySnapshot querySnapshot = await userReference.get();
      QuerySnapshot profileQuerySnapshot = await profileReference.get();
      List<Post> totalPosts = await PostFirestore().retrievePosts();
      for (var queryDocumentSnapshot in querySnapshot.docs) {
        if (queryDocumentSnapshot.exists) {
          AppUser user = AppUser.fromJSON(queryDocumentSnapshot.data());
          user.id = queryDocumentSnapshot.id;

          if(needsPhone && user.phoneNumber.isEmpty) {
            usersWOPhone.add(user);
            logger.v("${user.name} has no phone number");
            continue;
          }

          if(includeProfile) {
            for (var document in profileQuerySnapshot.docs) {
              if(document.reference.parent.parent!.id == user.id) {
                profile = AppProfile.fromJSON(document.data());
                profile.id = document.id;
                if((profileTypes == null || profileTypes.contains(profile.type))
                    && (usageReasons == null || usageReasons.contains(profile.reason))) {
                  if(profile.posts?.isNotEmpty ?? false) {
                    if(AppUtilities.distanceBetweenPositionsRounded(profile.position!, currentPosition!) < maxDistance) {
                      List<Post> profilePosts = totalPosts.where((element) => element.ownerId == profile.id).toList();
                      List<String> postImgUrls = [];
                      for (var profilePost in profilePosts) {
                        if(postImgUrls.length < 6 && profilePost.mediaUrl.isNotEmpty) {
                          postImgUrls.add(profilePost.mediaUrl);
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

                      if(placeType != null) {
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

                      if(profile.address.isEmpty && profile.position != null) {
                        profile.address = await AppUtilities.getAddressFromPlacerMark(profile.position!);
                        ProfileFirestore().updateAddress(profile.id, profile.address);
                      }
                      user.profiles.add(profile);
                    } else {
                      logger.v("Profile ${profile.id} ${profile.name} is out of max distance");
                    }
                  } else {
                    logger.v("Profile ${profile.id} ${profile.name} has not posts");
                  }

                }
              }
            }

            if(user.profiles.isEmpty) continue;
          }

          users.add(user);
        }
      }
    } catch (e) {
      logger.e(e.toString());
    }

    return users;
  }

  @override
  Future<List<String>> getFCMTokens() async {
    logger.d("Get available FCM Tokens from Users");

    List<String> fcmTokens = [];
    try {
      QuerySnapshot querySnapshot = await userReference.get();
      for (var queryDocumentSnapshot in querySnapshot.docs) {
        if (queryDocumentSnapshot.exists) {
          AppUser user = AppUser.fromJSON(queryDocumentSnapshot.data());
          if(user.fcmToken.isNotEmpty) {
            fcmTokens.add(user.fcmToken);
          }
        }
      }
    } catch (e) {
      logger.e(e.toString());
    }

    return fcmTokens;
  }

  @override
  Future<bool> addReleaseItem({required String userId, required String releaseItemId}) async {
    logger.d("ReleaseItem $releaseItemId would be added to User $userId");

    try {
      DocumentSnapshot documentSnapshot = await userReference
          .doc(userId).get();

      await documentSnapshot.reference.update({
        AppFirestoreConstants.releaseItemIds: FieldValue.arrayUnion([releaseItemId])
      });
      logger.d("ReleaseItem $releaseItemId is now at User $userId");
      return true;
    } catch (e) {
      logger.e(e.toString());
    }

    return false;
  }

}
