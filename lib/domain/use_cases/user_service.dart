import 'package:firebase_auth/firebase_auth.dart';

import '../../utils/enums/owner_type.dart';
import '../../utils/enums/subscription_level.dart';
import '../model/app_profile.dart';
import '../model/app_user.dart';
import '../model/band.dart';
import '../model/user_subscription.dart';

abstract class UserService {

  Future<void> createUser();
  Future<void> removeAccount();
  Future<void> getUserFromFacebook(String fbAccessToken);
  void getUserFromFirebase(User fbaUser);
  Future<void> setUserById(String userId);
  Future<void> setUserByEmail(String userEmail);
  Future<void> changeProfile(AppProfile selectedProfile);
  Future<void> createProfile();
  Future<void> getProfiles();
  Future<void> removeProfile();
  Future<void> reloadProfileItemlists();
  Future<void> loadProfileChambers();
  void stopGoingToEvent(String eventId);
  void goingToEvent(String eventId);
  Future<void> addOrderId(String orderId);
  Future<void> addBoughtItem(String itemId);
  Future<void> updateCustomerId(String customerId);
  Future<void> updateSubscriptionId(String subscriptionId);
  Future<bool> updatePhoneNumber(String phone, String countryCode);
  Future<void> getUserSubscription();
  Future<void> setUserSubscription(UserSubscription subscription);
  Future<void> setIsVerified(bool isVerified);
  Future<void> verifyLocation();

  AppUser get user;
  set user(AppUser appUser);

  AppProfile get profile;
  set profile(AppProfile appProfile);

  AppProfile get newProfile;
  set newProfile(AppProfile appProfile);

  bool get isNewUser;

  UserSubscription? get userSubscription;
  set userSubscription(UserSubscription? subscription);

  SubscriptionLevel get subscriptionLevel;

  Band get band;
  set band(Band band);

  OwnerType get itemlistOwnerType;
  set itemlistOwnerType(OwnerType ownerType);

}
