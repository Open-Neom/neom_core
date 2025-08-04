import 'dart:async';

import 'package:geolocator/geolocator.dart';
import '../model/app_profile.dart';

abstract class ProfileInstrumentsRepository {

  Future<List<AppProfile>> retrieveAll();
  Future<Map<String,AppProfile>> retrieveProfilesBySpecs({
    String instrumentId = "",
    String selfProfileId = "",
    Position? currentPosition,
    int maxDistance = 20,
    int maxProfiles = 10,
  });

}
