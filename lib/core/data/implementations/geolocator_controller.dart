import 'dart:async';

import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';

import '../../domain/use_cases/geolocator_service.dart';
import '../../utils/app_utilities.dart';
import '../../utils/constants/app_constants.dart';
import '../../utils/constants/app_route_constants.dart';
import '../firestore/profile_firestore.dart';

class GeoLocatorController implements GeoLocatorService {

  @override
  Future<Placemark> getPlaceMark(Position currentPos) async {

    Placemark placeMark = const Placemark();
    List<Placemark> placeMarks = [];
    try {
      if(currentPos.latitude != 0 && currentPos.longitude != 0) {
        placeMarks = await placemarkFromCoordinates(currentPos.latitude, currentPos.longitude);
        if(placeMarks.isNotEmpty) {
          placeMark = placeMarks.first;
        }
      }
    } catch (e) {
      AppUtilities.logger.e(e.toString());
    }

    return placeMark;
  }

  @override
  Future<String> getAddressSimple(Position currentPos) async {
    AppUtilities.logger.t(currentPos.toString());
    String address = "";
    List<Placemark> placeMarks = [];

    try {
      if(currentPos.latitude != 0) {
        placeMarks = await placemarkFromCoordinates(currentPos.latitude, currentPos.longitude);
        Placemark placeMark  = placeMarks[0];
        String locality = placeMark.locality!;
        String administrativeArea = placeMark.administrativeArea!;
        String country = placeMark.country!;

        if(country.isNotEmpty) {
          locality.isNotEmpty ?
          address = "$locality, $country"
              : address = "$administrativeArea, $country";
        }
      }
    } catch (e) {
      AppUtilities.logger.e(e.toString());
    }


    AppUtilities.logger.t(address);
    return address;
  }


  @override
  Future<LocationPermission> requestPermission() async {

    bool serviceEnabled;
    LocationPermission permission = LocationPermission.unableToDetermine;

    try {

      serviceEnabled = await Geolocator.isLocationServiceEnabled();

      if (!serviceEnabled) {
        return Future.error('Location services are disabled.');
      }

      permission = await Geolocator.checkPermission();
      AppUtilities.logger.d('Current LocationPermission is: ${permission.name}');

      permission = await Geolocator.requestPermission();
      AppUtilities.logger.d('New LocationPermission is: ${permission.name}');

    } catch (e) {
      AppUtilities.logger.e(e.toString());
    }

    return permission;

  }


  @override
  Future<Position> getCurrentPosition() async {

    bool serviceEnabled;
    LocationPermission permission;

    Position position = Position(longitude: 0, latitude: 0, timestamp: DateTime.now(),
        accuracy: 0, altitude: 0, heading: 0, speed: 0, speedAccuracy: 0, altitudeAccuracy: 1, headingAccuracy: 1);

    try {

      serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return Future.error('Location services are disabled.');
      }

      permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          Get.offAndToNamed(AppRouteConstants.introRequiredPermissions);
          Get.toNamed(AppRouteConstants.logout,
              arguments: [AppRouteConstants.logout, AppRouteConstants.login]);
          return Future.error('Location permissions are denied');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        Get.toNamed(AppRouteConstants.logout,
            arguments: [AppRouteConstants.logout, AppRouteConstants.login]);
        return Future.error('Location permissions are permanently denied,'
            ' we cannot request permissions.');
      }

      position = await Geolocator.getCurrentPosition();
      AppUtilities.logger.t("Position: ${position.toString()}");
    } catch (e) {
      AppUtilities.logger.e(e.toString());
    }

    return position;
  }


  @override
  Future<Position> updateLocation(String profileId, Position? currentPosition) async {
    AppUtilities.logger.t("Updating Location for ProfileId $profileId");

    Position newPosition = Position(longitude: 0, latitude: 0, timestamp: DateTime.now(),
        accuracy: 0, altitude: 0, heading: 0, speed: 0, speedAccuracy: 0, altitudeAccuracy: 1, headingAccuracy: 1);

    try {
      newPosition =  (await getCurrentPosition());
      if(currentPosition != null) {
        int distance = AppUtilities.distanceBetweenPositionsRounded(currentPosition, newPosition);
        if(distance > AppConstants.significantDistanceKM){
          AppUtilities.logger.t("GpsLocation would be updated as distance difference is significant");
          if(await ProfileFirestore().updatePosition(profileId, newPosition)){
            AppUtilities.logger.i("GpsLocation was updated as distance was significant ${distance}Kms");
          }
        } else {
          return currentPosition;
        }
      } else {
        if(await ProfileFirestore().updatePosition(profileId, newPosition)){
          AppUtilities.logger.i("GpsLocation was updated as there was no data for it");
        }
      }

    } catch (e) {
      AppUtilities.logger.e(e.toString());
    }

    AppUtilities.logger.d("updateLocation method Exit");
    return newPosition;
  }

}
