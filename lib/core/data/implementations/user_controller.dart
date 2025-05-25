
import 'package:firebase_auth/firebase_auth.dart' as fba;
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:get/get.dart';

import '../../../auth/ui/login/login_controller.dart';
import '../../domain/model/app_profile.dart';
import '../../domain/model/app_user.dart';
import '../../domain/model/band.dart';
import '../../domain/model/item_list.dart';
import '../../domain/model/user_subscription.dart';
import '../../domain/use_cases/user_service.dart';
import '../../utils/app_utilities.dart';
import '../../utils/constants/app_page_id_constants.dart';
import '../../utils/constants/app_route_constants.dart';
import '../../utils/constants/app_translation_constants.dart';
import '../../utils/constants/message_translation_constants.dart';
import '../../utils/core_utilities.dart';
import '../../utils/enums/itemlist_type.dart';
import '../../utils/enums/owner_type.dart';
import '../../utils/enums/subscription_level.dart';
import '../../utils/enums/subscription_status.dart';
import '../../utils/enums/user_role.dart';
import '../firestore/app_release_item_firestore.dart';
import '../firestore/chamber_firestore.dart';
import '../firestore/constants/app_firestore_constants.dart';
import '../firestore/itemlist_firestore.dart';
import '../firestore/profile_firestore.dart';
import '../firestore/user_firestore.dart';
import '../firestore/user_subscription_firestore.dart';
import 'app_hive_controller.dart';

class UserController extends GetxController implements UserService {

  UserFirestore userFirestore = UserFirestore();
  
  AppUser user = AppUser();
  AppProfile profile = AppProfile();
  AppProfile newProfile = AppProfile();
  Band band = Band();

  bool isNewUser = false;

  OwnerType itemlistOwner  = OwnerType.profile;

  String fcmToken = "";

  UserSubscription? userSubscription;
  SubscriptionLevel subscriptionLevel = SubscriptionLevel.freemium;


  //Move to other global Controller to get ReleaseItemList on AudioPlayerHome
  ItemlistType defaultItemlistType  = ItemlistType.playlist;
  Map<String, Itemlist> releaseItemlists = {};

  @override
  void onInit() {
    super.onInit();
    AppUtilities.logger.t("onInit User Controller");
    AppHiveController().fetchProfileInfo();
  }

  @override
  void onReady() {
    super.onReady();

    AppUtilities.logger.t("onReady User Controller");
    try {
      getFcmToken();
    } catch (e) {
      AppUtilities.logger.e(e.toString());
    }

  }

  Future<void> getFcmToken() async {
    fcmToken = await FirebaseMessaging.instance.getToken() ?? "";

    if(fcmToken.isNotEmpty) {
      await FirebaseMessaging.instance.subscribeToTopic(AppFirestoreConstants.allUsers);
      AppUtilities.logger.i("User ${user.id} subscribed to topic ${AppFirestoreConstants.allUsers}.");
    } else {
      AppUtilities.logger.w("FCM Token is empty");
    }

  }

  @override
  Future<void> removeAccount() async {
    AppUtilities.logger.d("removeAccount method Started");
    try {

      if(user.id.isNotEmpty && user.profiles.isNotEmpty) {
        for (var prof in user.profiles) {
          await ProfileFirestore().remove(userId: user.id, profileId: prof.id);
        }
        await userFirestore.remove(user.id);
      }

      LoginController loginController = Get.find<LoginController>();
      fba.AuthCredential? authCredential;

      if(loginController.credentials == null) {
        authCredential = await loginController.getAuthCredentials();
      } else {
        authCredential = loginController.credentials;
      }

      if(authCredential != null) {
        await loginController.fbaUser.value?.reauthenticateWithCredential(authCredential);
        await loginController.fbaUser.value?.delete();
        await loginController.signOut();
        clear();
      } else {
        AppUtilities.logger.e("AuthCredentials to reauthenticate were null");
        Get.offAndToNamed(AppRouteConstants.login);
      }

    } catch (e) {
      Get.snackbar(
        MessageTranslationConstants.errorSigningOut.tr,
        e.toString(),
        snackPosition: SnackPosition.bottom,
      );
      Get.toNamed(AppRouteConstants.logout);
    }

    AppUtilities.logger.i("removeAccount method Finished");
    update();
  }


  // @override
  // Future<void> getUserFromFacebook(String fbAccessToken) async {
  //   AppUtilities.logger.i("User is new");
  //   try {
  //
  //     Uri fbURI = Uri.https(AppFacebookConstants.graphApiAuthorityUrl, AppFacebookConstants.graphApiUnencondedPath,
  //         {AppFacebookConstants.graphApiQueryFieldsParam: AppFacebookConstants.graphApiQueryFieldsValues,
  //           AppFacebookConstants.graphApiQueryAccessTokenParam: fbAccessToken});
  //
  //     var graphResponse = await http.get(fbURI);
  //
  //     if(graphResponse.statusCode == 200) {
  //       var jsonResponse = jsonDecode(graphResponse.body) as Map<String, dynamic>;
  //       AppUtilities.logger.i("Profile from Graph FB API ${jsonResponse.toString()}");
  //       user = AppUser.fromFbProfile(jsonResponse);
  //     } else {
  //       AppUtilities.logger.w("Request failed with status: ${graphResponse.statusCode}");
  //     }
  //   } catch (e) {
  //     Get.snackbar(
  //       MessageTranslationConstants.errorCreatingAccount.tr,
  //       e.toString(),
  //       snackPosition: SnackPosition.bottom,
  //     );
  //     AppUtilities.logger.e(e);
  //   }
  // }


  /// Create user profile from google login
  @override
  void getUserFromFirebase(fba.User fbaUser) {
    AppUtilities.logger.d("Getting User Info From Firebase Authentication");
    user =  AppUser(
      dateOfBirth: 0,
      homeTown: AppTranslationConstants.somewhereUniverse.tr,
      photoUrl: fbaUser.photoURL ?? "",
      name: fbaUser.displayName ?? "",
      firstName: "",
      lastName: "",
      email: fbaUser.email ?? "",
      id: fbaUser.providerData.first.uid ?? "",
      phoneNumber: fbaUser.phoneNumber ?? "",
      isVerified: false,
      password: "",
      );

    AppUtilities.logger.d('Last login at: ${fbaUser.metadata.lastSignInTime}');
    AppUtilities.logger.d(user.toString());
  }

  void clear() {
    user = AppUser();
  }


  @override
  Future<void> createUser() async {

    AppUtilities.logger.d("User to create ${user.name}");
    AppUser newUser = user;

    newProfile.photoUrl = newUser.photoUrl;
    newProfile.coverImgUrl = newUser.photoUrl;
    newProfile.mainFeature = CoreUtilities.getProfileMainFeature(newProfile);
    newProfile.isActive = true;
    newProfile.reviewStars = 0;
    newProfile.bannedGenres = [];
    newProfile.itemmates = [];
    newProfile.eventmates = [];
    newProfile.followers = [];
    newProfile.following = [];
    newProfile.unfollowing = [];
    newProfile.blockTo = [];
    newProfile.blockedBy = [];
    newProfile.posts = [];
    newProfile.hiddenPosts = [];
    newProfile.reports = [];
    newProfile.bands = [];
    newProfile.events = [];
    newProfile.reviews = [];
    newProfile.watchingEvents = [];
    newProfile.goingEvents = [];
    newProfile.playingEvents = [];
    newProfile.itemlists = {};
    newProfile.favoriteItems = [];

    newUser.profiles = [newProfile];
    newUser.userRole = UserRole.subscriber;

    try {

      if(newUser.name.isEmpty) newUser.name = newProfile.name;

      newUser.createdDate = DateTime.now().millisecondsSinceEpoch;

      if(await userFirestore.insert(newUser)) {
        isNewUser = false;
        user = newUser;

        String profileId = await ProfileFirestore().insert(user.id, user.profiles.first);

        if(profileId.isNotEmpty) {
          user.profiles.first.id = profileId;
          user.currentProfileId = profileId;
          userFirestore.updateCurrentProfile(user.id, profileId);
          profile = user.profiles.first;
          Get.offAllNamed(AppRouteConstants.home);
          profile.itemlists = await ItemlistFirestore().getByOwnerId(profile.id);
        } else {
          userFirestore.remove(newUser.id);
          AppUtilities.logger.e("Something wrong creating account.");
          Get.offAllNamed(AppRouteConstants.login);
        }
      } else {
        AppUtilities.logger.e("Something wrong creating account.");
        Get.offAllNamed(AppRouteConstants.login);
      }
    } catch (e) {
      Get.snackbar(
        MessageTranslationConstants.errorCreatingAccount.tr,
        e.toString(),
        snackPosition: SnackPosition.bottom,
      );
    }

    AppUtilities.logger.d("");
    AppHiveController().writeProfileInfo();
    update([AppPageIdConstants.login, AppPageIdConstants.home]);
  }

  @override
  Future<void> createProfile() async {

    AppUtilities.logger.d("Profile to create ${newProfile.name}");

    if(newProfile.photoUrl.isEmpty) {
      newProfile.photoUrl = user.photoUrl;
      newProfile.coverImgUrl = user.photoUrl;
    } else {
      newProfile.coverImgUrl = newProfile.photoUrl;
    }

    newProfile.mainFeature = CoreUtilities.getProfileMainFeature(newProfile);
    newProfile.isActive = true;
    newProfile.reviewStars = 0;
    newProfile.bannedGenres = [];
    newProfile.itemmates = [];
    newProfile.eventmates = [];
    newProfile.followers = [];
    newProfile.following = [];
    newProfile.unfollowing = [];
    newProfile.blockTo = [];
    newProfile.blockedBy = [];
    newProfile.posts = [];
    newProfile.hiddenPosts = [];
    newProfile.reports = [];
    newProfile.bands = [];
    newProfile.events = [];
    newProfile.reviews = [];

    newProfile.watchingEvents = [];
    newProfile.goingEvents = [];
    newProfile.playingEvents = [];
    newProfile.itemlists = {};
    newProfile.favoriteItems = [];

    try {

      String profileId = await ProfileFirestore().insert(user.id, newProfile);

      if(profileId.isNotEmpty) {
        newProfile.id = profileId;
        user.profiles.add(newProfile);
        profile = newProfile;

        if(profileId.isNotEmpty) {
          userFirestore.updateCurrentProfile(user.id, profileId);
          AppUtilities.logger.i("Additional profile created successfully.");
          Get.offAllNamed(AppRouteConstants.home);
        } else {
          AppUtilities.logger.e("Something wrong creating account.");
          Get.offAllNamed(AppRouteConstants.login);
        }
      }
    } catch (e) {
      Get.snackbar(
        MessageTranslationConstants.errorCreatingAccount.tr,
        e.toString(),
        snackPosition: SnackPosition.bottom,
      );
      AppUtilities.logger.e("Something wrong creating account.");
      Get.offAllNamed(AppRouteConstants.login);
      update();
    }

    AppUtilities.logger.d("");
    AppHiveController().writeProfileInfo();
    update([AppPageIdConstants.login, AppPageIdConstants.home]);
  }

  @override
  Future<void> getProfiles() async {
    AppUtilities.logger.d("User looked up by ${user.id}");

    try {
      user.profiles = await ProfileFirestore().retrieveByUserId(user.id);
    } catch (e) {
      Get.snackbar(
        MessageTranslationConstants.errorRetrievingProfiles.tr,
        e.toString(),
        snackPosition: SnackPosition.bottom,
      );
    }
    update([AppPageIdConstants.login]);
  }


  @override
  Future<void> getUserById(String userId) async {

    try {
      AppUser userFromFirestore = await userFirestore.getById(userId);
      if(userFromFirestore.id.isNotEmpty){
        AppUtilities.logger.i("User $userId exists!!");
        user = userFromFirestore;
        profile = user.profiles.first;
        isNewUser = false;
        // Future.microtask(() => getUserSubscription());
      } else {
        AppUtilities.logger.w("User $userId not exists!!");
        isNewUser = true;
      }
    } catch (e) {
      AppUtilities.logger.e(e.toString());
    }
  }

  @override
  Future<void> getUserByEmail(String userEmail) async {

    try {
      AppUser userFromEmail = await userFirestore.getByEmail(userEmail, getProfile: true) ?? AppUser();
      if(userFromEmail.id.isNotEmpty) {
        AppUtilities.logger.t("User $userEmail exists!!");
        user = userFromEmail;
        profile = user.profiles.first;
        isNewUser = false;
      } else {
        AppUtilities.logger.w("User $userEmail not exists!!");
        user = AppUser();
        profile = AppProfile();
        isNewUser = true;
      }
    } catch (e) {
      AppUtilities.logger.e(e.toString());
    }
  }

  // void addToWallet(amount) {
  //   user.wallet.amount = user.wallet.amount + amount;
  //   update([]);
  // }

  // void subtractFromWallet(double amount) {
  //   user.wallet.amount = user.wallet.amount - amount;
  //   update([]);
  // }

  Future<void> changeProfile(AppProfile selectedProfile) async {
    AppUtilities.logger.i("Changing profile to ${selectedProfile.id}");

    try {
      profile = selectedProfile;
      Get.toNamed(AppRouteConstants.splashScreen, arguments: [AppRouteConstants.refresh]);
      profile = await userFirestore.updateCurrentProfile(user.id, selectedProfile.id);
    } catch(e) {
      AppUtilities.logger.e(e.toString());
    }

    update();
  }

  @override
  Future<void> removeProfile() async {
    AppUtilities.logger.d("removeProfile method Started");
    try {

      if(await ProfileFirestore().remove(userId: user.id, profileId: profile.id)) {
        user.profiles.removeWhere((element) => element.id == profile.id);
        if(user.profiles.isNotEmpty) {
          profile = await userFirestore.updateCurrentProfile(user.id, user.profiles.first.id);
        }

      }

    } catch (e) {
      Get.snackbar(
        MessageTranslationConstants.errorSigningOut.tr,
        e.toString(),
        snackPosition: SnackPosition.bottom,
      );
      Get.toNamed(AppRouteConstants.logout);
    }

    AppUtilities.logger.i("removeProfile method Finished");
    update();
  }

  @override
  Future<void> reloadProfileItemlists() async {

    try {
      profile.itemlists = await ItemlistFirestore().getByOwnerId(profile.id);
      profile.favoriteItems?.clear();
      profile.chamberPresets?.clear();

      CoreUtilities.getTotalPresets(profile.chambers ?? {}).forEach((key, value) {
        profile.chamberPresets!.add(key);
      });

      CoreUtilities.getTotalMediaItems(profile.itemlists ?? {}).forEach((key, value) {
        profile.favoriteItems!.add(key);
      });

      CoreUtilities.getTotalReleaseItems(profile.itemlists ?? {}).forEach((key, value) {
        profile.favoriteItems!.add(key);
      });
    } catch (e) {
      AppUtilities.logger.e(e.toString());
    }

    update([]);
  }

  @override
  Future<void> loadProfileChambers() async {

    try {
      profile.chambers = await ChamberFirestore().fetchAll(ownerId: profile.id);
      profile.chamberPresets?.clear();

      CoreUtilities.getTotalPresets(profile.chambers!).forEach((key, value) {
        profile.chamberPresets!.add(key);
      });

    } catch (e) {
      AppUtilities.logger.e(e.toString());
    }

    update();
  }

  @override
  void stopGoingToEvent(String eventId) {
    profile.goingEvents?.remove(eventId);
    try {
      //Get.find<EventDetailsController>().stopGoingToEvent();
    } catch (e) {
      AppUtilities.logger.e(e.toString());
    }
    update([AppPageIdConstants.timeline]);
  }

  @override
  void goingToEvent(String eventId) {
    profile.goingEvents?.add(eventId);
    try {
      //Get.find<EventDetailsController>().stopGoingToEvent();
    } catch (e) {
      AppUtilities.logger.e(e.toString());
    }
    update([AppPageIdConstants.timeline]);
  }

  @override
  Future<void> addOrderId(String orderId) async {
    AppUtilities.logger.d("addOrderId $orderId");
    try {
      if(await userFirestore.addOrderId(userId: user.id, orderId: orderId)) {
        user.orderIds.add(orderId);
      } else {
        AppUtilities.logger.w("Something occurred while adding order to User ${user.id}");
      }
    } catch (e) {
      AppUtilities.logger.e(e.toString());
    }
    update();
  }

  @override
  Future<void> addBoughtItem(String itemId) async {
    AppUtilities.logger.d("addBoughtItem $itemId");
    try {
      if(itemId.isNotEmpty) {
        if(await userFirestore.addBoughtItem(userId: user.id, itemId: itemId)) {
          user.boughtItems ??= [];
          user.boughtItems!.add(itemId);
        }

        AppReleaseItemFirestore().addBoughtUser(releaseItemId: itemId, userId: user.id);
      }
    } catch (e) {
      AppUtilities.logger.e(e.toString());
    }
    update();
  }

  @override
  Future<void> updateCustomerId(String customerId) async {
    AppUtilities.logger.d("updateCustomerId $customerId");

    try {
      user.customerId = customerId;
      userFirestore.updateCustomerId(user.id, customerId);
    } catch (e) {
      AppUtilities.logger.e(e.toString());
    }

    update();
  }

  @override
  Future<void> updateSubscriptionId(String subscriptionId) async {
    AppUtilities.logger.d("updateSubscriptionId $subscriptionId");

    try {
      user.subscriptionId = subscriptionId;
      userFirestore.updateSubscriptionId(user.id, subscriptionId);
    } catch (e) {
      AppUtilities.logger.e(e.toString());
    }

    update();
  }

  @override
  Future<bool> updatePhoneNumber(String phone, String countryCode) async {
    AppUtilities.logger.d("updatePhoneNumber Phone: $phone & countryCode $countryCode");
    bool wasUpdated = false;
    try {
      if(user.phoneNumber != phone) {
        if(await userFirestore.isAvailablePhone(phone)) {
          user.phoneNumber = phone;
          userFirestore.updatePhoneNumber(user.id, phone);
          wasUpdated = true;
        } else {
          AppUtilities.logger.e("Phone number is not available");
          Get.snackbar(AppTranslationConstants.updatePhone.tr,
            MessageTranslationConstants.phoneNotAvailable.tr,
            snackPosition: SnackPosition.bottom,
          );
        }
      } else {
        AppUtilities.logger.d("Same Phone number");
      }

      if(user.countryCode != countryCode) {
        user.countryCode = countryCode;
        userFirestore.updateCountryCode(user.id, countryCode);
        wasUpdated = true;
      } else {
        AppUtilities.logger.d("Same Country Code");
      }
    } catch (e) {
      AppUtilities.logger.e(e.toString());
    }

    update();

    return wasUpdated;
  }

  @override
  Future<void> getUserSubscription() async {
    AppUtilities.logger.d('getUserSubscription');

    try {
      List<UserSubscription> subscriptions = await UserSubscriptionFirestore().getByUserId(user.id);

      if(subscriptions.isNotEmpty) {
        userSubscription = subscriptions.firstWhereOrNull((subscription) => subscription.status == SubscriptionStatus.active);
        if(userSubscription?.subscriptionId == user.subscriptionId) {
          subscriptionLevel = userSubscription?.level ?? SubscriptionLevel.freemium;
          AppUtilities.logger.d('User subscriptionId is the same as user.subscriptionId for ${subscriptionLevel.name}');
        } else if(userSubscription?.subscriptionId.isNotEmpty ?? false) {
          user.subscriptionId = userSubscription?.subscriptionId ?? '';
          AppUtilities.logger.d('User subscription is different from user.subscriptionId');
        }
      } else if(user.subscriptionId.isNotEmpty) {
        if (AppUtilities.isWithinFirstMonth(user.createdDate)) {
          subscriptionLevel = SubscriptionLevel.freeMonth;
          AppUtilities.logger.i('User subscriptionId ${user.subscriptionId} is still within free month for SubscriptionLevel ${subscriptionLevel.name}');
        } else {
          AppUtilities.logger.w('User subscriptionId ${user.subscriptionId} is out of free month');
          user.subscriptionId = "";
        }
      } else if(user.userRole.value > UserRole.subscriber.value){
        AppUtilities.logger.d('No user subscription found');
        subscriptionLevel = SubscriptionLevel.ambassador;
      }
    } catch (e) {
      AppUtilities.logger.e(e.toString());
    }

  }

  @override
  Future<void> setUserSubscription(UserSubscription subscription) async {
    AppUtilities.logger.d('Setting userSubscription with subscriptionId: ${subscription.subscriptionId}');

    try {
      userSubscription = subscription;
    } catch (e) {
      AppUtilities.logger.e(e.toString());
    }

    // update();
  }

  @override
  Future<void> setIsVerified(bool isVerified) async {
    AppUtilities.logger.d('Setting isVerified value $isVerified for: ${user.id}');

    try {
      await userFirestore.setIsVerified(user.id, isVerified);
      user.isVerified = isVerified;
    } catch (e) {
      AppUtilities.logger.e(e.toString());
    }

    // update();
  }

}
