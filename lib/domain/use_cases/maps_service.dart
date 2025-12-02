import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:neom_maps_services/domain/models/place_autocomplete_response.dart';
import 'package:neom_maps_services/domain/models/prediction.dart';

import '../model/place.dart';

abstract class MapsService {

  Future<void> goToPosition(Position placePosition);
  Future<void> goToHomePosition();
  void onError(PlacesAutocompleteResponse response);
  Future<Prediction> placeAutoComplete(BuildContext context, String startText);
  CameraPosition initialCameraPosition();
  CameraPosition getCameraPosition(Position position);
  Future<Place> predictionToGooglePlace(Prediction prediction);

  GoogleMapController? get googleMapController;
  Position get placePosition;
  set googleMapController(GoogleMapController? controller);

  Set<Marker> get markers;

}
