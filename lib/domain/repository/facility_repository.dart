import 'dart:async';

import '../../utils/enums/facilitator_type.dart';
import '../model/facility.dart';


abstract class FacilityRepository {

  Future<Map<String?,Facility>> retrieveFacilities(profileId);

  Future<bool> removeFacility({required String profileId, required String facilityId});

  Future<bool> addFacility({required String profileId, required FacilityType facilityType});

  Future<bool> updateMainFacility({required String profileId,
    required String facilityId, required String prevFacilityId});

}
