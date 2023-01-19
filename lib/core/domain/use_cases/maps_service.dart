import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_maps_webservice/places.dart';

abstract class MapsService {

  Future<void> goToPosition(Position placePosition);
  Future<void> goToHomePosition();
  void onError(PlacesAutocompleteResponse response);
  Future<Prediction> placeAutocomplate(BuildContext context, String startText);
  CameraPosition getCameraPosition(Position position);

}
