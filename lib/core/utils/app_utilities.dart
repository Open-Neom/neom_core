import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:intl/intl.dart';
import 'package:logger/logger.dart';
import 'package:path_provider/path_provider.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../../neom_commons.dart';

class AppUtilities {

  ///Logger to log different types of events within the app.
  ///i - info | d - debug | w - warning - | e - error | t - trace
  static final logger = Logger();

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

  static String getTimeAgo(int createdTime, {showShort = true}) {

    Locale? locale;

    if(!showShort) locale = Get.locale;

    return timeago.format(
        DateTime.fromMillisecondsSinceEpoch(createdTime),
        locale: locale?.languageCode ?? 'en_short'
    );
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

  static Future<File> cropImage(XFile mediaFile, {double ratioX = 1, double ratioY = 1}) async {
    AppUtilities.logger.d("Initializing Image Cropper");

    File croppedImageFile = File("");
    try {
      CroppedFile? croppedFile = await ImageCropper().cropImage(
        sourcePath: mediaFile.path,
        aspectRatio: CropAspectRatio(
            ratioX: ratioX,
            ratioY: ratioY
        ),
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: AppTranslationConstants.adjustImage.tr,
            backgroundColor: AppColor.getMain(),
            toolbarColor: AppColor.getMain(),
            toolbarWidgetColor: AppColor.white,
            statusBarColor: AppColor.getMain(),
            dimmedLayerColor: AppColor.main50,
            activeControlsWidgetColor: AppColor.yellow,
            aspectRatioPresets: [
              CropAspectRatioPreset.square,
              CropAspectRatioPreset.ratio3x2,
              CropAspectRatioPreset.original,
              CropAspectRatioPreset.ratio4x3,
              CropAspectRatioPreset.ratio16x9
            ],
              // initAspectRatio: CropAspectRatioPreset.square,

          ),
          IOSUiSettings(
            title: AppTranslationConstants.adjustImage.tr,
            cancelButtonTitle: AppTranslationConstants.cancel.tr,
            doneButtonTitle: AppTranslationConstants.done.tr,
            minimumAspectRatio: 1.0,
            showCancelConfirmationDialog: true,
            aspectRatioLockEnabled: true,
            aspectRatioPresets: [
              CropAspectRatioPreset.square,
              CropAspectRatioPreset.ratio3x2,
              CropAspectRatioPreset.original,
              CropAspectRatioPreset.ratio4x3,
              CropAspectRatioPreset.ratio16x9
            ],
          )
        ],
      );

      croppedImageFile = File(croppedFile?.path ?? "");


    } catch (e) {
      AppUtilities.logger.e(e.toString());
    }
    AppUtilities.logger.d("Cropped Image in file ${croppedImageFile.path}");

    return croppedImageFile;
  }

  static Future<XFile> compressImageFile(XFile imageFile) async {

    XFile compressedImageFile = XFile('');
    CompressFormat compressFormat = CompressFormat.jpeg;

    try {
      ///DEPRECATED final lastIndex = imageFile.path.lastIndexOf(RegExp(r'.jp'));
      final lastIndex = imageFile.path.lastIndexOf(RegExp(r'\.jp|\.png'));


      if(lastIndex >= 0) {
        String subPath = imageFile.path.substring(0, (lastIndex));
        String fileFormat = imageFile.path.substring(lastIndex);

        if(fileFormat.contains(CompressFormat.png.name)){
          compressFormat = CompressFormat.png;
        }

        String outPath = "${subPath}_out$fileFormat";
        XFile? result = await FlutterImageCompress.compressAndGetFile(imageFile.path, outPath, format: compressFormat);

        if(result != null) {
          compressedImageFile = result;
          AppUtilities.logger.d("Image compressed successfully");
        } else {
          compressedImageFile = imageFile;
          AppUtilities.logger.w("Image was not compressed and return as before");
        }
      }
    } catch(e) {
      AppUtilities.logger.e(e.toString());
    }


    return compressedImageFile;
  }

  static bool isWithinLastSevenDays(int date) {
    DateTime dateTime = DateTime.fromMillisecondsSinceEpoch(date);
    DateTime now = DateTime.now();
    Duration difference = now.difference(dateTime);
    return difference.inDays < 7;
  }

  ///Stopwatch to measure execution time of tasks
  static final _stopwatch = Stopwatch();
  static String _stopWatchReference = '';

  /// Starts the stopwatch
  static void startStopwatch({String reference = ''}) {
    if(!_stopwatch.isRunning) {
      _stopwatch.start();
      _stopWatchReference = reference;
    } else {
      logger.i('Instance of stopwatch is running for $_stopWatchReference.');
    }
  }

  /// Stops the stopwatch, logs the execution time, and resets the stopwatch
  static void stopStopwatch() {
    _stopwatch.stop();
    if(_stopWatchReference.isNotEmpty) {
      logger.i('Execution Time: ${_stopwatch.elapsedMilliseconds} ms for $_stopWatchReference');
      _stopWatchReference = '';
    } else {
      logger.i('Execution Time: ${_stopwatch.elapsedMilliseconds} ms');
    }

    _stopwatch.reset();

  }

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

}
