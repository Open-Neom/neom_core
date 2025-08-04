import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:google_api_headers/google_api_headers.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:neom_google_places/neom_google_places.dart';
import 'package:neom_maps_services/places.dart';

import '../../app_config.dart';
import '../../app_properties.dart';
import '../../domain/model/address.dart';
import '../../domain/model/app_profile.dart';
import '../../domain/model/place.dart';
import '../../domain/use_cases/maps_service.dart';
import '../../domain/use_cases/user_service.dart';
import '../../utils/constants/core_constants.dart';

//TODO Move to neom_maps_service or something specific out of neom_core
class MapsController extends GetxController implements MapsService {

  final userServiceImpl = Get.find<UserService>();

  final Completer<GoogleMapController> _googleMapController = Completer();

  AppProfile profile = AppProfile();
  Location location = Location(lat: 37.42796133580664, lng: -122.085749655962);
  final Rx<Prediction> prediction = Prediction().obs;

  @override
  void onInit() async {
    super.onInit();
    AppConfig.logger.t("Maps Controller Init");

    profile = userServiceImpl.profile;
    if(profile.position != null) {
      location = Location(lat: profile.position!.latitude, lng: profile.position!.longitude);
    } else {
      try {
        Position position = await Geolocator.getCurrentPosition(
          locationSettings: LocationSettings(accuracy: LocationAccuracy.high,)
        );
        profile.position = position;
        userServiceImpl.profile = profile;
      } catch (e) {
        AppConfig.logger.e(e.toString());
      }
    }

    await goToHomePosition();
  }

  @override
  Future<void> goToPosition(Position placePosition) async {
    AppConfig.logger.d("Go to position on Maps Controller");

    try {
      final GoogleMapController controller = await _googleMapController.future;
      controller.animateCamera(CameraUpdate.newCameraPosition(CameraPosition(
          target: LatLng(placePosition.latitude, placePosition.longitude),
          zoom: CoreConstants.cameraPositionZoom
      )));
    } catch (e) {
      AppConfig.logger.e(e.toString());
    }

    update();
  }

  @override
  Future<void> goToHomePosition() async {
    AppConfig.logger.t("goToHomePosition");

    try {
      GoogleMapController controller = await _googleMapController.future;
      Position position = profile.position!;

      controller.animateCamera(
          CameraUpdate.newCameraPosition(
              CameraPosition(
                  target: LatLng(position.latitude, position.longitude),
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
      AppConfig.logger.d(response.toString());
    } catch (e) {
      AppConfig.logger.d(e.toString());
    }
  }

  @override
  Future<Prediction> placeAutoComplete(BuildContext context, String startText) async {
    AppConfig.logger.d("Entering placeAutocomplate method");

    Prediction prediction = Prediction();

    try {
      Prediction? retrievedPrediction =  await PlacesAutocomplete.show(
        startText: startText,
        offset: 0,
        radius: 1000,
        types: [],
        location: location,
        strictbounds: false,
        mode: Mode.fullscreen,
        context: context,
        apiKey: AppProperties.getGoogleApiKey(),
        onError: onError,
        language: "mx",
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
  CameraPosition getCameraPosition(Position position){
    return CameraPosition(
      target: LatLng(position.latitude, position.longitude),
      zoom: CoreConstants.cameraPositionZoom,
    );
  }

  @override
  Future<Place> predictionToGooglePlace(Prediction p) async {
    AppConfig.logger.d("");

    Place place = Place();
    String placeName = "";
    Address address = Address();
    if(p.terms.isNotEmpty) {
      placeName = p.terms.elementAt(0).value;

      if(p.terms.length == 4) {
        address = Address(
          city: p.terms.elementAt(1).value,
          state: p.terms.elementAt(2).value,
          country: p.terms.elementAt(3).value,
        );
      } else if(p.terms.length == 5) {
        address = Address(
          street: p.terms.elementAt(1).value,
          city: p.terms.elementAt(2).value,
          state: p.terms.elementAt(3).value,
          country: p.terms.elementAt(4).value,
        );
      } else if(p.terms.length == 6) {
        address = Address(
          street: p.terms.elementAt(1).value,
          neighborhood: p.terms.elementAt(2).value,
          city: p.terms.elementAt(3).value,
          state: p.terms.elementAt(4).value,
          country: p.terms.elementAt(5).value,
        );
      }

    }

    try {
      GoogleMapsPlaces places = GoogleMapsPlaces(
        apiKey: AppProperties.getGoogleApiKey(),
        apiHeaders: await const GoogleApiHeaders().getHeaders(),
      );

      PlacesDetailsResponse detail = await places.getDetailsByPlaceId(p.placeId!);

      place.name = placeName;
      place.address = address;
      place.position = Position(
          latitude: detail.result.geometry!.location.lat,
          longitude: detail.result.geometry!.location.lng,
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
  Completer<GoogleMapController> get googleMapController => _googleMapController;

}
