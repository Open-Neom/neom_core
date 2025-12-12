import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:google_api_headers/google_api_headers.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:neom_google_places/ui/places_autocomplete.dart';
import 'package:neom_google_places/utils/enums/mode.dart';
import 'package:neom_maps_services/data/google_maps_places.dart';
import 'package:neom_maps_services/domain/models/location.dart';
import 'package:neom_maps_services/domain/models/place_autocomplete_response.dart';
import 'package:neom_maps_services/domain/models/place_details.dart';
import 'package:neom_maps_services/domain/models/prediction.dart';
import 'package:neom_maps_services/utils/component.dart';

import '../../app_config.dart';
import '../../app_properties.dart';
import '../../domain/model/app_profile.dart';
import '../../domain/model/place.dart';
import '../../domain/use_cases/maps_service.dart';
import '../../domain/use_cases/user_service.dart';
import '../../utils/constants/core_constants.dart';
import '../../utils/position_utilities.dart';

//TODO Move to neom_maps_service or something specific out of neom_core
class MapsController extends GetxController implements MapsService {

  final userServiceImpl = Get.find<UserService>();

  GoogleMapController? _googleMapController;
  final RxSet<Marker> _markers = <Marker>{}.obs;

  AppProfile profile = AppProfile();
  Position? referencePosition;
  final Rx<Position> _placePosition = Position(
      latitude: 0,
      longitude: 0,
      timestamp: DateTime.now(), accuracy: 0, altitude: 0, heading: 0, speed: 0, speedAccuracy: 0,
      altitudeAccuracy: 1, headingAccuracy: 1
  ).obs;
  Location location = Location(latitude: 0, longitude: 0);
  final Rx<Prediction> prediction = Prediction().obs;

  @override
  void onInit() async {
    super.onInit();
    AppConfig.logger.t("Maps Controller Init");

    profile = userServiceImpl.profile;

    referencePosition = await Geolocator.getCurrentPosition(
        locationSettings: LocationSettings(accuracy: LocationAccuracy.high,)
    );

    if(profile.position != null) {
      referencePosition = profile.position!;
    } else {
      referencePosition = await Geolocator.getCurrentPosition(
          locationSettings: LocationSettings(accuracy: LocationAccuracy.high,)
      );
      profile.position = referencePosition;
      userServiceImpl.profile = profile;
    }

    if(referencePosition != null) {
      _placePosition.value = referencePosition!;
      location = Location(
          latitude: referencePosition!.latitude,
          longitude: referencePosition!.longitude);
    }

    await goToHomePosition();
  }

  @override
  Future<void> goToPosition(Position position) async {
    AppConfig.logger.d("Go to position on Maps Controller");

    try {
      _placePosition.value = position;
      _googleMapController?.animateCamera(CameraUpdate.newCameraPosition(CameraPosition(
          target: LatLng(_placePosition.value.latitude, _placePosition.value.longitude),
          zoom: CoreConstants.cameraPositionZoom
      )));

      _markers.clear();
      _markers.add(
          Marker(
            markerId: const MarkerId("selectedPlace"),
            position: LatLng(position.latitude, position.longitude),
          )
      );

    } catch (e) {
      AppConfig.logger.e(e.toString());
    }

    update();
  }

  @override
  Future<void> goToHomePosition() async {
    AppConfig.logger.t("goToHomePosition on Maps Controller");

    try {
      if(referencePosition == null) {
        AppConfig.logger.d("Profile position is null, cannot go to home position");
        return;
      }

      _googleMapController?.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: LatLng(referencePosition!.latitude, referencePosition!.longitude),
            zoom: CoreConstants.cameraPositionZoom,
          )
        )
      );
    } catch (e) {
      AppConfig.logger.d(e.toString());
    }
  }

  @override
  void onError(PlacesAutocompleteResponse response) {
    try {
      AppConfig.logger.d(response.errorMessage);
    } catch (e) {
      AppConfig.logger.d(e.toString());
    }
  }

  @override
  Future<Prediction> placeAutoComplete(BuildContext context, String startText) async {
    AppConfig.logger.d("Entering placeAutoComplete with startText: $startText");

    Prediction prediction = Prediction();

    try {
      Prediction? retrievedPrediction =  await PlacesAutocomplete.show(
        startText: startText,
        offset: 0,
        radius: 1000,
        types: [],
        location: location,
        strictBounds: false,
        mode: Mode.fullscreen,
        context: context,
        apiKey: AppProperties.getGoogleApiKey(),
        onError: onError,
        language: "es-MX",
        decoration: InputDecoration(
          hintText: CoreConstants.search.tr,
          fillColor: Colors.yellow
        ),
        components: [Component(Component.country, "mx")],
      );

      if(retrievedPrediction != null) prediction = retrievedPrediction;

    } catch (e) {
      AppConfig.logger.d(e.toString());
    }

    return prediction;
  }

  @override
  CameraPosition initialCameraPosition(){
    return CameraPosition(
      target: LatLng(referencePosition!.latitude, referencePosition!.longitude),
      zoom: CoreConstants.cameraPositionZoom,
    );
  }

  @override
  CameraPosition getCameraPosition(Position position){
    return CameraPosition(
      target: LatLng(position.latitude, position.longitude),
      zoom: CoreConstants.cameraPositionZoom,
    );
  }

  @override
  Future<Place> predictionToGooglePlace(Prediction prediction) async {
    AppConfig.logger.d("Entering predictionToGooglePlace with prediction: ${prediction.toString()}");

    Place place = Place();

    ///DEPRECATED
    // if(p.terms?.isNotEmpty ?? false) {
    //   placeName = p.terms!.elementAt(0).value;
    //
    //   if(p.terms!.length == 4) {
    //     address = Address(
    //       city: p.terms!.elementAt(1).value,
    //       state: p.terms!.elementAt(2).value,
    //       country: p.terms!.elementAt(3).value,
    //     );
    //   } else if(p.terms!.length == 5) {
    //     address = Address(
    //       street: p.terms!.elementAt(1).value,
    //       city: p.terms!.elementAt(2).value,
    //       state: p.terms!.elementAt(3).value,
    //       country: p.terms!.elementAt(4).value,
    //     );
    //   } else if(p.terms!.length == 6) {
    //     address = Address(
    //       street: p.terms!.elementAt(1).value,
    //       neighborhood: p.terms!.elementAt(2).value,
    //       city: p.terms!.elementAt(3).value,
    //       state: p.terms!.elementAt(4).value,
    //       country: p.terms!.elementAt(5).value,
    //     );
    //   }
    //
    // }

    try {
      GoogleMapsPlaces places = GoogleMapsPlaces(
        apiKey: AppProperties.getGoogleApiKey(),
        apiHeaders: await const GoogleApiHeaders().getHeaders(),
      );

      PlaceDetails placeDetails = await places.getDetailsByPlaceId(
          prediction.placeId ?? '',
          language: Get.locale?.languageCode
      );

      place.name = placeDetails.displayName?.text ?? '' ;
      place.address = await PositionUtilities.getAddressFromFormattedAddress(placeDetails.formattedAddress ?? '');
      place.position = Position(
          latitude: placeDetails.location?.latitude ?? 0,
          longitude: placeDetails.location?.longitude ?? 0,
          timestamp: DateTime.now(), accuracy: 0, altitude: 0, heading: 0, speed: 0, speedAccuracy: 0,
          altitudeAccuracy: 1, headingAccuracy: 1
      );
      AppConfig.logger.i(place.toString());
    } catch (e) {
      AppConfig.logger.e(e.toString());
    }

    return place;
  }

  @override
  GoogleMapController? get googleMapController => _googleMapController;

  @override
  set googleMapController(GoogleMapController? controller) {
    _googleMapController = controller;
  }

  @override
  // TODO: implement placePosition
  Position get placePosition => _placePosition.value;

  @override
  Set<Marker> get markers => _markers.value;

}
