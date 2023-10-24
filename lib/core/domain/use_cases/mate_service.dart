import 'package:flutter/cupertino.dart';

import '../model/app_profile.dart';

abstract class MateService {

  Future<void> loadProfiles();
  Future<void> loadMates();
  Future<void> loadMatesFromList(List<String> itemmateIds);
  Map<String, AppProfile> filterByNameOrInstrument(String name);
  Future<void> getMateDetails(AppProfile itemmate);
  Future<void> blockMate(String itemmateId);
  Future<void> showBlockProfileAlert(BuildContext context, String postOwnerId);

}
