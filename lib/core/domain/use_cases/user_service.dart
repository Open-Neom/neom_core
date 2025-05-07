import 'package:firebase_auth/firebase_auth.dart';

import '../model/user_subscription.dart';

abstract class UserService {

  Future<void> createUser();
  Future<void> removeAccount();
  // Future<void> getUserFromFacebook(String fbAccessToken);
  void getUserFromFirebase(User fbaUser);
  Future<void> getUserById(String userId);
  Future<void> getUserByEmail(String userEmail);
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

}
