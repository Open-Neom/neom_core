import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:logger/logger.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'data/firestore/app_info_firestore.dart';
import 'data/implementations/app_hive_controller.dart';
import 'data/implementations/user_controller.dart';
import 'domain/model/app_info.dart';
import 'domain/use_cases/login_service.dart';
import 'utils/enums/app_in_use.dart';
import 'utils/enums/auth_status.dart';

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

  /// Inicialización manual para controlar mejor el ciclo de vida
  Future<void> initialize({required AppInUse app}) async {
    if (_isInitialized) return;
    _isInitialized = true;

    logger.t("AppConfig Initialization");

    try {
      appInUse = app;
      getAppInfo();
      loadPackageInfo();
    } catch (e) {
      logger.e(e.toString());
    }
  }

  Future<void> getAppInfo() async {
    appInfo = await AppInfoFirestore().retrieve();
    lastStableVersion = appInfo.version;
    lastStableBuild = appInfo.build;
    logger.i(appInfo.toString());
  }

  Future<void> loadPackageInfo() async {
    PackageInfo info = await PackageInfo.fromPlatform();
    appVersion = info.version;
    buildNumber = int.parse(info.buildNumber);

    logger.d("App Version: $appVersion (Build: $buildNumber)");
  }

  Widget selectRootPage({required Widget rootPage, required  Widget homePage,
    required  Widget splashPage, required  previousVersionPage, required  Widget onGoingPage}) {

    final loginController = Get.find<LoginService>();
    final userController = Get.find<UserController>();

    authStatus.value = loginController.getAuthStatus();
    if(authStatus.value == AuthStatus.waiting) {
      return splashPage;
    } else if (lastStableBuild > buildNumber) {
      rootPage = previousVersionPage;
    } else if(AppHiveController().firstTime) {
      rootPage = onGoingPage;
      AppHiveController().setFirstTime(false);
    } else if(authStatus.value == AuthStatus.loggingIn) {
      rootPage = splashPage;
    } else if (authStatus.value == AuthStatus.loggedIn
        && (userController.user.id.isNotEmpty)
        && ((userController.user.profiles.isNotEmpty)
            && (userController.user.profiles.first.id.isNotEmpty))) {
      rootPage = homePage;
    }

    return rootPage;
  }

}
