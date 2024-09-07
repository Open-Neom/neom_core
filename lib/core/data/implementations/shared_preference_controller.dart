
import 'package:enum_to_string/enum_to_string.dart';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/model/app_user.dart';
import '../../domain/use_cases/shared_preference_service.dart';
import '../../utils/app_utilities.dart';
import '../../utils/constants/app_shared_preference_constants.dart';
import '../../utils/enums/app_locale.dart';
import 'user_controller.dart';


class SharedPreferenceController extends GetxController implements SharedPreferenceService {

  final logger = AppUtilities.logger;
  final userController = Get.find<UserController>();

  late SharedPreferences prefs;

  bool firstTime = false;
  int lastNotificationCheckDate = 0;

  @override
  void onInit() async {
    super.onInit();
    logger.t("onInit Shared Preferences");
    await readLocal();
  }

  @override
  Future<void> readLocal() async {

    try {
      prefs = await SharedPreferences.getInstance();
      userController.user.name = prefs.getString(AppSharedPreferenceConstants.username) ?? '';
      userController.profile.id = prefs.getString(AppSharedPreferenceConstants.profileId) ?? '';
      userController.profile.aboutMe = prefs.getString(AppSharedPreferenceConstants.aboutMe) ?? '';
      userController.profile.photoUrl = prefs.getString(AppSharedPreferenceConstants.photoUrl) ?? '';
      firstTime = prefs.getBool(AppSharedPreferenceConstants.firstTime) ?? true;
      lastNotificationCheckDate = prefs.getInt(AppSharedPreferenceConstants.lastNotificationCheckDate) ?? 0;

      String appLocale = prefs.getString(AppSharedPreferenceConstants.appLocale) ?? '';

      if(appLocale.isNotEmpty) {
        setLocale(EnumToString.fromString(AppLocale.values, appLocale)!);
      } else {
        AppLocale appLocale = AppLocale.spanish;

        switch(Get.locale?.languageCode ?? "") {
          case "es":
            appLocale = AppLocale.spanish;
            break;
          case "en":
            appLocale = AppLocale.english;
            break;
          case "":
            break;

        }
        setLocale(appLocale);
        updateLocale(appLocale);
      }
    } catch(e) {
      logger.e(e.toString());
    }
  }

  @override
  Future<void> writeLocal() async {
    AppUser currentUser = userController.user;
    await prefs.setString(AppSharedPreferenceConstants.userId, currentUser.id);
    await prefs.setString(AppSharedPreferenceConstants.profileId, userController.profile.id);
    await prefs.setString(AppSharedPreferenceConstants.username, currentUser.name);
    await prefs.setString(AppSharedPreferenceConstants.photoUrl, currentUser.photoUrl);
    await prefs.setBool(AppSharedPreferenceConstants.firstTime, false);
  }

  @override
  Future<void> updateFirstTIme(bool isFirstTime) async {
    await prefs.setBool(AppSharedPreferenceConstants.firstTime, isFirstTime);
  }


  @override
  Future<void> updateLocale(AppLocale appLocale) async {
    logger.d("Setting locale preference to ${appLocale.name}");

    try {
      await prefs.setString(AppSharedPreferenceConstants.appLocale, appLocale.name);
      setLocale(appLocale);
    } catch (e) {
      logger.e(e.toString());
    }

  }

  @override
  Future<void> setFirstTime(bool fTime) async {
    logger.t("Setting firsTime to $firstTime");

    try {
      firstTime = fTime;
      await prefs.setBool(AppSharedPreferenceConstants.firstTime, fTime);
    } catch (e) {
      logger.e(e.toString());
    }

  }

  @override
  void setLocale(AppLocale appLocale) {

    Locale locale = Get.deviceLocale!;

    switch(appLocale) {
      case AppLocale.english:
        locale = const Locale('en');
        break;
      case AppLocale.spanish:
        locale = const Locale('es');
        break;
      case AppLocale.french:
        locale = const Locale('fr');
        break;
      case AppLocale.deutsch:
        locale = const Locale('de');
        break;
    }

    Get.updateLocale(locale);

  }


  Future<void> setLastNotificationCheckDate(int lastNotificationCheckDate) async {
    logger.d("Setting last time notification were checked");

    try {
      lastNotificationCheckDate = lastNotificationCheckDate;
      await prefs.setInt(AppSharedPreferenceConstants.lastNotificationCheckDate, lastNotificationCheckDate);
    } catch (e) {
      logger.e(e.toString());
    }

  }

}
