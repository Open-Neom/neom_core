import '../../utils/enums/app_currency.dart';
import '../model/app_user.dart';

abstract class UserRepository {

  Future<bool> insert(AppUser user);
  Future<AppUser> getById(userId);
  Future<List<AppUser>> getAll();
  Future<bool> remove(String userId);
  Future<bool> updateAndroidNotificationToken(String userId, String token);
  Future<bool> isAvailableEmail(String email);
  Future<bool> isAvailablePhone(String phoneNumber);
  Future<bool> addToWallet(String userId, double amount, {AppCurrency appCurrency = AppCurrency.appCoin});
  Future<bool> updatePhotoUrl(String userId, String photoUrl);
  Future<bool> addOrderId({required String userId, required String orderId});
  Future<bool> removeOrderId({required String userId, required String orderId});
  Future<bool> updateFcmToken(String userId, String fcmToken);
  Future<String> retrieveFcmToken(String userId);
  Future<bool> updateSpotifyToken(String userId, String spotifyToken);
  Future<void> updateLastTimeOn(String userId);

}
