import 'package:get/get.dart';
import 'ui/analytics/analytics_page.dart';
import 'ui/analytics/nupale/nupale_stats_page.dart';
import 'ui/media/media_fullscreen_page.dart';
import 'ui/static/previous_version_page.dart';
import 'ui/static/splash_page.dart';
import 'ui/static/under_construction_page.dart';
import 'utils/constants/app_route_constants.dart';

class CoreRoutes {

  static final List<GetPage<dynamic>> routes = [
    GetPage(
        name: AppRouteConstants.splashScreen,
        page: () => const SplashPage(),
        transition: Transition.zoom
    ),
    GetPage(
        name: AppRouteConstants.introCreating,
        page: () => const SplashPage(),
        transition: Transition.zoom
    ),
    GetPage(
        name: AppRouteConstants.introWelcome,
        page: () => const SplashPage(),
        transition: Transition.zoom
    ),
    GetPage(
      name: AppRouteConstants.accountRemove,
      page: () => const SplashPage(),
    ),

    GetPage(
        name: AppRouteConstants.mediaFullScreen,
        page: () => const MediaFullScreenPage(),
        transition: Transition.zoom
    ),
    GetPage(
      name: AppRouteConstants.previousVersion,
      page: () => const PreviousVersionPage(),
    ),
    GetPage(
      name: AppRouteConstants.underConstruction,
      page: () => const UnderConstructionPage(),
      transition: Transition.zoom,
    ),
    GetPage(
      name: AppRouteConstants.analytics,
      page: () => const AnalyticsPage(),
      transition: Transition.zoom,
    ),
    GetPage(
      name: AppRouteConstants.nupaleStats,
      page: () => const NupaleStatisticsRootPage(),
      transition: Transition.zoom,
    ),
  ];

}
