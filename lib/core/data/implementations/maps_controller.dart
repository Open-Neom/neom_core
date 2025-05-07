import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:google_api_headers/google_api_headers.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:neom_google_places/neom_google_places.dart';
import 'package:neom_maps_services/places.dart';

import '../../../neom_commons.dart';

class MapsController extends GetxController implements MapsService {

  final userController = Get.find<UserController>();

  final Completer<GoogleMapController> _controller = Completer();
  Completer<GoogleMapController> get controller => _controller;

  AppProfile profile = AppProfile();
  Location location = Location(lat: 37.42796133580664, lng: -122.085749655962);
  final Rx<Prediction> prediction = Prediction().obs;

  @override
  void onInit() async {
    super.onInit();
    AppUtilities.logger.t("Maps Controller Init");

    profile = userController.profile;
    if(profile.position != null) {
      location = Location(lat: profile.position!.latitude, lng: profile.position!.longitude);
    } else {
      try {
        Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
        profile.position = position;
        userController.profile = profile;
      } catch (e) {
        AppUtilities.logger.e(e.toString());
      }
    }

    await goToHomePosition();
  }

  @override
  Future<void> goToPosition(Position placePosition) async {
    AppUtilities.logger.d("Go to position on Maps Controller");

    try {
      final GoogleMapController controller = await _controller.future;
      controller.animateCamera(CameraUpdate.newCameraPosition(CameraPosition(
          target: LatLng(placePosition.latitude, placePosition.longitude),
          zoom: AppConstants.cameraPositionZoom
      )));
    } catch (e) {
      AppUtilities.logger.e(e.toString());
    }

    update([AppPageIdConstants.event]);
  }

  @override
  Future<void> goToHomePosition() async {
    AppUtilities.logger.t("goToHomePosition");

    try {
      GoogleMapController controller = await _controller.future;
      Position position = profile.position!;

      controller.animateCamera(
          CameraUpdate.newCameraPosition(
              CameraPosition(
                  target: LatLng(position.latitude, position.longitude),
                  zoom: AppConstants.cameraPositionZoom,
              )
          )
      );
    } catch (e) {
      AppUtilities.logger.d(e.toString());
    }
  }

  @override
  void onError(PlacesAutocompleteResponse response) {
    try {
      AppUtilities.logger.d(response.toString());
    } catch (e) {
      AppUtilities.logger.d(e.toString());
    }
  }

  @override
  Future<Prediction> placeAutoComplete(BuildContext context, String startText) async {
    AppUtilities.logger.d("Entering placeAutocomplate method");

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
        apiKey: AppFlavour.getGoogleApiKey(),
        onError: onError,
        language: "mx",
        decoration: InputDecoration(
          hintText: AppTranslationConstants.search.tr,
          fillColor: AppColor.yellow
        ),

        components: [Component(Component.country, "mx")],
      );

      if(retrievedPrediction != null) prediction = retrievedPrediction;

    } catch (e) {
      AppUtilities.logger.d(e.toString());
    }

    return prediction;
  }

  @override
  CameraPosition getCameraPosition(Position position){
    return CameraPosition(
      target: LatLng(position.latitude, position.longitude),
      zoom: AppConstants.cameraPositionZoom,
    );
  }

  @override
  Future<Place> predictionToGooglePlace(Prediction p) async {
    AppUtilities.logger.d("");

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
        apiKey: AppFlavour.getGoogleApiKey(),
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
      AppUtilities.logger.i(place.toString());
    } catch (e) {
      AppUtilities.logger.e(e.toString());
    }

    return place;
  }

}
