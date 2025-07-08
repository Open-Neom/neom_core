import 'dart:async';

import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

import '../../app_config.dart';
import '../../domain/use_cases/geolocator_service.dart';
import '../../utils/constants/core_constants.dart';
import '../../utils/position_utilities.dart';
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
      AppConfig.logger.e(e.toString());
    }

    return placeMark;
  }

  Future<List<Placemark>> getMultiplePlacemarks(List<Position> positions) async {
    List<Future<Placemark>> placemarkFutures = positions.map((pos) {
      return getPlaceMark(pos);
    }).toList();
    return await Future.wait(placemarkFutures);
  }

  @override
  Future<String> getAddressSimple(Position currentPos) async {
    AppConfig.logger.t(currentPos.toString());
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
      AppConfig.logger.e(e.toString());
    }


    AppConfig.logger.t(address);
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
      AppConfig.logger.d('Current LocationPermission is: ${permission.name}');

      permission = await Geolocator.requestPermission();
      AppConfig.logger.d('New LocationPermission is: ${permission.name}');

    } catch (e) {
      AppConfig.logger.e(e.toString());
    }

    return permission;

  }


  @override
  Future<Position?> getCurrentPosition() async {

    bool serviceEnabled;
    LocationPermission permission;

    Position? position;

    try {
      serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return Future.error('Location services are disabled.');
      }

      permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          // Get.offAndToNamed(AppRouteConstants.introRequiredPermissions);
          // Get.toNamed(AppRouteConstants.logout,
          //     arguments: [AppRouteConstants.logout, AppRouteConstants.login]);
          // return Future.error('Location permissions are denied');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        // position = null;
        ///DEPRECATED
        // Get.toNamed(AppRouteConstants.logout,
        //     arguments: [AppRouteConstants.logout, AppRouteConstants.login]);
        // return Future.error('Location permissions are permanently denied,'
        //     ' we cannot request permissions.');
      } else {
        position = await Geolocator.getCurrentPosition();
      }

      AppConfig.logger.t("Position: ${position.toString()}");
    } catch (e) {
      AppConfig.logger.e(e.toString());
    }

    return position;
  }


  @override
  Future<Position?> updateLocation(String profileId, Position? currentPosition) async {
    AppConfig.logger.t("Updating Location for ProfileId $profileId");

    Position? newPosition = Position(longitude: 0, latitude: 0, timestamp: DateTime.now(),
        accuracy: 0, altitude: 0, heading: 0, speed: 0, speedAccuracy: 0, altitudeAccuracy: 1, headingAccuracy: 1);

    try {
      newPosition =  (await getCurrentPosition());
      if(currentPosition != null && newPosition != null) {
        int distance = PositionUtilities.distanceBetweenPositionsRounded(currentPosition, newPosition);
        if(distance > CoreConstants.significantDistanceKM){
          AppConfig.logger.t("GpsLocation would be updated as distance difference is significant");
          if(await ProfileFirestore().updatePosition(profileId, newPosition)){
            AppConfig.logger.i("GpsLocation was updated as distance was significant ${distance}Kms");
          }
        } else {
          return currentPosition;
        }
      } else if(newPosition != null) {
        if(await ProfileFirestore().updatePosition(profileId, newPosition)){
          AppConfig.logger.i("GpsLocation was updated as there was no data for it");
        }
      }
    } catch (e) {
      AppConfig.logger.e(e.toString());
    }

    AppConfig.logger.d("updateLocation method Exit");
    return newPosition;
  }

  Future<List<String>> getNearbySimpleAddresses(Position currentPos, {int numberOfSuggestions = 10}) async {
    List<String> addresses = [];

    try {
      if (currentPos.latitude == 0 || currentPos.longitude == 0) return addresses;

      double offset = 0.020; // ~2000 metros, puedes ajustar
      List<Future<String>> futures = [];

      // Genera posiciones ligeramente desplazadas alrededor del punto original
      for (int i = 0; i < numberOfSuggestions; i++) {
        double latOffset = (i % 2 == 0 ? offset : -offset) * (i / 2).ceil();
        double lngOffset = (i % 3 == 0 ? offset : -offset) * (i / 3).ceil();

        futures.add(getAddressSimple(Position(
          latitude: currentPos.latitude + latOffset,
          longitude: currentPos.longitude + lngOffset,
          timestamp: DateTime.now(),
          accuracy: 0,
          altitude: 0,
          heading: 0,
          speed: 0,
          speedAccuracy: 0,
          altitudeAccuracy: 0,
          headingAccuracy: 0,
        )));
      }

      // Espera a obtener todas las direcciones
      addresses = await Future.wait(futures);

      // Eliminar direcciones duplicadas
      addresses = addresses.toSet().toList();

    } catch (e) {
      AppConfig.logger.e(e.toString());
    }

    return addresses;
  }


}
