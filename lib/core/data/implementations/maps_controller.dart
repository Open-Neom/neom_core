import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_google_places/flutter_google_places.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_maps_webservice/places.dart';

import '../../domain/model/app_profile.dart';
import '../../domain/use_cases/maps_service.dart';
import '../../utils/app_utilities.dart';
import '../../utils/constants/app_constants.dart';
import '../../utils/constants/app_google_constants.dart';
import '../../utils/constants/app_page_id_constants.dart';
import '../../utils/constants/app_translation_constants.dart';
import 'user_controller.dart';

class MapsController extends GetxController implements MapsService {

  var logger = AppUtilities.logger;
  final userController = Get.find<UserController>();

  final Completer<GoogleMapController> _controller = Completer();
  Completer<GoogleMapController> get controller => _controller;

  AppProfile profile = AppProfile();
  Location _location = Location(lat: 37.42796133580664, lng: -122.085749655962);

  @override
  void onInit() async {
    super.onInit();
    logger.d("Maps Controller Init");

    profile = userController.profile;
    _location = Location(lat: profile.position!.latitude, lng: profile.position!.longitude);


    await goToHomePosition();

  }

  @override
  Future<void> goToPosition(Position placePosition) async {
    logger.d("");

    try {
      final GoogleMapController controller = await _controller.future;
      controller.animateCamera(CameraUpdate.newCameraPosition(CameraPosition(
          target: LatLng(placePosition.latitude, placePosition.longitude),
          zoom: AppConstants.cameraPositionZoom
      )));
    } catch (e) {
      logger.e(e.toString());
    }

    update([AppPageIdConstants.event]);
  }

  @override
  Future<void> goToHomePosition() async {
    logger.d("");

    try {
      GoogleMapController controller = await _controller.future;
      Position position = profile.position!;

      controller.animateCamera(CameraUpdate.newCameraPosition(CameraPosition(
        //bearing: 192.8334901395799,
          target: LatLng(position.latitude, position.longitude),
          // tilt: 59.440717697143555,
          zoom: AppConstants.cameraPositionZoom
      )));
    } catch (e) {
      logger.d(e.toString());
    }

  }

  @override
  void onError(PlacesAutocompleteResponse response) {
    try {
      logger.d(response.toString());
    } catch (e) {
      logger.d(e.toString());
    }
  }



  final Rx<Prediction> _prediction = Prediction().obs;
  Prediction get prediction => _prediction.value;


  @override
  Future<Prediction> placeAutocomplate(BuildContext context, String startText) async {
    logger.d("Entering placeAutocomplate method");

    Prediction prediction = Prediction();

    try {
      Prediction? retrievedPrediction =  await PlacesAutocomplete.show(
        //logo: Text(""),
        startText: startText,
        offset: 0,
        radius: 1000,
        types: [],
        location: _location,
        strictbounds: false,
        mode: Mode.fullscreen,
        context: context,
        apiKey: AppGoogleConstants.kGoogleApiKey,
        onError: onError,
        language: "mx",
        decoration: InputDecoration(
          hintText: AppTranslationConstants.search.tr,
        ),
        components: [Component(Component.country, "mx")],
      );

      if(retrievedPrediction != null) prediction = retrievedPrediction;

    } catch (e) {
      logger.d(e.toString());
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

}
