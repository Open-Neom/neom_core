import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:logger/logger.dart';
import 'package:path_provider/path_provider.dart';
import '../data/implementations/geolocator_controller.dart';
import 'app_color.dart';
import 'constants/app_route_constants.dart';
import 'constants/app_translation_constants.dart';

class AppUtilities {

  static final logger = Logger(
    printer: PrettyPrinter(
      methodCount: 5,
      errorMethodCount: 5,
      lineLength: 50,
      colors: true,
      printEmojis: true,
      printTime: false,
    )
  );

  static void showAlert(context, title,  message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppColor.getMain(),
          title: Text(title),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              child: Text(AppTranslationConstants.close.tr,
                style: const TextStyle(color: AppColor.white)
              ),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
          ],
        );
      },
    );
  }

  static void showSnackBar(String title, String message, {Duration duration = const Duration(seconds: 2)}) {
    Get.snackbar(title.tr, message.tr,
        snackPosition: SnackPosition.bottom,
        duration: duration
    );
  }

  static int distanceBetweenPositionsRounded(Position mainUserPos, Position refUserPos){

    int distanceKm = 0;
    try {
      double mainLatitude = mainUserPos.latitude;
      double mainLongitude = mainUserPos.longitude;
      double refLatitude = refUserPos.latitude;
      double refLongitude = refUserPos.longitude;

      int distanceInMeters = Geolocator.distanceBetween(mainLatitude, mainLongitude, refLatitude, refLongitude).round();
      logger.v("Distance between positions $distanceInMeters");

      distanceKm = (distanceInMeters / 1000).round();
    } catch (e) {
      logger.e(e.toString());
    }

    return distanceKm;
  }

  static double distanceBetweenPositions(Position mainUserPos, Position refUserPos){

    double mainLatitude = mainUserPos.latitude;
    double mainLongitude = mainUserPos.longitude;
    double refLatitude = refUserPos.latitude;
    double refLongitude = refUserPos.longitude;

    int distanceInMeters = Geolocator.distanceBetween(mainLatitude, mainLongitude, refLatitude, refLongitude).round();
    logger.v("Distance between positions $distanceInMeters");

    return (distanceInMeters / 1000);
  }

  static Future<String> getAddressFromPlacerMark(Position position) async {
    logger.d("");

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

    logger.d(address);
    return address;
  }

  static List<DateTime> getDaysFromNow({days = 21}){

    List<DateTime> dates = [];

    DateTime dateTimeNow = DateTime.now();
    dates.add(dateTimeNow);

    for( int nextDay = 1 ; nextDay <= days; nextDay++ ) {
      dates.add(dateTimeNow.add(Duration(days: nextDay)));
    }

    return dates;
  }

  static String getDurationInMinutes(int durationMs) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    Duration duration = Duration(milliseconds: durationMs);
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return "$twoDigitMinutes:$twoDigitSeconds";
  }

  static void goHome() {
    logger.d("");
    Get.offAllNamed(AppRouteConstants.home);
  }

  static String dateFormat(int dateMsSinceEpoch, {dateFormat = "dd-MM-yyyy"}) {
    String formattedDate = "";

    formattedDate = DateFormat(dateFormat)
        .format(DateTime.fromMillisecondsSinceEpoch(dateMsSinceEpoch));

    AppUtilities.logger.v("Date formatted to: $formattedDate");

    return formattedDate;
  }

  static String getNumberWithFormat(String number) {
    String numberWithFormat = "";
    if(number.length > 3) {
      NumberFormat formatter = NumberFormat('#,###,###');
      if(number.length == 4) {
        formatter = NumberFormat('#,###');
      } else if(number.length == 5) {
        formatter = NumberFormat('##,###');
      } else if(number.length == 6) {
        formatter = NumberFormat('###,###');
      }
      numberWithFormat = formatter.format(double.parse(number));
    } else {
      numberWithFormat = number;
    }

    AppUtilities.logger.d("Returning number $number with format as $numberWithFormat");
    return numberWithFormat;
  }

  static Future<File> getPdfFromUrl(String pdfUrl) async {
    logger.d("Start download file from internet!");
    File file = File("");
    String filename = "";
    try {
      filename = pdfUrl.substring(pdfUrl.lastIndexOf("/") + 1);
      var request = await HttpClient().getUrl(Uri.parse(pdfUrl));
      var response = await request.close();
      var bytes = await consolidateHttpClientResponseBytes(response);
      var dir = await getApplicationDocumentsDirectory();
      logger.d("Download files");
      logger.i("PDF Path: ${dir.path}/$filename");
      file = File("${dir.path}/$filename");
      await file.writeAsBytes(bytes, flush: true);
    } catch (e) {
      throw Exception('Error parsing asset file!');
    }

    return file;
  }

  static Future<File> getFileFromPath(String filePath) async {
    logger.d("Getting PDF File From Path");
    File file = File("");

    try {
      logger.i("File Path: $filePath");

      if(Platform.isAndroid) {
        file = File(filePath);
      } else {
        file = await File.fromUri(Uri.parse(filePath)).create();
      }

    } catch (e) {
      logger.e('Error getting File');
    }

    return file;
  }
}
