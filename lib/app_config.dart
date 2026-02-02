import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:sint/sint.dart';

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

  AuthStatus authStatus = AuthStatus.notDetermined;
  bool isGuestMode = true;

  Map<String, Itemlist> releaseItemlists = {};
  ItemlistType defaultItemlistType = ItemlistType.playlist;

  /// Inicialización manual para controlar mejor el ciclo de vida
  Future<void> initialize({required AppInUse app}) async {
    if (_isInitialized) return;
    _isInitialized = true;

    logger.t("AppConfig Initialization");

    try {
      appInUse = app;
      await _getAppInfo();
      await _loadPackageInfo();
      if(app == AppInUse.e) {
        defaultItemlistType = ItemlistType.readlist;
      }
    } catch (e) {
      logger.e(e.toString());
    }
  }

  Future<void> _getAppInfo() async {
    AppConfig.logger.d("Retrieving App Info from Firestore...");
    if(appInfo.version.isNotEmpty) {
      logger.d("AppInfo already loaded: ${appInfo.toString()}}");
      return;
    } else if(Firebase.apps.isNotEmpty) {
      appInfo = await AppInfoFirestore().retrieve();
      lastStableVersion = appInfo.version;
      lastStableBuild = appInfo.build;
      logger.d(appInfo.toString());
    } else {
      logger.w("Firebase not initialized, cannot retrieve app info.");
      lastStableVersion = "0.0.0";
      lastStableBuild = 0;
    }

  }

  Future<void> _loadPackageInfo() async {
    AppConfig.logger.d("Loading Package Info...");
    PackageInfo info = await PackageInfo.fromPlatform();
    appVersion = info.version;
    buildNumber = int.parse(info.buildNumber);

    logger.d("App Version: $appVersion (Build: $buildNumber)");
  }

  Widget selectRootPage({required Widget rootPage, required  Widget? homePage,
    required  Widget splashPage, required  previousVersionPage, required  Widget onGoingPage}) {

    if(!Sint.isRegistered<LoginService>() || !Sint.isRegistered<UserService>()) {
      return rootPage;
    }

    final loginServiceImpl = Sint.find<LoginService>();

    authStatus = loginServiceImpl.getAuthStatus();
    if(authStatus == AuthStatus.waiting) {
      return splashPage;
    } else if (lastStableBuild > buildNumber) {
      rootPage = previousVersionPage;
    } else if(AppHiveController().firstTime) {
      rootPage = onGoingPage;
      AppHiveController().setFirstTime(false);
    } else if(authStatus == AuthStatus.loggingIn) {
      rootPage = splashPage;
    } else if (homePage != null
        && (authStatus == AuthStatus.loggedIn || isGuestMode)) {
      rootPage = homePage;
    }

    return rootPage;
  }

}
