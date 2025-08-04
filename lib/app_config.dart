import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:logger/logger.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'data/firestore/app_info_firestore.dart';
import 'data/implementations/app_hive_controller.dart';
import 'domain/model/app_info.dart';
import 'domain/model/item_list.dart';
import 'domain/use_cases/login_service.dart';
import 'domain/use_cases/user_service.dart';
import 'utils/enums/app_in_use.dart';
import 'utils/enums/auth_status.dart';
import 'utils/enums/itemlist_type.dart';

class AppConfig {

  static final logger = Logger();

  static final AppConfig _instance = AppConfig._internal();
  static AppConfig get instance => _instance;
  AppConfig._internal();

  bool _isInitialized = false;

  AppInUse appInUse = AppInUse.o;
  String appVersion = '';
  int buildNumber = 0;

  AppInfo appInfo = AppInfo();
  String lastStableVersion = '';
  int lastStableBuild = 0;

  Rx<AuthStatus> authStatus = AuthStatus.notDetermined.obs;

  Map<String, Itemlist> releaseItemlists = {};
  ItemlistType defaultItemlistType = ItemlistType.playlist;

  /// Inicialización manual para controlar mejor el ciclo de vida
  Future<void> initialize({required AppInUse app}) async {
    if (_isInitialized) return;
    _isInitialized = true;

    logger.t("AppConfig Initialization");

    try {
      appInUse = app;
      getAppInfo();
      loadPackageInfo();
      if(app == AppInUse.e) {
        defaultItemlistType = ItemlistType.readlist;
      }
    } catch (e) {
      logger.e(e.toString());
    }
  }

  Future<void> getAppInfo() async {
    if(Firebase.apps.isNotEmpty) {
      appInfo = await AppInfoFirestore().retrieve();
      lastStableVersion = appInfo.version;
      lastStableBuild = appInfo.build;
      logger.i(appInfo.toString());
    } else {
      logger.w("Firebase not initialized, cannot retrieve app info.");
      lastStableVersion = "0.0.0";
      lastStableBuild = 0;
    }

  }

  Future<void> loadPackageInfo() async {
    PackageInfo info = await PackageInfo.fromPlatform();
    appVersion = info.version;
    buildNumber = int.parse(info.buildNumber);

    logger.d("App Version: $appVersion (Build: $buildNumber)");
  }

  Widget selectRootPage({required Widget rootPage, required  Widget? homePage,
    required  Widget splashPage, required  previousVersionPage, required  Widget onGoingPage}) {

    if(!Get.isRegistered<LoginService>() || !Get.isRegistered<UserService>()) {
      return rootPage;
    }

    final loginServiceImpl = Get.find<LoginService>();
    final userServiceImpl = Get.find<UserService>();

    authStatus.value = loginServiceImpl.getAuthStatus();
    if(authStatus.value == AuthStatus.waiting) {
      return splashPage;
    } else if (lastStableBuild > buildNumber) {
      rootPage = previousVersionPage;
    } else if(AppHiveController().firstTime) {
      rootPage = onGoingPage;
      AppHiveController().setFirstTime(false);
    } else if(authStatus.value == AuthStatus.loggingIn) {
      rootPage = splashPage;
    } else if (homePage != null
        && authStatus.value == AuthStatus.loggedIn
        && (userServiceImpl.user.id.isNotEmpty)
        && ((userServiceImpl.user.profiles.isNotEmpty)
            && (userServiceImpl.user.profiles.first.id.isNotEmpty))) {
      rootPage = homePage;
    }

    return rootPage;
  }

}
