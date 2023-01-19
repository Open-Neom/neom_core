import 'dart:async';

import '../../utils/enums/place_type.dart';
import '../model/place.dart';

abstract class PlaceRepository {

  Future<Map<String?,Place>> retrievePlaces(profileId);

  Future<bool> removePlace({required String profileId, required String placeId});

  Future<bool> addPlace({required String profileId, required PlaceType placeType});

  Future<bool> updateMainPlace({required String profileId,
    required String placeId, required String prevPlaceId});

}
