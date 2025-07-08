
import '../model/app_profile.dart';

abstract class MateService {

  Future<void> loadProfiles();
  Future<void> loadMates();
  Future<void> loadMatesFromList(List<String> itemmateIds);
  Future<void> getMateDetails(AppProfile itemmate);
  Future<void> block(String itemmateId);

}
