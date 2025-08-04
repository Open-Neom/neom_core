import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:upgrader/upgrader.dart';

import '../app_config.dart';
import '../domain/use_cases/home_service.dart';
import '../domain/use_cases/user_service.dart';
import '../utils/constants/core_constants.dart';
import '../utils/core_utilities.dart';

class RootPage extends StatelessWidget {

  final Widget rootPage;
  final Widget splashPage;
  final Widget? homePage;
  final HomeService? homeService;
  final Widget previousVersionPage;
  final Widget onGoingPage;
  final Widget? miniPlayer;
  final Future<bool> Function(BuildContext context) showExitConfirmationDialog;

  const RootPage({required this.rootPage, required this.splashPage,
    required this.homePage, required this.homeService,
    required this.previousVersionPage, required this.onGoingPage,
    required this.showExitConfirmationDialog, this.miniPlayer, super.key});

  @override
  Widget build(BuildContext context) {
    return PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) async {

          try {
            if((homeService?.currentIndex != CoreConstants.firstHomeTabIndex)
                || (homeService?.getTimelineScrollOffset() != 0.0)) {
              homeService?.selectPageView(CoreConstants.firstHomeTabIndex);
              return;
            }
          } catch (e) {
            AppConfig.logger.e(e.toString());
          }

          bool shouldPop = await showExitConfirmationDialog(context);
          if (shouldPop) CoreUtilities.exitApp();
        },
        child: UpgradeAlert(
              upgrader: Upgrader(
                minAppVersion: AppConfig.instance.lastStableVersion,
              ),
              child: homePage == null ? rootPage : Stack(
                  children: [
                    AppConfig.instance.selectRootPage(
                        rootPage: rootPage,
                        homePage: homePage,
                        splashPage: splashPage,
                        onGoingPage: onGoingPage,
                        previousVersionPage: previousVersionPage
                    ),
                    if (Get.isRegistered<UserService>() && Get.find<UserService>().user.id.isNotEmpty && miniPlayer != null
                        && (homeService?.timelineReady ?? false) && (homeService?.mediaPlayerEnabled ?? false))
                      Positioned(
                        left: 0, right: 0,
                        bottom: 0,
                        child: miniPlayer!,
                      ),
                  ]
              )

        )
    );
  }
}
