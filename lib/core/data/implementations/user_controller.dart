import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart' as fba;
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

import '../../../auth/ui/login/login_controller.dart';
import '../../app_flavour.dart';
import '../../domain/model/app_coupon.dart';
import '../../domain/model/app_profile.dart';
import '../../domain/model/app_user.dart';
import '../../domain/model/band.dart';
import '../../domain/model/item_list.dart';
import '../../domain/model/neom/chamber_preset.dart';
import '../../domain/use_cases/user_service.dart';
import '../../utils/app_utilities.dart';
import '../../utils/constants/app_constants.dart';
import '../../utils/constants/app_facebook_constants.dart';
import '../../utils/constants/app_page_id_constants.dart';
import '../../utils/constants/app_route_constants.dart';
import '../../utils/constants/app_translation_constants.dart';
import '../../utils/constants/message_translation_constants.dart';
import '../../utils/core_utilities.dart';
import '../../utils/enums/app_in_use.dart';
import '../../utils/enums/itemlist_owner.dart';
import '../../utils/enums/profile_type.dart';
import '../../utils/enums/user_role.dart';
import '../firestore/coupon_firestore.dart';
import '../firestore/itemlist_firestore.dart';
import '../firestore/profile_firestore.dart';
import '../firestore/user_firestore.dart';
import 'shared_preference_controller.dart';


class UserController extends GetxController implements UserService {

  final logger = AppUtilities.logger;

  final Rxn<AppUser> _user = Rxn<AppUser>();
  AppUser? get user => _user.value;
  set user(AppUser? user) => _user.value = user;

  bool isNewUser = false;

  final Rxn<AppProfile> _profile = Rxn<AppProfile>();
  AppProfile get profile => _profile.value ?? AppProfile();
  set profile(AppProfile? profile) => _profile.value = profile;

  final Rxn<AppProfile> _newProfile = Rxn<AppProfile>();
  AppProfile get newProfile => _newProfile.value ?? AppProfile();
  set newProfile(AppProfile? newProfile) => _newProfile.value = newProfile;

  final Rxn<Band> _band = Rxn<Band>();
  Band get band => _band.value ?? Band();
  set band(Band? band) => _band.value = band;

  ItemlistOwner itemlistOwner  = ItemlistOwner.profile;

  bool appliedCoupon= false;
  AppCoupon coupon = AppCoupon();

  String fcmToken = "";

  @override
  void onInit() async {

    super.onInit();
    user = AppUser();
    profile = AppProfile();
    newProfile = AppProfile();
    band = Band();

  }

  @override
  void onReady() async {
    try {
      fcmToken = await FirebaseMessaging.instance.getToken() ?? "";
    } catch (e) {
      logger.e(e.toString());
    }

    update([AppPageIdConstants.coupon]);
  }


  @override
  Future<void> removeAccount() async {
    logger.d("removeAccount method Started");
    try {

      LoginController loginController = Get.find<LoginController>();
      fba.AuthCredential? authCredential;
      if(loginController.credentials == null) {
        authCredential = await loginController.getAuthCredentials();
      } else {
        authCredential = loginController.credentials;
      }

      if(authCredential != null) {
        for (var prof in user!.profiles) {
          await ProfileFirestore().remove(userId: user!.id, profileId: prof.id);
        }

        if(await UserFirestore().remove(user!.id)) {
          await loginController.fbaUser.reauthenticateWithCredential(authCredential);
          await loginController.fbaUser.delete();
          await loginController.signOut();
          clear();
        }
      } else {
        logger.e("AuthCredentials to reauthenticate were null");
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

    logger.i("removeAccount method Finished");
    update();
  }


  @override
  Future<void> getUserFromFacebook(String fbAccessToken) async {
    logger.i("User is new");
    try {

      Uri fbURI = Uri.https(AppFacebookConstants.graphApiAuthorityUrl, AppFacebookConstants.graphApiUnencondedPath,
          {AppFacebookConstants.graphApiQueryFieldsParam: AppFacebookConstants.graphApiQueryFieldsValues,
            AppFacebookConstants.graphApiQueryAccessTokenParam: fbAccessToken});

      var graphResponse = await http.get(fbURI);

      if(graphResponse.statusCode == 200) {
        var jsonResponse = jsonDecode(graphResponse.body) as Map<String, dynamic>;
        logger.i("Profile from Graph FB API ${jsonResponse.toString()}");
        user = AppUser.fromFbProfile(jsonResponse);
      } else {
        logger.w("Request failed with status: ${graphResponse.statusCode}");
      }
    } catch (e) {
      Get.snackbar(
        MessageTranslationConstants.errorCreatingAccount.tr,
        e.toString(),
        snackPosition: SnackPosition.bottom,
      );
      logger.e(e);
    }
  }


  /// Create user profile from google login
  @override
  void getUserFromFirebase(fba.User fbaUser) {
    logger.d("Getting User Info From Firebase Authentication");
    user =  AppUser(
      dateOfBirth: DateTime(1950, DateTime.now().month, DateTime.now().day + 3)
          .toString(),
      homeTown: AppTranslationConstants.somewhereUniverse.tr,
      photoUrl: fbaUser.photoURL ?? "",
      name: fbaUser.displayName ?? "",
      firstName: "",
      lastName: "",
      email: fbaUser.email ?? "",
      id: fbaUser.providerData.first.uid ?? "",
      phoneNumber: fbaUser.phoneNumber ?? "",
      isPremium: false,
      isVerified: false,
      password: "",
      );

    logger.d('Last login at: ${fbaUser.metadata.lastSignInTime}');
    logger.d(user.toString());
  }

  void clear() {
    user = AppUser();
  }


  @override
  Future<void> createUser() async {

    logger.d("User to create ${user!.name}");
    AppUser newUser = user!;

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

    (newProfile.type == ProfileType.instrumentist) ?
    newProfile.itemlists![AppConstants.firstItemlist] = Itemlist.myFirstItemlist()
    : newProfile.itemlists![AppConstants.firstItemlist] = Itemlist.myFirstItemlistFan();

    if(AppFlavour.appInUse == AppInUse.cyberneom) {
      newProfile.itemlists![AppConstants.firstItemlist]!.chamberPresets = [];
      newProfile.itemlists![AppConstants.firstItemlist]!.chamberPresets!.add(ChamberPreset.myFirstNeomChamberPreset());
      newProfile.chamberPresets = [AppConstants.firstChamberPreset];
    } else {
      newProfile.appItems = [AppFlavour.getFirstAppItemId()];
    }
    newUser.profiles = [newProfile];
    newUser.userRole = UserRole.subscriber;

    if(Get.find<LoginController>().appInfo.coinPromo) {
      logger.i("GIVING COINS AS PART OF BETA LAUNCH");
      newUser.wallet.amount = newUser.wallet.amount + Get.find<LoginController>().appInfo.coinAmount;
    }

    await Future.delayed(const Duration(seconds: 1));

    try {

      if(newUser.name.isEmpty) {
        newUser.name = newProfile.name;
      }

      if(await UserFirestore().insert(newUser)){
        isNewUser = false;
        user = newUser;

        String profileId = await ProfileFirestore().insert(user!.id, user!.profiles.first);

        if(profileId.isNotEmpty) {
          user!.profiles.first.id = profileId;
          user!.currentProfileId = profileId;
          UserFirestore().updateCurrentProfile(user!.id, profileId);
          profile = user!.profiles.first;
          profile.itemlists = await ItemlistFirestore().retrieveItemlists(profile.id);
          if(appliedCoupon) await CouponFirestore().incrementUsageCount(coupon.id);
          Get.offAllNamed(AppRouteConstants.home);
        } else {
          await UserFirestore().remove(newUser.id);
          logger.e("Something wrong creating account.");
          Get.offAllNamed(AppRouteConstants.login);
        }
      } else {
        logger.e("Something wrong creating account.");
        Get.offAllNamed(AppRouteConstants.login);
      }
    } catch (e) {
      Get.snackbar(
        MessageTranslationConstants.errorCreatingAccount.tr,
        e.toString(),
        snackPosition: SnackPosition.bottom,
      );
    }

    logger.d("");
    Get.find<SharedPreferenceController>().writeLocal();
    update([AppPageIdConstants.login, AppPageIdConstants.home]);
  }

  @override
  Future<void> createProfile() async {

    logger.d("Profile to create ${newProfile.name}");

    if(newProfile.photoUrl.isEmpty) {
      newProfile.photoUrl = user!.photoUrl;
      newProfile.coverImgUrl = user!.photoUrl;
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

    (newProfile.type == ProfileType.instrumentist) ?
    newProfile.itemlists![AppConstants.firstItemlist] = Itemlist.myFirstItemlist()
        : newProfile.itemlists![AppConstants.firstItemlist] = Itemlist.myFirstItemlistFan();

    if(AppFlavour.appInUse == AppInUse.cyberneom) {
      newProfile.itemlists![AppConstants.firstItemlist]!.chamberPresets = [];
      newProfile.itemlists![AppConstants.firstItemlist]!.chamberPresets!.add(ChamberPreset.myFirstNeomChamberPreset());
      newProfile.chamberPresets = [AppConstants.firstChamberPreset];
    } else {
      newProfile.appItems = [AppFlavour.getFirstAppItemId()];
    }
    try {

      String profileId = await ProfileFirestore().insert(user!.id, newProfile);

      if(profileId.isNotEmpty) {
        newProfile.id = profileId;
        user!.profiles.add(newProfile);
        profile = newProfile;

        if(profileId.isNotEmpty) {
          await UserFirestore().updateCurrentProfile(user!.id, profileId);
          logger.i("Additional profile created successfully.");
          Get.offAllNamed(AppRouteConstants.home);
        } else {
          logger.e("Something wrong creating account.");
          Get.offAllNamed(AppRouteConstants.login);
        }
      }
    } catch (e) {
      Get.snackbar(
        MessageTranslationConstants.errorCreatingAccount.tr,
        e.toString(),
        snackPosition: SnackPosition.bottom,
      );
      logger.e("Something wrong creating account.");
      Get.offAllNamed(AppRouteConstants.login);
      update();
    }

    logger.d("");
    Get.find<SharedPreferenceController>().writeLocal();
    update([AppPageIdConstants.login, AppPageIdConstants.home]);
  }

  @override
  Future<void> getProfiles() async {
    logger.d("User looked up by ${user!.id}");

    try {
      user!.profiles = await ProfileFirestore().retrieveProfiles(user!.id);
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
      AppUser userFromFirestore = await UserFirestore().getById(userId);
      if(userFromFirestore.id.isNotEmpty){
        logger.d("User $userId exists!!");
        user = userFromFirestore;
        profile = user!.profiles.first;
      } else {
        logger.i("User $userId not exists!!");
        isNewUser = true;
      }
    } catch (e) {
      logger.e(e.toString());
    }
  }


  void addToWallet(amount) {
    if(user != null) {
      user!.wallet.amount = user!.wallet.amount + amount;
    }
    update([]);
  }


  void subtractFromWallet(amount) {
    if(user != null) {
      user!.wallet.amount = user!.wallet.amount - amount;
    }
    update([]);
  }

  Future<void> changeProfile(AppProfile selectedProfile) async {
    logger.i("Changing profile to ${selectedProfile.id}");

    try {
      profile = selectedProfile;
      Get.toNamed(AppRouteConstants.splashScreen, arguments: [AppRouteConstants.refresh]);
      profile = await UserFirestore().updateCurrentProfile(user!.id, selectedProfile.id);
    } catch(e) {
      logger.e(e.toString());
    }

    update();
  }

  @override
  Future<void> removeProfile() async {
    logger.d("removeProfile method Started");
    try {

      if(await ProfileFirestore().remove(userId: user!.id, profileId: profile.id)) {
        user!.profiles.removeWhere((element) => element.id == profile.id);
        if(user?.profiles.isNotEmpty ?? false) {
          profile = await UserFirestore().updateCurrentProfile(user!.id, user!.profiles.first.id);
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

    logger.i("removeProfile method Finished");
    update();
  }

  @override
  Future<void> reloadProfileItemlists() async {

    try {
      profile.itemlists = await ItemlistFirestore().retrieveItemlists(profile.id);
      profile.appItems?.clear();
      profile.chamberPresets?.clear();

      CoreUtilities.getTotalPresets(profile.itemlists!).forEach((key, value) {
        profile.chamberPresets!.add(key);
      });

      CoreUtilities.getTotalItems(profile.itemlists!).forEach((key, value) {
        profile.appItems!.add(key);
      });
    } catch (e) {
      AppUtilities.logger.e(e.toString());
    }

    update();
  }

}
