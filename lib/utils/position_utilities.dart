import 'package:geolocator/geolocator.dart';

import 'neom_logger.dart';
import '../domain/model/address.dart';
import 'neom_error_logger.dart';
import 'platform/core_geocoding.dart';

class PositionUtilities {

  static int distanceBetweenPositionsRounded(Position mainUserPos, Position refUserPos){

    int distanceKm = 0;
    try {
      double mainLatitude = mainUserPos.latitude;
      double mainLongitude = mainUserPos.longitude;
      double refLatitude = refUserPos.latitude;
      double refLongitude = refUserPos.longitude;

      int distanceInMeters = Geolocator.distanceBetween(mainLatitude, mainLongitude, refLatitude, refLongitude).round();
      neomLogger.t("Distance between positions $distanceInMeters");

      distanceKm = (distanceInMeters / 1000).round();
    } catch (e, st) {
      NeomErrorLogger.recordError(e, st, module: 'neom_core', operation: 'distanceBetweenPositionsRounded');
    }

    return distanceKm;
  }

  static double distanceBetweenPositions(Position mainUserPos, Position refUserPos){

    double mainLatitude = mainUserPos.latitude;
    double mainLongitude = mainUserPos.longitude;
    double refLatitude = refUserPos.latitude;
    double refLongitude = refUserPos.longitude;

    int distanceInMeters = Geolocator.distanceBetween(mainLatitude, mainLongitude, refLatitude, refLongitude).round();
    neomLogger.t("Distance between positions $distanceInMeters");

    return (distanceInMeters / 1000);
  }

  static Future<Placemark> _getPlaceMark(Position currentPos) async {
    Placemark placeMark = const Placemark();
    try {
      if (currentPos.latitude != 0 && currentPos.longitude != 0) {
        List<Placemark> placeMarks = await placemarkFromCoordinates(currentPos.latitude, currentPos.longitude);
        if (placeMarks.isNotEmpty) {
          placeMark = placeMarks.first;
        }
      }
    } catch (e, st) {
      NeomErrorLogger.recordError(e, st, module: 'neom_core', operation: '_getPlaceMark');
    }
    return placeMark;
  }

  static Future<String> getFormattedAddressFromPosition(Position position) async {
    neomLogger.t("getAddressFromPlacerMark for position: $position");

    Placemark placeMark = await _getPlaceMark(position);
    String country = placeMark.country ?? "";
    String locality = placeMark.locality ?? "";
    String address = "";

    if(locality.isNotEmpty && country.isNotEmpty) {
      address = "$locality, $country";
    } else if(locality.isNotEmpty) {
      address = locality;
    } else if (country.isNotEmpty) {
      address = country;
    }

    neomLogger.t(address);
    return address;
  }

  static Future<List<String>> getAddressesFromPositions(List<Position> positions) async {
    neomLogger.d("Getting Addresses from ${positions.length} positions");

    List<Future<Placemark>> placemarkFutures = positions.map((pos) {
      return _getPlaceMark(pos);
    }).toList();
    List<Placemark> placemarks = await Future.wait(placemarkFutures);

    List<String> addresses = [];
    for(Placemark placemark in placemarks) {
      String country = placemark.country ?? "";
      String locality = placemark.locality ?? "";
      String address = "";

      if(locality.isNotEmpty && country.isNotEmpty) {
        address = "$locality, $country";
      } else if(locality.isNotEmpty) {
        address = locality;
      } else if (country.isNotEmpty) {
        address = country;
      }
      if(address.isNotEmpty) addresses.add(address);
    }

    return addresses;
  }

  static Future<List<String>> getLocationSuggestions(Position position, {bool includeCurrentPosition = true}) async {
    neomLogger.d("Getting location suggestions for position: $position");

    List<String> suggestions = await _getNearbySimpleAddresses(position);

    if(includeCurrentPosition) {
      Position? currentPosition = await _getCurrentPosition();

      if(currentPosition != null) {
        String currentAddress = await _getAddressSimple(currentPosition);
        if(!suggestions.contains(currentAddress)) {
          suggestions.add(currentAddress);
        }
      }
    }

    return suggestions;
  }

  static Future<Address> getAddressFromPosition(Position position) async {
    neomLogger.d("Getting address from position: $position");

    Placemark placeMark = await _getPlaceMark(position);

    return Address(
        country: placeMark.country ?? "",
        state: placeMark.locality ?? "",
        zipCode: placeMark.postalCode ?? "",
        city: placeMark.subLocality ?? "",
        street: placeMark.street ?? ""
    );
  }

  static Future<Address> getAddressFromFormattedAddress(String formattedAddress) async {
    neomLogger.d("Getting address from formatted address: $formattedAddress");

    List<Location> locations = await locationFromAddress(formattedAddress);

    if (locations.isEmpty) {
      return Address();
    }

    Location firstLocation = locations.first;
    Position position = Position(
      latitude: firstLocation.latitude,
      longitude: firstLocation.longitude,
      timestamp: DateTime.now(),
      accuracy: 0.0,
      altitude: 0.0,
      heading: 0.0,
      speed: 0.0,
      speedAccuracy: 0.0,
      altitudeAccuracy: 0.0,
      headingAccuracy: 0.0,
    );

    return await getAddressFromPosition(position);
  }

  static Future<Position?> _getCurrentPosition() async {
    try {
      return await Geolocator.getCurrentPosition();
    } catch (e, st) {
      NeomErrorLogger.recordError(e, st, module: 'neom_core', operation: '_getCurrentPosition');
      return null;
    }
  }

  static Future<String> _getAddressSimple(Position currentPos) async {
    String address = "";
    try {
      if (currentPos.latitude != 0) {
        List<Placemark> placeMarks = await placemarkFromCoordinates(currentPos.latitude, currentPos.longitude);
        if (placeMarks.isNotEmpty) {
          Placemark placeMark = placeMarks[0];
          String locality = placeMark.locality ?? "";
          String administrativeArea = placeMark.administrativeArea ?? "";
          String country = placeMark.country ?? "";

          if (country.isNotEmpty) {
            locality.isNotEmpty
                ? address = "$locality, $country"
                : address = "$administrativeArea, $country";
          }
        }
      }
    } catch (e, st) {
      NeomErrorLogger.recordError(e, st, module: 'neom_core', operation: '_getAddressSimple');
    }
    return address;
  }

  static Future<List<String>> _getNearbySimpleAddresses(Position currentPos, {int numberOfSuggestions = 10}) async {
    final Set<String> areaSuggestions = {};

    try {
      if (currentPos.latitude == 0 || currentPos.longitude == 0) return [];

      await _addPlaceToSet(currentPos, areaSuggestions);

      double offset = 0.045;
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
          timestamp: DateTime.now(), accuracy: 0.0, altitude: 0.0, heading: 0.0, speed: 0.0, speedAccuracy: 0.0, altitudeAccuracy: 0.0, headingAccuracy: 0.0,
        );

        await _addPlaceToSet(searchPos, areaSuggestions);
      }
    } catch (e, st) {
      NeomErrorLogger.recordError(e, st, module: 'neom_core', operation: '_getNearbySimpleAddresses');
    }

    return areaSuggestions.toList();
  }

  static Future<void> _addPlaceToSet(Position pos, Set<String> suggestions) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(pos.latitude, pos.longitude);

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks.first;

        if (place.name != null && place.name!.isNotEmpty && int.tryParse(place.name!) == null) {
          if (place.name!.length > 3) suggestions.add(place.name!);
        }

        if (place.locality != null && place.locality!.isNotEmpty) {
          suggestions.add(place.locality!);
        }

        if (place.subAdministrativeArea != null && place.subAdministrativeArea!.isNotEmpty) {
          suggestions.add(place.subAdministrativeArea!);
        }

        if (place.subLocality != null && place.subLocality!.isNotEmpty) {
          suggestions.add(place.subLocality!);
        }
      }
    } catch (e) {
      // Ignore
    }
  }

}
