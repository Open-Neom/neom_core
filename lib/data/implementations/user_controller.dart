
import 'package:firebase_auth/firebase_auth.dart' as fba;
import 'package:sint/sint.dart';

import '../../app_config.dart';
import '../../domain/model/app_profile.dart';
import '../../domain/model/app_user.dart';
import '../../domain/model/band.dart';
import '../../domain/model/user_subscription.dart';
import '../../domain/repository/chamber_repository.dart';
import '../../domain/use_cases/login_service.dart';
import '../../domain/use_cases/user_service.dart';
import '../../utils/constants/app_route_constants.dart';
import '../../utils/constants/core_constants.dart';
import '../../utils/core_utilities.dart';
import '../../utils/enums/itemlist_type.dart';
import '../../utils/enums/owner_type.dart';
import '../../utils/enums/subscription_level.dart';
import '../../utils/enums/subscription_status.dart';
import '../../utils/enums/user_role.dart';
import '../firestore/app_release_item_firestore.dart';
import '../firestore/itemlist_firestore.dart';
import '../firestore/profile_firestore.dart';
import '../firestore/user_firestore.dart';
import '../firestore/user_subscription_firestore.dart';
import 'app_hive_controller.dart';
import 'geolocator_controller.dart';

class UserController extends SintController implements UserService {

  UserFirestore userFirestore = UserFirestore();
  
  AppUser _user = AppUser();
  AppProfile _profile = AppProfile();
  AppProfile _newProfile = AppProfile();
  Band _band = Band();

  bool _isNewUser = false;

  OwnerType _itemlistOwnerType  = OwnerType.profile;

  String fcmToken = "";

  UserSubscription? _userSubscription;
  SubscriptionLevel _subscriptionLevel = SubscriptionLevel.freemium;


  @override
  void onInit() {
    super.onInit();
    AppConfig.logger.t("onInit User Controller");
  }

  @override
  void onReady() {
    super.onReady();
    AppConfig.logger.t("onReady User Controller");
    try {
      // AppHiveController().fetchProfileInfo();
    } catch (e) {
      AppConfig.logger.e(e.toString());
    }

  }

  @override
  Future<void> removeAccount() async {
    AppConfig.logger.d("removeAccount method Started");
    try {

      if(user.id.isNotEmpty && user.profiles.isNotEmpty) {
        for (var prof in user.profiles) {
          await ProfileFirestore().remove(userId: user.id, profileId: prof.id);
        }
        await userFirestore.remove(user.id);
      }

      final loginServiceImpl = Sint.find<LoginService>();
      fba.AuthCredential? authCredential;

      if(loginServiceImpl.getAuthCredentials() == null) {
        await loginServiceImpl.setAuthCredentials();
      }

      authCredential = loginServiceImpl.getAuthCredentials();

      if(authCredential != null) {
        await loginServiceImpl.deleteFbaUser(authCredential);
        clear();
      } else {
        AppConfig.logger.e("AuthCredentials to reauthenticate were null");
        Sint.offAndToNamed(AppRouteConstants.login);
      }

    } catch (e) {
      Sint.snackbar(
        CoreConstants.errorSigningOut.tr,
        e.toString(),
        snackPosition: SnackPosition.bottom,
      );

      Sint.toNamed(AppRouteConstants.logout);
    }

    AppConfig.logger.i("removeAccount method Finished");
    update();
  }

  /// Create user profile from google login
  @override
  void getUserFromFirebase(fba.User fbaUser) {
    AppConfig.logger.d("Getting User Info From Firebase Authentication");
    user =  AppUser(
      dateOfBirth: 0,
      homeTown: CoreConstants.somewhereUniverse.tr,
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

    AppConfig.logger.d('Last login at: ${fbaUser.metadata.lastSignInTime}');
    AppConfig.logger.d(user.toString());
  }

  void clear() {
    AppConfig.logger.d("Clearing User");
    user = AppUser();
  }


  @override
  Future<void> createUser() async {

    AppConfig.logger.d("User to create ${user.name}");
    AppUser newUser = user;
    setNewProfileInfo();

    newUser.profiles = [_newProfile];
    newUser.userRole = UserRole.subscriber;

    try {

      if(newUser.name.isEmpty) newUser.name = _newProfile.name;

      newUser.createdDate = DateTime.now().millisecondsSinceEpoch;

      if(await userFirestore.insert(newUser)) {
        _isNewUser = false;

        String profileId = await ProfileFirestore().insert(newUser.id, newUser.profiles.first);

        if(profileId.isNotEmpty) {
          newUser.profiles.first.id = profileId;
          newUser.currentProfileId = profileId;
          userFirestore.updateCurrentProfile(newUser.id, profileId);
          profile = newUser.profiles.first;
          user = newUser;
          AppHiveController().writeProfileInfo();
          Sint.offAllNamed(AppRouteConstants.home);
        } else {
          userFirestore.remove(newUser.id);
          Sint.snackbar(
            CoreConstants.errorCreatingAccount.tr,
            '',
            snackPosition: SnackPosition.bottom,
          );

          Sint.offAllNamed(AppRouteConstants.login);
        }
      } else {
        Sint.snackbar(
          CoreConstants.errorCreatingAccount.tr,
          '',
          snackPosition: SnackPosition.bottom,
        );

        Sint.offAllNamed(AppRouteConstants.login);
      }
    } catch (e) {
      AppConfig.logger.e("Error creating user: $e");
      Sint.snackbar(
        CoreConstants.errorCreatingAccount.tr,
        e.toString(),
        snackPosition: SnackPosition.bottom,
      );
      // Navigate back to login on error to prevent stuck screen
      Sint.offAllNamed(AppRouteConstants.login);
    }
  }

  void setNewProfileInfo() {
    _newProfile.photoUrl = user.photoUrl;
    _newProfile.coverImgUrl = user.photoUrl;
    _newProfile.mainFeature = CoreUtilities.getProfileMainFeature(_newProfile);
    _newProfile.isActive = true;
    _newProfile.reviewStars = 0;
    _newProfile.bannedGenres = [];
    _newProfile.itemmates = [];
    _newProfile.eventmates = [];
    _newProfile.followers = [];
    _newProfile.following = [];
    _newProfile.unfollowing = [];
    _newProfile.blockTo = [];
    _newProfile.blockedBy = [];
    _newProfile.posts = [];
    _newProfile.hiddenPosts = [];
    _newProfile.reports = [];
    _newProfile.bands = [];
    _newProfile.events = [];
    _newProfile.reviews = [];
    _newProfile.watchingEvents = [];
    _newProfile.goingEvents = [];
    _newProfile.playingEvents = [];
    _newProfile.itemlists = {};
    _newProfile.favoriteItems = [];
  }

  @override
  Future<void> createProfile() async {

    AppConfig.logger.d("Profile to create ${_newProfile.name}");

    if(_newProfile.photoUrl.isEmpty) {
      _newProfile.photoUrl = user.photoUrl;
      _newProfile.coverImgUrl = user.photoUrl;
    } else {
      _newProfile.coverImgUrl = _newProfile.photoUrl;
    }

    _newProfile.mainFeature = CoreUtilities.getProfileMainFeature(_newProfile);
    _newProfile.isActive = true;
    _newProfile.reviewStars = 0;
    _newProfile.bannedGenres = [];
    _newProfile.itemmates = [];
    _newProfile.eventmates = [];
    _newProfile.followers = [];
    _newProfile.following = [];
    _newProfile.unfollowing = [];
    _newProfile.blockTo = [];
    _newProfile.blockedBy = [];
    _newProfile.posts = [];
    _newProfile.hiddenPosts = [];
    _newProfile.reports = [];
    _newProfile.bands = [];
    _newProfile.events = [];
    _newProfile.reviews = [];

    _newProfile.watchingEvents = [];
    _newProfile.goingEvents = [];
    _newProfile.playingEvents = [];
    _newProfile.itemlists = {};
    _newProfile.favoriteItems = [];

    try {

      String profileId = await ProfileFirestore().insert(user.id, _newProfile);

      if(profileId.isNotEmpty) {
        _newProfile.id = profileId;
        user.profiles.add(_newProfile);
        profile = _newProfile;

        if(profileId.isNotEmpty) {
          userFirestore.updateCurrentProfile(user.id, profileId);
          AppConfig.logger.i("Additional profile created successfully.");
          Sint.offAllNamed(AppRouteConstants.home);
        } else {
          AppConfig.logger.e("Something wrong creating account.");
          Sint.offAllNamed(AppRouteConstants.login);
        }
      }
    } catch (e) {
      Sint.snackbar(
        CoreConstants.errorCreatingAccount.tr,
        e.toString(),
        snackPosition: SnackPosition.bottom,
      );
      AppConfig.logger.e("Something wrong creating account.");
      Sint.offAllNamed(AppRouteConstants.login);
      update();
    }

    AppConfig.logger.d("Profile created: ${_newProfile.name} with id: ${_newProfile.id}");
    AppHiveController().writeProfileInfo();
    update();
  }

  @override
  Future<void> getProfiles() async {
    if(user.id.isEmpty) return;
    
    AppConfig.logger.d("User looked up by ${user.id}");

    try {
      user.profiles = await ProfileFirestore().retrieveByUserId(user.id);
    } catch (e) {
      Sint.snackbar(
        CoreConstants.errorRetrievingProfiles.tr,
        e.toString(),
        snackPosition: SnackPosition.bottom,
      );
    }
    update();
  }


  @override
  Future<void> setUserById(String userId) async {

    try {
      AppUser userFromFirestore = await userFirestore.getById(userId);
      if(userFromFirestore.id.isNotEmpty){
        AppConfig.logger.i("User $userId exists!!");
        user = userFromFirestore;
        profile = user.profiles.first;
        _isNewUser = false;
      } else {
        AppConfig.logger.w("User $userId not exists!!");
        _isNewUser = true;
      }
    } catch (e) {
      AppConfig.logger.e(e.toString());
    }
  }

  @override
  Future<void> setUserByEmail(String userEmail) async {

    try {
      AppUser? userFromEmail = await userFirestore.getByEmail(userEmail, getProfile: true);
      if(userFromEmail?.id.isNotEmpty ?? false) {
        AppConfig.logger.t("User $userEmail exists!!");
        user = userFromEmail!;
        if(user.profiles.isNotEmpty) {
          profile = user.profiles.first;
          _isNewUser = false;
        } else {
          AppConfig.logger.w("User $userEmail exists but has no profiles");
          _isNewUser = false;
        }
      } else {
        AppConfig.logger.w("User $userEmail not exists!!");
        _isNewUser = true;
      }
    } catch (e) {
      AppConfig.logger.e(e.toString());
    }
  }

  @override
  Future<void> changeProfile(AppProfile selectedProfile) async {
    AppConfig.logger.i("Changing profile to ${selectedProfile.id}");

    try {
      profile = selectedProfile;
      Sint.toNamed(AppRouteConstants.splashScreen, arguments: [AppRouteConstants.home]);
      profile = await userFirestore.updateCurrentProfile(user.id, selectedProfile.id);
    } catch(e) {
      AppConfig.logger.e(e.toString());
    }

    update();
  }

  @override
  Future<void> removeProfile() async {
    AppConfig.logger.d("removeProfile method Started");
    try {

      if(await ProfileFirestore().remove(userId: user.id, profileId: profile.id)) {
        user.profiles.removeWhere((element) => element.id == profile.id);
        if(user.profiles.isNotEmpty) {
          profile = await userFirestore.updateCurrentProfile(user.id, user.profiles.first.id);
        }

      }

    } catch (e) {
      Sint.snackbar(
        CoreConstants.errorSigningOut.tr,
        e.toString(),
        snackPosition: SnackPosition.bottom,
      );
      Sint.toNamed(AppRouteConstants.logout);
    }

    AppConfig.logger.i("removeProfile method Finished");
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
      AppConfig.logger.e(e.toString());
    }

    update([]);
  }

  @override
  Future<void> loadProfileChambers() async {

    try {
      profile.chambers = await Sint.find<ChamberRepository>().fetchAll(ownerId: profile.id);
      profile.chamberPresets?.clear();

      CoreUtilities.getTotalPresets(profile.chambers!).forEach((key, value) {
        profile.chamberPresets!.add(key);
      });

    } catch (e) {
      AppConfig.logger.e(e.toString());
    }

    update();
  }

  @override
  void stopGoingToEvent(String eventId) {
    profile.goingEvents?.remove(eventId);
    try {
      //Sint.find<EventDetailsController>().stopGoingToEvent();
    } catch (e) {
      AppConfig.logger.e(e.toString());
    }
    update();
  }

  @override
  void goingToEvent(String eventId) {
    profile.goingEvents?.add(eventId);
    try {
      //Sint.find<EventDetailsController>().stopGoingToEvent();
    } catch (e) {
      AppConfig.logger.e(e.toString());
    }
    update();
  }

  @override
  Future<void> addOrderId(String orderId) async {
    AppConfig.logger.d("addOrderId $orderId");
    try {
      if(await userFirestore.addOrderId(userId: user.id, orderId: orderId)) {
        user.orderIds.add(orderId);
      } else {
        AppConfig.logger.w("Something occurred while adding order to User ${user.id}");
      }
    } catch (e) {
      AppConfig.logger.e(e.toString());
    }
    update();
  }

  @override
  Future<void> addBoughtItem(String itemId) async {
    AppConfig.logger.d("addBoughtItem $itemId");
    try {
      if(itemId.isNotEmpty) {
        if(await userFirestore.addBoughtItem(userId: user.id, itemId: itemId)) {
          user.boughtItems ??= [];
          user.boughtItems!.add(itemId);
        }

        AppReleaseItemFirestore().addBoughtUser(releaseItemId: itemId, userId: user.id);
      }
    } catch (e) {
      AppConfig.logger.e(e.toString());
    }
    update();
  }

  @override
  Future<void> updateCustomerId(String customerId) async {
    AppConfig.logger.d("updateCustomerId $customerId");

    try {
      user.customerId = customerId;
      userFirestore.updateCustomerId(user.id, customerId);
    } catch (e) {
      AppConfig.logger.e(e.toString());
    }

    update();
  }

  @override
  Future<void> updateSubscriptionId(String subscriptionId) async {
    AppConfig.logger.d("updateSubscriptionId $subscriptionId");

    try {
      user.subscriptionId = subscriptionId;
      userFirestore.updateSubscriptionId(user.id, subscriptionId);
    } catch (e) {
      AppConfig.logger.e(e.toString());
    }

    update();
  }

  @override
  Future<bool> updatePhoneNumber(String phone, String countryCode) async {
    AppConfig.logger.d("updatePhoneNumber Phone: $phone & countryCode $countryCode");
    bool wasUpdated = false;
    try {
      if(user.phoneNumber != phone) {
        if(await userFirestore.isAvailablePhone(phone)) {

          if(user.countryCode != countryCode) {
            userFirestore.updateCountryCode(user.id, countryCode);
            user.countryCode = countryCode;
          } else {
            AppConfig.logger.d("Same Country Code");
          }

          userFirestore.updatePhoneNumber(user.id, phone);
          user.phoneNumber = phone;
          wasUpdated = true;
        } else {
          AppConfig.logger.e("Phone number is not available");
          Sint.snackbar(CoreConstants.updatePhone.tr,
            CoreConstants.phoneNotAvailable.tr,
            snackPosition: SnackPosition.bottom,
          );
        }
      } else {
        AppConfig.logger.d("Same Phone number");
      }
    } catch (e) {
      AppConfig.logger.e(e.toString());
    }

    update();
    return wasUpdated;
  }

  @override
  Future<void> getUserSubscription() async {
    AppConfig.logger.d('getUserSubscription');

    try {
      List<UserSubscription> subscriptions = await UserSubscriptionFirestore().getByUserId(user.id);

      if(subscriptions.isNotEmpty) {
        _userSubscription = subscriptions.firstWhereOrNull((subscription) => subscription.status == SubscriptionStatus.active);
        if(userSubscription?.subscriptionId == user.subscriptionId) {
          _subscriptionLevel = userSubscription?.level ?? SubscriptionLevel.freemium;
          AppConfig.logger.d('User ${userSubscription?.subscriptionId} is the same as ${user.subscriptionId} for ${subscriptionLevel.name}');
        } else if(userSubscription?.subscriptionId.isNotEmpty ?? false) {
          user.subscriptionId = userSubscription?.subscriptionId ?? '';
          AppConfig.logger.d('User subscription is different from user.subscriptionId');
        }
      } else if(user.subscriptionId.isNotEmpty) {
        if (CoreUtilities.isWithinFirstMonth(user.createdDate)) {
          _subscriptionLevel = SubscriptionLevel.freeMonth;
          AppConfig.logger.i('User subscriptionId ${user.subscriptionId} is still within free month for SubscriptionLevel ${subscriptionLevel.name}');
        } else {
          AppConfig.logger.w('User subscriptionId ${user.subscriptionId} is out of free month');
          user.subscriptionId = "";
        }
      } else if(user.userRole.value > UserRole.subscriber.value){
        AppConfig.logger.d('No user subscription found');
        _subscriptionLevel = SubscriptionLevel.ambassador;
      }
    } catch (e) {
      AppConfig.logger.e(e.toString());
    }

  }

  @override
  Future<void> setUserSubscription(UserSubscription subscription) async {
    AppConfig.logger.d('Setting userSubscription with subscriptionId: ${subscription.subscriptionId}');

    try {
      _userSubscription = subscription;
    } catch (e) {
      AppConfig.logger.e(e.toString());
    }

  }

  @override
  Future<void> setIsVerified(bool isVerified) async {
    AppConfig.logger.d('Setting isVerified value $isVerified for: ${user.id}');

    try {
      await userFirestore.setIsVerified(user.id, isVerified);
      user.isVerified = isVerified;
    } catch (e) {
      AppConfig.logger.e(e.toString());
    }

  }

  @override
  Future<void> verifyLocation() async {
    AppConfig.logger.t("Verifying location");
    try {
      profile.position = await GeoLocatorController().updateLocation(profile.id, profile.position);
    } catch (e) {
      AppConfig.logger.e(e.toString());
    }
  }

  @override
  Future<void> getUserFromFacebook(String fbAccessToken) {
    // TODO: implement getUserFromFacebook
    throw UnimplementedError();
  }

  @override
  AppProfile get profile => _profile;

  @override
  AppUser get user => _user;

  @override
  set profile(AppProfile appProfile) {
    _profile = appProfile;
  }

  @override
  set user(AppUser appUser) {
    _user = appUser;
  }

  @override
  UserSubscription? get userSubscription => _userSubscription;

  @override
  set userSubscription(UserSubscription? subscription) {
    _userSubscription = subscription;
  }

  @override
  SubscriptionLevel get subscriptionLevel => _subscriptionLevel;

  @override
  Band get band => _band;

  @override
  OwnerType get itemlistOwnerType => _itemlistOwnerType;

  @override
  set band(Band band) {
    _band = band;
  }

  @override
  set itemlistOwnerType(OwnerType ownerType) {
    _itemlistOwnerType = ownerType;
  }

  @override
  AppProfile get newProfile => _newProfile;

  @override
  bool get isNewUser => _isNewUser;

  @override
  set newProfile(AppProfile appProfile) {
    _newProfile = appProfile;
  }


  ItemlistType? _currentItemlistType;

  @override
  ItemlistType? get currentItemlistType => _currentItemlistType;

  @override
  void setCurrentItemlistType(ItemlistType? type) {
    _currentItemlistType = type;
  }

}
