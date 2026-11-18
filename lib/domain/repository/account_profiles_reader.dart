import '../model/app_profile.dart';

/// Optional account-scoped listing capability, independent of login bootstrap.
abstract class AccountProfilesReader {
  Future<List<AppProfile>> getOwnedProfiles(String userId);
}
