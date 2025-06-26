//
// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:package_info_plus/package_info_plus.dart';
//
// import '../../app_config.dart';
// import '../../domain/model/app_info.dart';
// import '../../domain/use_cases/login_service.dart';
// import '../../ui/splash_page.dart';
//
// import '../../utils/enums/auth_status.dart';
// import '../firestore/app_info_firestore.dart';
// import 'app_hive_controller.dart';
// import 'user_controller.dart';
//
// class AppController extends GetxController {
//
//   AppInfo appInfo = AppInfo();
//   String lastStableVersion = '';
//   int lastStableBuild = 0;
//
//   String appVersion = '';
//   int buildNumber = 0;
//   Rx<AuthStatus> authStatus = AuthStatus.notDetermined.obs;
//
//   @override
//   void onInit() {
//     super.onInit();
//     AppConfig.logger.t("onInit User Controller");
//     getAppInfo();
//     loadPackageInfo();
//   }
//
//   @override
//   void onReady() {
//     super.onReady();
//     AppConfig.logger.t("onReady User Controller");
//     try {
//
//     } catch (e) {
//       AppConfig.logger.e(e.toString());
//     }
//   }
//
//   Future<void> getAppInfo() async {
//     appInfo = await AppInfoFirestore().retrieve();
//     lastStableVersion = appInfo.version;
//     lastStableBuild = appInfo.build;
//     AppConfig.logger.i(appInfo.toString());
//   }
//
//   Future<void> loadPackageInfo() async {
//     PackageInfo info = await PackageInfo.fromPlatform();
//     appVersion = info.version;
//     buildNumber = int.parse(info.buildNumber);
//
//     AppConfig.logger.d("App Version: $appVersion (Build: $buildNumber)");
//   }
//
//   Widget selectRootPage({required Widget rootPage, required  Widget homePage}) {
//
//     final loginController = Get.find<LoginService>();
//     final userController = Get.find<UserController>();
//
//     authStatus.value = loginController.getAuthStatus();
//     if(authStatus.value == AuthStatus.waiting) {
//       return SplashPage();
//     } else if (lastStableBuild > buildNumber) {
//       rootPage = const PreviousVersionPage();
//     } else if(AppHiveController().firstTime) {
//       rootPage = const OnGoing();
//       AppHiveController().setFirstTime(false);
//     } else if(authStatus.value == AuthStatus.loggingIn) {
//       rootPage = const SplashPage();
//     } else if (authStatus.value == AuthStatus.loggedIn
//         && (userController.user.id.isNotEmpty)
//         && ((userController.user.profiles.isNotEmpty)
//             && (userController.user.profiles.first.id.isNotEmpty))) {
//       rootPage = homePage;
//     }
//
//     return rootPage;
//   }
//
// }
