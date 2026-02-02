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
          // Sint.offAndToNamed(AppRouteConstants.introRequiredPermissions);
          // Sint.toNamed(AppRouteConstants.logout,
          //     arguments: [AppRouteConstants.logout, AppRouteConstants.login]);
          // return Future.error('Location permissions are denied');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        // position = null;
        ///DEPRECATED
        // Sint.toNamed(AppRouteConstants.logout,
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

  final Set<String> areaSuggestions = {};

  Future<List<String>> getNearbySimpleAddresses(Position currentPos, {int numberOfSuggestions = 10}) async {
    List<String> addresses = [];

    try {
      if (currentPos.latitude == 0 || currentPos.longitude == 0) return addresses;

      // 1. Obtener la ubicación ACTUAL (Prioridad Alta)
      await _addPlaceToSet(currentPos, areaSuggestions);

      // 2. Exploración de Vecinos (Cross Search)
      // Nos movemos ~5km (0.045 grados aprox) en 4 direcciones para encontrar municipios colindantes.
      // Esto es secuencial para no bloquear la API.
      double offset = 0.045;

      // Lista de desplazamientos: [Norte, Sur, Este, Oeste]
      List<List<double>> directions = [
        [offset, 0],   // Norte
        [-offset, 0],  // Sur
        [0, offset],   // Este
        [0, -offset],  // Oeste
      ];

      for (var dir in directions) {
        if (areaSuggestions.length >= 6) break;

        Position searchPos = Position(
          latitude: currentPos.latitude + dir[0],
          longitude: currentPos.longitude + dir[1],
          timestamp: DateTime.now(), accuracy: 0, altitude: 0, heading: 0, speed: 0, speedAccuracy: 0, altitudeAccuracy: 0, headingAccuracy: 0,
        );

        await _addPlaceToSet(searchPos, areaSuggestions);
      }

    } catch (e) {
      AppConfig.logger.e(e.toString());
    }

    return areaSuggestions.toList();

  }

  // Método auxiliar privado para extraer solo Ciudad/Municipio y agregarlo al Set
  Future<void> _addPlaceToSet(Position pos, Set<String> suggestions) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(pos.latitude, pos.longitude);

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks.first;

        // 1. Intentar obtener el nombre del lugar (Ej. "Andares", "Centro Magno")
        // A veces 'name' es solo el número de calle, así que validamos que no sea dígito.
        if (place.name != null && place.name!.isNotEmpty && int.tryParse(place.name!) == null) {
          // Filtramos nombres muy cortos o genéricos si es necesario
          if(place.name!.length > 3) suggestions.add(place.name!);
        }

        // Prioridad 1: Locality (Ciudad/Municipio principal, ej: "Guadalajara")
        if (place.locality != null && place.locality!.isNotEmpty) {
          suggestions.add(place.locality!);
        }

        // Prioridad 2: SubAdministrativeArea (A veces contiene el municipio si locality es el barrio)
        if (place.subAdministrativeArea != null && place.subAdministrativeArea!.isNotEmpty) {
          // Solo agregamos si es diferente a lo que ya tenemos (el Set lo maneja, pero por claridad)
          suggestions.add(place.subAdministrativeArea!);
        }

        //Opcional: Si quieres barrios populares (ej. "Colonia Americana")
        if (place.subLocality != null && place.subLocality!.isNotEmpty) {
          suggestions.add(place.subLocality!);
        }
      }
    } catch (e) {
      // Si un punto cae en medio de la nada, simplemente lo ignoramos y seguimos
      AppConfig.logger.d("No address found for coordinates: $pos");
    }
  }

}
