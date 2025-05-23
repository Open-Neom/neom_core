import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';

import '../../app_flavour.dart';
import '../../domain/model/app_profile.dart';
import '../../domain/model/app_user.dart';
import '../../domain/model/facility.dart';
import '../../domain/model/place.dart';
import '../../domain/model/post.dart';
import '../../domain/repository/user_repository.dart';
import '../../utils/app_utilities.dart';
import '../../utils/core_utilities.dart';
import '../../utils/enums/app_in_use.dart';
import '../../utils/enums/facilitator_type.dart';
import '../../utils/enums/place_type.dart';
import '../../utils/enums/profile_type.dart';
import '../../utils/enums/usage_reason.dart';
import '../../utils/enums/user_role.dart';
import 'chamber_firestore.dart';
import 'constants/app_firestore_collection_constants.dart';
import 'constants/app_firestore_constants.dart';
import 'facility_firestore.dart';
import 'place_firestore.dart';
import 'post_firestore.dart';
import 'profile_firestore.dart';

class UserFirestore implements UserRepository {
  
  final userReference = FirebaseFirestore.instance.collection(AppFirestoreCollectionConstants.users);
  final profileReference = FirebaseFirestore.instance.collectionGroup(AppFirestoreCollectionConstants.profiles);

  @override
  Future<bool> insert(AppUser user) async {
    String userId = user.id.toLowerCase();
    AppUtilities.logger.i("Inserting user $userId to Firestore");

    Map<String,dynamic> userJSON = user.toJSON();
    AppUtilities.logger.d(userJSON.toString());

    try {

      await userReference.doc(userId).set(userJSON)
          .whenComplete(() => AppUtilities.logger.i('User added to the database'))
          .catchError((e) => AppUtilities.logger.e(e));

      AppUtilities.logger.d("User ${user.toString()} inserted successfully.");
      return true;

    } catch (e) {
      await remove(userId) ? AppUtilities.logger.i("User rollback") : AppUtilities.logger.e(e.toString());
      return false;
    }
  }

  @override
  Future<List<AppUser>> getAll() async {
    AppUtilities.logger.d("Get all Users");

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
      AppUtilities.logger.e(e.toString());
    }

    return users;
  }

  @override
  Future<AppUser> getById(String userId, {getProfileFeatures = false}) async {
    AppUtilities.logger.t("Get User by ID: $userId");
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
               user.profiles = [profile];
             } else {
               AppUtilities.logger.d("Profile for userId $userId not found");
             }
          } else {
             user.profiles = await ProfileFirestore().retrieveByUserId(userId);

          }

          if(getProfileFeatures) {
            if(user.profiles.isNotEmpty && user.profiles.first.id.isNotEmpty) {
              user.profiles.first = await ProfileFirestore().getProfileFeatures(user.profiles.first);
            }
          }
        } else {
          AppUtilities.logger.w("No user found");
        }
    } catch (e) {
      AppUtilities.logger.e(e.toString());
    }

    return user;
  }

  @override
  Future<AppUser?> getByEmail(String email,  {bool getProfile = false, bool getProfileFeatures = false}) async {
    AppUtilities.logger.d("Get User by Email: $email");

    try {
      QuerySnapshot querySnapshot = await userReference.where(AppFirestoreConstants.email, isEqualTo: email).limit(1).get();

      if (querySnapshot.docs.isNotEmpty) {
        var queryDocumentSnapshot = querySnapshot.docs.first;
        if (queryDocumentSnapshot.exists) {
          AppUser user = AppUser.fromJSON(queryDocumentSnapshot.data());
          user.id = queryDocumentSnapshot.id;

          if(getProfile) {
            AppProfile profile = AppProfile();

            if(user.currentProfileId.isNotEmpty) {
              profile = await ProfileFirestore().retrieve(user.currentProfileId);
              if(profile.id.isNotEmpty) {
                if(AppFlavour.appInUse == AppInUse.c) {
                  profile.chambers = await ChamberFirestore().fetchAll(ownerId: profile.id);
                  profile.chamberPresets?.clear();

                  CoreUtilities.getTotalPresets(profile.chambers!).forEach((key, value) {
                    profile.chamberPresets!.add(key);
                  });
                }
                user.profiles = [profile];
              } else {
                AppUtilities.logger.d("Profile for userId ${user.id} not found");
              }
            } else {
              user.profiles = await ProfileFirestore().retrieveByUserId(user.id);
            }

            if(getProfileFeatures) {
              if(user.profiles.isNotEmpty && user.profiles.first.id.isNotEmpty) {
                user.profiles.first = await ProfileFirestore().getProfileFeatures(user.profiles.first);
              }
            }
          }

          return user;
        } else {
          AppUtilities.logger.w("No user found");
        }
      }
    } catch (e) {
      AppUtilities.logger.e(e.toString());
    }

    return null;
  }

  @override
  Future<AppUser> getByProfileId(String profileId) async {
    AppUtilities.logger.d("Getting user for ProfileId: $profileId");
    AppUser user = AppUser();
    String userId = "";
    QuerySnapshot userQuerySnapshot;

    try {
      QuerySnapshot querySnapshot = await profileReference.get();

      for (var profile in querySnapshot.docs) {
        if(profile.id == profileId) {
          AppUtilities.logger.w("Reference id: ${profile.reference.parent.parent!.id}");
          DocumentReference documentReference = profile.reference;
          userId = documentReference.parent.parent!.id;

          userQuerySnapshot = await userReference
              .where(FieldPath.documentId, isEqualTo: userId)
              .get();
          AppUtilities.logger.i("${userQuerySnapshot.docs.length} users found");

          user = AppUser.fromJSON(userQuerySnapshot.docs.first.data());
          user.id = userId;
        }
      }
    } catch (e) {
      AppUtilities.logger.e(e.toString());
    }

    return user;
  }


  @override
  Future<bool> remove(String userId) async {
    AppUtilities.logger.d("Removing User $userId from Firestore");

    try {
      await userReference.doc(userId).delete();
      AppUtilities.logger.d("User $userId removed successfully.");
    } catch (e) {
      AppUtilities.logger.e(e);
      return false;
    }

    return true;
  }


  @override
  Future<bool> updateAndroidNotificationToken(String userId, String token) async {
    AppUtilities.logger.d("Updating Android Notification Token for User $userId");

    try {
      await userReference.doc(userId).update({AppFirestoreConstants.androidNotificationToken: token});
      AppUtilities.logger.d("User $userId removed successfully.");
      return true;
    } catch (e) {
      AppUtilities.logger.e(e);
      return false;
    }
  }


  @override
  Future<bool> isAvailableEmail(String email) async {
    AppUtilities.logger.t("Verify if email $email is already in use");

    try {
      QuerySnapshot querySnapshot = await userReference
          .where(AppFirestoreConstants.email, isEqualTo: email)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        AppUtilities.logger.i("Email already in use");
        return false;
      }

      AppUtilities.logger.t("Email is available");
      return true;

    } catch (e) {
      AppUtilities.logger.e(e.toString());
      rethrow;
    }
  }


  @override
  Future<bool> isAvailablePhone(String phoneNumber) async {

    AppUtilities.logger.d("Verify if phoneNumber $phoneNumber is available");

    try {
      QuerySnapshot querySnapshot = await userReference.where(
          AppFirestoreConstants.phoneNumber,
          isEqualTo: phoneNumber).get();

      if (querySnapshot.docs.isNotEmpty) {
        AppUtilities.logger.i("Phone number already in use");
        return false;
      }

      AppUtilities.logger.d("No phoneNumber found");
      return true;

    } catch (e) {
      AppUtilities.logger.e(e.toString());
      rethrow;
    }
  }


  // @override
  // Future<bool> addToWallet(String userId, double amount, {AppCurrency appCurrency = AppCurrency.appCoin}) async {
  //   AppUtilities.logger.d("Entering addToWalletMethod");
  //
  //   AppUser user = AppUser();
  //   try {
  //     DocumentSnapshot documentSnapshot = await userReference.doc(userId).get();
  //     if (documentSnapshot.exists) {
  //       user = AppUser.fromJSON(documentSnapshot.data());
  //       user.wallet.amount = user.wallet.amount + amount;
  //
  //       await documentSnapshot.reference.update({
  //         AppFirestoreConstants.wallet: user.wallet.toJSON()
  //       });
  //
  //       AppUtilities.logger.d("User Wallet updated");
  //       return true;
  //     } else {
  //       AppUtilities.logger.i("No user found");
  //     }
  //   } catch (e) {
  //     AppUtilities.logger.e(e.toString());
  //   }
  //
  //   return false;
  // }


  // Future<bool> subtractFromWallet(String userId, double amount, {AppCurrency appCurrency = AppCurrency.appCoin}) async {
  //   AppUtilities.logger.d("Subtraction $amount Aopcoins from UserId $userId");
  //   AppUser user = AppUser();
  //   try {
  //     DocumentSnapshot documentSnapshot = await userReference.doc(userId).get();
  //     if (documentSnapshot.exists) {
  //       user = AppUser.fromJSON(documentSnapshot.data());
  //       user.wallet.amount = user.wallet.amount - amount;
  //
  //       await documentSnapshot.reference.update({
  //         AppFirestoreConstants.wallet: user.wallet.toJSON()
  //       });
  //
  //       AppUtilities.logger.i("User Wallet updated for user $userId");
  //       return true;
  //     } else {
  //       AppUtilities.logger.i("No user found");
  //     }
  //   } catch (e) {
  //     AppUtilities.logger.e(e.toString());
  //   }
  //
  //   return false;
  // }


  @override
  Future<bool> updatePhotoUrl(String userId, String photoUrl) async {
    AppUtilities.logger.t("updatePhotoUrl");

    try {
      DocumentSnapshot documentSnapshot = await userReference.doc(userId).get();
      await documentSnapshot.reference.update({AppFirestoreConstants.photoUrl: photoUrl});

    } catch (e) {
      AppUtilities.logger.e(e.toString());
      return false;
    }

    return true;
  }



  @override
  Future<bool> addOrderId({required String userId, required String orderId}) async {
    AppUtilities.logger.d("Order $orderId would be added to User $userId");

    try {
      DocumentSnapshot documentSnapshot = await userReference
          .doc(userId).get();

      await documentSnapshot.reference.update({
        AppFirestoreConstants.orderIds: FieldValue.arrayUnion([orderId])
      });
      AppUtilities.logger.d("Order $orderId is now at User $userId");
      return true;
    } catch (e) {
      AppUtilities.logger.e(e.toString());
    }

    return false;
  }


  @override
  Future<bool> removeOrderId({required String userId, required String orderId}) async {
    AppUtilities.logger.d("Order $orderId would be removed from User $userId");

    try {
      DocumentSnapshot documentSnapshot = await userReference
          .doc(userId).get();

      await documentSnapshot.reference.update({
        AppFirestoreConstants.orderIds: FieldValue.arrayRemove([orderId])
      });
      AppUtilities.logger.d("Order $orderId was removed from User $userId");
      return true;
    } catch (e) {
      AppUtilities.logger.e(e.toString());
    }

    return false;
  }


  @override
  Future<bool> updateFcmToken(String userId, String fcmToken) async {
    AppUtilities.logger.d("updating Firebase Cloud Messaging Token for User $userId");

    try {
      DocumentSnapshot documentSnapshot = await userReference.doc(userId).get();
      await documentSnapshot.reference.update({AppFirestoreConstants.fcmToken: fcmToken});
      AppUtilities.logger.i("FCM Token successfully updated for User $userId");
      return true;
    } catch (e) {
      AppUtilities.logger.e(e.toString());
    }

    return false;
  }

  @override
  Future<void> updateLastTimeOn(String userId) async {
    AppUtilities.logger.t("updating LastTimeOn for user $userId");

    try {
      DocumentSnapshot documentSnapshot = await userReference.doc(userId).get();
      await documentSnapshot.reference.update({AppFirestoreConstants.lastTimeOn: DateTime.now().millisecondsSinceEpoch});
      AppUtilities.logger.t("LastTimeOn successfully updated for User $userId");
    } catch (e) {
      AppUtilities.logger.e(e.toString());
    }

  }

  @override
  Future<String> retrieveFcmToken(String userId) async {
    AppUtilities.logger.d("Retrieving Firebase Cloud Messaging Token for User $userId device");

    String fcmToken = "";
    try {
      DocumentSnapshot documentSnapshot = await userReference.doc(userId).get();
      fcmToken = AppUser.fromJSON(documentSnapshot.data()).fcmToken;
      AppUtilities.logger.i("FCM Token $fcmToken retrieved");
    } catch (e) {
      AppUtilities.logger.e(e.toString());
    }

    return fcmToken;
  }

  @override
  Future<bool> updateSpotifyToken(String userId, String spotifyToken) async {
    AppUtilities.logger.d("updating Spotify Access Token for User $userId");

    try {
      DocumentSnapshot documentSnapshot = await userReference.doc(userId).get();
      await documentSnapshot.reference.update({AppFirestoreConstants.spotifyToken: spotifyToken});
      AppUtilities.logger.i("Spotify Token successfully updated for User $userId");
      return true;
    } catch (e) {
      AppUtilities.logger.e(e.toString());
    }

    return false;
  }

  Future<AppProfile> updateCurrentProfile(String userId, String currentProfileId) async {
    AppUtilities.logger.d("Updating current profile $userId");
    AppProfile profile = AppProfile();
    try {
      DocumentSnapshot documentSnapshot = await userReference.doc(userId).get();
      await documentSnapshot.reference.update({AppFirestoreConstants.currentProfileId: currentProfileId});
      AppUtilities.logger.i("CurrentProfileId successfully updated for User $userId");
      profile = await ProfileFirestore().retrieveFull(currentProfileId);
    } catch (e) {
      AppUtilities.logger.e(e.toString());
    }

    return profile;
  }

  @override
  Future<List<AppUser>> getWithParameters({
    bool needsPhone  = false, bool includeProfile = false, bool needsPosts = false,
    List<ProfileType>? profileTypes, FacilityType? facilityType, PlaceType? placeType,
    List<UsageReason>? usageReasons, Position? currentPosition, int maxDistance = 30,}) async {

    AppUtilities.logger.d("Get all Users by parameters");

    List<AppUser> users = [];
    AppProfile profile = AppProfile();
    Map<String,AppProfile> facilityProfiles = <String, AppProfile>{};
    Map<String,AppProfile> placeProfiles = <String, AppProfile>{};
    Map<String,AppProfile> noMainFacilityProfiles = <String, AppProfile>{};
    Map<String,AppProfile> noMainPlaceProfiles = <String, AppProfile>{};

    try {
      QuerySnapshot userQuerySnapshot = !needsPhone ? await userReference.get()
          : await userReference.where(AppFirestoreConstants.phoneNumber, isNotEqualTo: '').get();


      QuerySnapshot? profileQuerySnapshot;
      List<Post> totalPosts = [];

      if(includeProfile) {
        profileQuerySnapshot = await profileReference.get();
        totalPosts = await PostFirestore().retrievePosts();
      }

      for (var queryDocumentSnapshot in userQuerySnapshot.docs) {
        if (queryDocumentSnapshot.exists) {
          AppUser user = AppUser.fromJSON(queryDocumentSnapshot.data());
          user.id = queryDocumentSnapshot.id;

          if(includeProfile && profileQuerySnapshot != null) {
            for (var document in profileQuerySnapshot.docs) {
              if(document.reference.parent.parent!.id == user.id) {
                profile = AppProfile.fromJSON(document.data());
                profile.id = document.id;

                if(profileTypes != null && !profileTypes.contains(profile.type)) {
                  AppUtilities.logger.t("Profile ${profile.id} ${profile.name} - ${profile.type.name} is not profile type ${profileTypes.toString()} required");
                  continue;
                }

                if(usageReasons != null && (!usageReasons.contains(profile.usageReason) && profile.usageReason != UsageReason.any)) {
                  AppUtilities.logger.t("Profile ${profile.id} ${profile.name} - ${profile.usageReason.name} has not the usage reason ${usageReasons.toString()} required");
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
                  List<Post> profilePosts = totalPosts.where((element) => element.ownerId == profile.id).toList();
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
                  if(profile.address.isNotEmpty) await ProfileFirestore().updateAddress(profile.id, profile.address);
                }

                if(profile.phoneNumber.isEmpty) {
                  profile.phoneNumber = user.countryCode + user.phoneNumber;
                  await ProfileFirestore().updatePhoneNumber(profile.id, profile.phoneNumber);
                }

                user.profiles.add(profile);
              }
            }

            if(user.profiles.isEmpty) continue;
          }

          users.add(user);
        }
      }
    } catch (e) {
      AppUtilities.logger.e(e.toString());
    }

    return users;
  }

  @override
  Future<List<String>> getFCMTokens() async {
    AppUtilities.logger.t("Get available FCM Tokens from all Users on Firestore");

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
      AppUtilities.logger.e(e.toString());
    }

    AppUtilities.logger.d("${fcmTokens.length} FCM Tokens retrieved for user");
    return fcmTokens;
  }

  @override
  Future<bool> addReleaseItem({required String userId, required String releaseItemId}) async {
    AppUtilities.logger.t("ReleaseItem $releaseItemId would be added to User $userId");

    try {
      DocumentSnapshot documentSnapshot = await userReference
          .doc(userId).get();

      await documentSnapshot.reference.update({
        AppFirestoreConstants.releaseItemIds: FieldValue.arrayUnion([releaseItemId])
      });
      AppUtilities.logger.d("ReleaseItem $releaseItemId is now at User $userId");
      return true;
    } catch (e) {
      AppUtilities.logger.e(e.toString());
    }

    return false;
  }

  @override
  Future<bool> updateUserRole(String userId, UserRole userRole) async {
    AppUtilities.logger.d("Updating UserRole to ${userRole.name} for User $userId");

    try {
      await userReference.doc(userId).update({AppFirestoreConstants.userRole: userRole.name});
      AppUtilities.logger.d("UserRole for $userId updated successfully.");
      return true;
    } catch (e) {
      AppUtilities.logger.e(e);
      return false;
    }
  }

  @override
  Future<bool> addBoughtItem({required String userId, required String itemId}) async {
    AppUtilities.logger.d("$userId would add $itemId");

    try {
      await userReference.doc(userId).update({
        AppFirestoreConstants.boughtItems: FieldValue.arrayUnion([itemId])
      });
      AppUtilities.logger.d("$userId has added boughtItem $itemId");
      return true;
    } catch (e) {
      AppUtilities.logger.e(e.toString());
    }
    return false;
  }


  @override
  Future<bool> removeBoughtItem(String userId, String itemId) async {
    AppUtilities.logger.d("$userId would remove $itemId");

    try {
      await userReference.doc(userId).update({
        AppFirestoreConstants.boughtItems: FieldValue.arrayRemove([itemId])
      });
      AppUtilities.logger.d("$userId has removed boughtItem $itemId");
      return true;
    } catch (e) {
      AppUtilities.logger.e(e.toString());
    }
    return false;
  }

  @override
  Future<void> updateCustomerId(String userId, String customerId) async {
    AppUtilities.logger.d("Updating subscriptionId for User $userId");

    try {
      if(customerId.isEmpty) {
        AppUtilities.logger.e('customerId is empty');
        return;
      }

      await userReference.doc(userId).update({
        AppFirestoreConstants.customerId: customerId,
      });
      AppUtilities.logger.d("User $userId customerId value successfully updated to: $customerId");
    } catch (e) {
      AppUtilities.logger.e(e);
    }
  }

  @override
  Future<void> updateSubscriptionId(String userId, String subscriptionId) async {
    AppUtilities.logger.d("Updating subscriptionId for User $subscriptionId");

    try {
      await userReference.doc(userId).update({
        AppFirestoreConstants.subscriptionId: subscriptionId,
      });
      AppUtilities.logger.d("User $userId subscriptionId value successfully updated to: $subscriptionId");
    } catch (e) {
      AppUtilities.logger.e(e);
    }
  }

  @override
  Future<void> updatePhoneNumber(String userId, String phoneNumber) async {
    AppUtilities.logger.d("Updating phoneNumber for User $phoneNumber");

    try {
      await userReference.doc(userId).update({
        AppFirestoreConstants.phoneNumber: phoneNumber,
      });
      AppUtilities.logger.d("User $userId phoneNumber value successfully updated to: $phoneNumber");
    } catch (e) {
      AppUtilities.logger.e(e);
    }
  }

  @override
  Future<void> updateCountryCode(String userId, String countryCode) async {
    AppUtilities.logger.d("Updating countryCode for User $countryCode");

    try {
      await userReference.doc(userId).update({
        AppFirestoreConstants.countryCode: countryCode,
      });
      AppUtilities.logger.d("User $userId countryCode value successfully updated to: $countryCode");
    } catch (e) {
      AppUtilities.logger.e(e);
    }
  }

  @override
  Future<void> setIsVerified(String userId, bool isVerified) async {
    AppUtilities.logger.d("Updating isVerified as $isVerified for User $userId");

    try {
      await userReference.doc(userId).update({
        AppFirestoreConstants.isVerified: isVerified,
      });
      AppUtilities.logger.d("User $userId isVerified value successfully updated to: $isVerified");
    } catch (e) {
      AppUtilities.logger.e(e);
    }
  }

}
