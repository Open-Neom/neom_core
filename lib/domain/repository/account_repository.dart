import '../model/app_profile.dart';
import '../model/app_user.dart';
import 'user_repository.dart';

/// Additional lifecycle operations already used by login. UserRepository stays
/// source-compatible; this capability preserves atomic account creation.
abstract class AccountRepository implements UserRepository {
  @override
  Future<AppUser> getById(
    String userId, {
    bool getProfileFeatures = false,
    bool throwOnError = false,
  });
  @override
  Future<AppUser?> getByEmail(
    String email, {
    bool getProfile = false,
    bool getProfileFeatures = false,
    bool throwOnError = false,
  });
  Future<String> insertWithProfile(AppUser user, AppProfile profile);
  Future<AppProfile> updateCurrentProfile(
    String userId,
    String currentProfileId,
  );
}
