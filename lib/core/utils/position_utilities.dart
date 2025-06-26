import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

import '../app_config.dart';
import '../data/implementations/geolocator_controller.dart';

class PositionUtilities {

  static int distanceBetweenPositionsRounded(Position mainUserPos, Position refUserPos){

    int distanceKm = 0;
    try {
      double mainLatitude = mainUserPos.latitude;
      double mainLongitude = mainUserPos.longitude;
      double refLatitude = refUserPos.latitude;
      double refLongitude = refUserPos.longitude;

      int distanceInMeters = Geolocator.distanceBetween(mainLatitude, mainLongitude, refLatitude, refLongitude).round();
      AppConfig.logger.t("Distance between positions $distanceInMeters");

      distanceKm = (distanceInMeters / 1000).round();
    } catch (e) {
      AppConfig.logger.e(e.toString());
    }

    return distanceKm;
  }

  static double distanceBetweenPositions(Position mainUserPos, Position refUserPos){

    double mainLatitude = mainUserPos.latitude;
    double mainLongitude = mainUserPos.longitude;
    double refLatitude = refUserPos.latitude;
    double refLongitude = refUserPos.longitude;

    int distanceInMeters = Geolocator.distanceBetween(mainLatitude, mainLongitude, refLatitude, refLongitude).round();
    AppConfig.logger.t("Distance between positions $distanceInMeters");

    return (distanceInMeters / 1000);
  }

  static Future<String> getAddressFromPlacerMark(Position position) async {
    AppConfig.logger.t("getAddressFromPlacerMark");

    Placemark placeMark = await GeoLocatorController().getPlaceMark(position);
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

    AppConfig.logger.t(address);
    return address;
  }

  static Future<List<String>> getAddressesFromPositions(List<Position> positions) async {
    AppConfig.logger.d("Getting Addresses from ${positions.length} positions");

    List<String> addresses = [];
    List<Placemark> placemarks = await GeoLocatorController().getMultiplePlacemarks(positions);

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

}
