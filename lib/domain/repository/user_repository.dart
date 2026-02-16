import 'package:geolocator/geolocator.dart';

import '../../utils/enums/facilitator_type.dart';
import '../../utils/enums/profile_type.dart';
import '../../utils/enums/user_role.dart';
import '../model/app_user.dart';

abstract class UserRepository {

  Future<bool> insert(AppUser user);
  Future<AppUser> getById(String userId);
  Future<AppUser?> getByEmail(String email);
  Future<AppUser> getByProfileId(String userId);
  Future<List<AppUser>> getAll();
  Future<bool> remove(String userId);
  Future<bool> updateAndroidNotificationToken(String userId, String token);
  Future<bool> isAvailableEmail(String email);
  Future<bool> isAvailablePhone(String phoneNumber);
  // Future<bool> addToWallet(String userId, double amount, {AppCurrency appCurrency = AppCurrency.appCoin});
  Future<bool> updatePhotoUrl(String userId, String photoUrl);
  Future<bool> addOrderId({required String userId, required String orderId});
  Future<bool> removeOrderId({required String userId, required String orderId});
  Future<bool> updateFcmToken(String userId, String fcmToken);
  Future<String> retrieveFcmToken(String userId);
  Future<bool> updateSpotifyToken(String userId, String spotifyToken);
  Future<void> updateLastTimeOn(String userId);
  Future<List<AppUser>> getWithParameters({
    bool needsPhone  = false, bool includeProfile = false, bool needsPosts = false,
    List<ProfileType>? profileTypes, FacilityType? facilityType,
    Position? currentPosition, int maxDistance = 30,});

  Future<List<String>> getFCMTokens();
  ///DEPRECATED Future<bool> addReleaseItem({required String userId, required String releaseItemId});
  Future<bool> updateUserRole(String userId, UserRole userRole);

  Future<bool> addBoughtItem({required String userId, required String itemId});
  Future<bool> removeBoughtItem(String userId, String itemId);
  Future<void> updateCustomerId(String userId, String customerId);
  Future<void> updateSubscriptionId(String userId, String subscriptionId);
  Future<void> updatePhoneNumber(String userId, String phoneNumber);
  Future<void> updateCountryCode(String userId, String countryCode);
  Future<void> setIsVerified(String userId, bool isVerified);

}
