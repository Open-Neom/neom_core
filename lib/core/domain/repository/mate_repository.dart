import '../model/app_profile.dart';

abstract class MateRepository {

  Future<Map<String, AppProfile>> getMatesFromList(List<String> mateIds);
  Future<AppProfile>? getMateSimple(String mateId);

  Future<bool> addMate(String profileId, String mateId);
  Future<bool> removeMate(String profileId, String mateId);

  void sendMateRequest();

}
