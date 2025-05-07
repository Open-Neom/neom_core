import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:logger/logger.dart';
import 'package:path_provider/path_provider.dart';

import '../../neom_commons.dart';
import 'enums/itemlist_type.dart';

class AppUtilities {

  ///Logger to log different types of events within the app.
  ///i - info | d - debug | w - warning - | e - error | t - trace
  static final logger = Logger();

  /// Returns the sha256 hash of [input] in hex notation.
  static String sha256ofString(String input) {
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  static String generateNonce([int length = 32]) {
    const charset = '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();
    return List.generate(length, (_) => charset[random.nextInt(charset.length)])
        .join();
  }

  static void showAlert(BuildContext context, {String title = '',  String message = ''}) {
    if(title.isEmpty) title = AppFlavour.getAppName();
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

  static void showSnackBar({String title = '', String message = '', Duration duration = const Duration(seconds: 3)}) {
    if(title.isEmpty) title = AppFlavour.getAppName();
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
      logger.t("Distance between positions $distanceInMeters");

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
    logger.t("Distance between positions $distanceInMeters");

    return (distanceInMeters / 1000);
  }

  static Future<String> getAddressFromPlacerMark(Position position) async {
    logger.t("getAddressFromPlacerMark");

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

    logger.t(address);
    return address;
  }

  static Future<List<String>> getAddressesFromPositions(List<Position> positions) async {
    logger.d("Getting Addresses from ${positions.length} positions");

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

  static List<DateTime> getDaysFromNow({days = 28}){

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

    AppUtilities.logger.t("Date formatted to: $formattedDate");

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
    logger.d("getPdfFromUrl $pdfUrl");
    File file = File("");
    String filename = "";
    try {
      filename = pdfUrl.substring(pdfUrl.lastIndexOf("/") + 1);
      var request = await HttpClient().getUrl(Uri.parse(pdfUrl));
      var response = await request.close();
      var bytes = await consolidateHttpClientResponseBytes(response);
      var dir = await getApplicationDocumentsDirectory();
      logger.d("File loaded and buffered");
      logger.i("PDF Path: ${dir.path}/$filename");
      file = File("${dir.path}/$filename");
      await file.writeAsBytes(bytes, flush: true);
    } catch (e) {
      throw Exception('Error parsing asset file!');
    }

    return file;
  }

  static Future<File> getFileFromPath(String filePath) async {
    logger.d("Getting File From Path: $filePath");
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

  static String secondsToMinutes(int seconds, {bool clockView = true}) {
    // Calculate the number of minutes and remaining seconds
    int minutes = seconds ~/ 60;
    int remainingSeconds = seconds % 60;

    // Format the minutes and seconds as two-digit strings
    String minutesStr = minutes.toString().padLeft(2, '0');
    String secondsStr = remainingSeconds.toString().padLeft(2, '0');

    // Create the formatted string
    String formattedTime = '';

    if(clockView) {
      formattedTime = '$minutesStr:$secondsStr';
    } else {
      formattedTime = '$minutesStr ${AppTranslationConstants.minutes.tr} - $secondsStr ${AppTranslationConstants.seconds.tr}';
    }


    return formattedTime;
  }

  static bool isDeviceSupportedVersion({bool isIOS = false}){
    logger.i(Platform.operatingSystemVersion);
    if(isIOS) {
      return Platform.operatingSystemVersion.contains('13')
          || Platform.operatingSystemVersion.contains('14')
          || Platform.operatingSystemVersion.contains('15')
          || Platform.operatingSystemVersion.contains('16')
          || Platform.operatingSystemVersion.contains('17');
    } else {
      return true;
    }
  }

  static bool isWithinLastSevenDays(int date) {
    DateTime dateTime = DateTime.fromMillisecondsSinceEpoch(date);
    DateTime now = DateTime.now();
    Duration difference = now.difference(dateTime);
    return difference.inDays < 7;
  }

  static bool isWithinFirstMonth(int createdTime) {
    DateTime creationDate = DateTime.fromMillisecondsSinceEpoch(createdTime);
    DateTime now = DateTime.now();

    DateTime dateOneMonthLater = DateTime(
      creationDate.year,
      creationDate.month + 1,
      creationDate.day,
    );

    return now.isBefore(dateOneMonthLater);
  }


  ///DEPRECATED
  // ///Stopwatch to measure execution time of tasks
  // static final _stopwatch = Stopwatch();
  // static String _stopWatchReference = '';
  //
  // /// Starts the stopwatch
  // static void startStopwatch({String reference = ''}) {
  //   _stopWatchReference = reference;
  //   if(!_stopwatch.isRunning) {
  //     logger.i('Starting stopwatch for $_stopWatchReference.');
  //     _stopwatch.start();
  //   } else {
  //     logger.i('Instance of stopwatch is running for $_stopWatchReference.');
  //   }
  // }
  //
  // /// Stops the stopwatch, logs the execution time, and resets the stopwatch
  // static void stopStopwatch() {
  //   _stopwatch.stop();
  //   if(_stopWatchReference.isNotEmpty) {
  //     logger.i('Execution Time: ${_stopwatch.elapsedMilliseconds} ms for $_stopWatchReference');
  //     _stopWatchReference = '';
  //   } else {
  //     logger.i('Execution Time: ${_stopwatch.elapsedMilliseconds} ms');
  //   }
  //
  //   _stopwatch.reset();
  //
  // }

  static List<DropdownMenuItem<String>> buildDropDownMenuItemlists(List<Itemlist> itemlists) {

    List<DropdownMenuItem<String>> menuItems = [];

    for (Itemlist list in itemlists) {
      menuItems.add(
          DropdownMenuItem<String>(
            value: list.id,
            child: Center(
                child: Text(
                    list.name.length > AppConstants.maxItemlistNameLength
                        ? "${list.name
                        .substring(0,AppConstants.maxItemlistNameLength).capitalizeFirst}..."
                        : list.name.capitalizeFirst)
            ),
          )
      );
    }

    return menuItems;
  }

  static String getArtistName(String artistMediaTitle) {

    String artistName = '';
    List<String> mediaNameSplitted = artistMediaTitle.split("-");

    if(mediaNameSplitted.isNotEmpty) {
      artistName = mediaNameSplitted.first.trim();
    }

    return artistName;
  }

  static String getMediaName(String artistMediaTitle) {

    String mediaName = '';
    List<String> mediaNameSplitted = artistMediaTitle.split("-");

    if(mediaNameSplitted.isNotEmpty && mediaNameSplitted.length == 1) {
      mediaName = mediaNameSplitted.last.trim();
    } else {
      List<String> partsAfterFirst = mediaNameSplitted.sublist(1).map((part) => part.trim()).toList();
      mediaName = partsAfterFirst.join(' - ');
    }

    return mediaName;
  }

  static List<Itemlist> filterItemlists(List<Itemlist> lists, ItemlistType type) {
    if(lists.isEmpty) return [];

    switch(type) {
      case ItemlistType.playlist:
        lists.removeWhere((list) => list.type == ItemlistType.readlist);
        lists.removeWhere((list) => list.type == ItemlistType.giglist);
        break;
      case ItemlistType.readlist:
        lists.removeWhere((list) => list.type != ItemlistType.readlist);
      default:
        break;
    }

    return lists;
  }

  static bool isInternal(String url) {
    final bool isInternal = url.contains(AppFlavour.getHubName())
        || url.contains(AppFlavour.getStorageServerName());
    return isInternal;
  }

  static Future<bool?> showConfirmationDialog(
      BuildContext context, {
        String title = '',
        String message = '',
        String textConfirm = 'OK', // Default text for confirm button
        String textCancel = 'Cancel', // Default text for cancel button
      }) async {
    if (title.isEmpty) title = AppFlavour.getAppName(); // Use default app name if title is empty

    return showDialog<bool?>( // Specify the return type of showDialog
      context: context,
      barrierDismissible: false, // User must tap button!
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppColor.getMain(), // Consistent with showAlert
          title: Text(title),
          content: Text(message),
          actions: <Widget>[
            // Cancel Button
            TextButton(
              child: Text(
                textCancel,
                style: const TextStyle(color: AppColor.white), // White text color
              ),
              onPressed: () {
                Navigator.of(context).pop(false); // Return false when cancelled
              },
            ),
            // Confirm Button
            TextButton(
              child: Text(
                textConfirm,
                style: const TextStyle(color: AppColor.white), // White text color
              ),
              onPressed: () {
                Navigator.of(context).pop(true); // Return true when confirmed
              },
            ),
          ],
        );
      },
    );
  }

  /// Normaliza una cadena, quitando acentos y caracteres especiales comunes.
  static String normalizeString(String input) {
    // Mapa de caracteres acentuados y especiales a sus equivalentes sin acento.
    const Map<String, String> accentMap = {
      'á': 'a', 'é': 'e', 'í': 'i', 'ó': 'o', 'ú': 'u',
      'Á': 'A', 'É': 'E', 'Í': 'I', 'Ó': 'O', 'Ú': 'U',
      'à': 'a', 'è': 'e', 'ì': 'i', 'ò': 'o', 'ù': 'u',
      'À': 'A', 'È': 'E', 'Ì': 'I', 'Ò': 'O', 'Ù': 'U',
      'â': 'a', 'ê': 'e', 'î': 'i', 'ô': 'o', 'û': 'u',
      'Â': 'A', 'Ê': 'E', 'Î': 'I', 'Ô': 'O', 'Û': 'U',
      'ä': 'a', 'ë': 'e', 'ï': 'i', 'ö': 'o', 'ü': 'u',
      'Ä': 'A', 'Ë': 'E', 'Ï': 'I', 'Ö': 'O', 'Ü': 'U',
      'ñ': 'n', 'Ñ': 'N',
      'ç': 'c', 'Ç': 'C',
    };

    String normalized = input;
    // Reemplazar cada carácter acentuado con su equivalente sin acento.
    accentMap.forEach((key, value) {
      normalized = normalized.replaceAll(key, value);
    });

    // Opcional: quitar otros caracteres no alfanuméricos si es necesario para el código del cupón.
    // Por ejemplo, para permitir solo letras y números:
    // normalized = normalized.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '');

    return normalized;
  }

}
