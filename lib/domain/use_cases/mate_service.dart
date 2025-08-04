
import '../model/app_profile.dart';

abstract class MateService {

  Map<String, AppProfile> get mates;
  Map<String, AppProfile> get profiles;
  Map<String, AppProfile> get followerProfiles;
  Map<String, AppProfile> get followingProfiles;
  Map<String, AppProfile> get totalProfiles;

  Future<void> loadProfiles({bool includeSelf = false});
  Future<void> loadMates();
  Future<void> loadMatesFromList(List<String> mateIds);
  Future<void> getMateDetails(AppProfile mate);
  Future<void> block(String mateId);

}
