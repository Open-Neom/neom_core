
import 'package:flutter/material.dart';

import '../app_flavour.dart';
import 'enums/app_in_use.dart';

class AppColor {

  static const Color appBlack = Color.fromRGBO(41,41,43, 1);

  static Color getMain() {
    AppInUse appInUse = AppFlavour.appInUse;
    Color mainColor = Colors.white;
    switch(appInUse) {
      case AppInUse.e:
        mainColor = const Color.fromRGBO(156, 48, 26, 1);
        break;
      case AppInUse.g:
        mainColor = const Color.fromRGBO(22, 42, 93, 1);
        break;
      case AppInUse.c:
        mainColor = const Color.fromRGBO(79, 25, 100, 1);
        break;
      default:
        mainColor = const Color.fromRGBO(22, 42, 93, 1);
    }

    return mainColor;

  }
  static Color main25 = getMain().withOpacity(0.25);
  static Color main50 = getMain().withOpacity(0.5);
  static Color main75 = getMain().withOpacity(0.75);
  static Color main95 = getMain().withOpacity(0.95);
  static final Color bottomNavigationBar = getMain().withOpacity(0.5);
  static final Color messageComposer = getMain().withOpacity(0.5);
  static final Color drawer = getMain().withOpacity(0.5);
  static final Color appBar = getMain().withOpacity(0.5);
  static final Color boxDecoration = getMain().withOpacity(0.3);

  static const Color secondary = Color(0xff14171A);
  static const Color lightGrey = Color(0xffAAB8C2);

  static const Color white = Colors.white;
  static final Color white80 = Colors.white.withOpacity(0.8);
  static final Color white50 = Colors.white.withOpacity(0.5);
  static final Color white25 = Colors.white.withOpacity(0.25);

  static const Color yellow = Color(0xffFCCD00);
  static const Color ceriseRed = Color.fromRGBO(224, 36, 94, 1.0);
  static const Color red = Colors.red;
  static const Color mystic = Color.fromRGBO(230, 236, 240, 1.0);
  static const Color bondiBlue = Color.fromRGBO(12, 18, 84, 1.0);
  static const Color bondiBlue25 = Color.fromRGBO(12, 18, 84, 0.25);
  static const Color bondiBlue50 = Color.fromRGBO(12, 18, 84, 0.50);
  static const Color bondiBlue75 = Color.fromRGBO(12, 18, 84, 0.75);
  static const Color dodgetBlue = Color.fromRGBO(29, 162, 240, 1.0);

  static const Color textColor = Color.fromRGBO(250, 250, 250, 0.95);
  static const Color textButton = Colors.black;
  static const Color cutColoredImage = Color(0xBB8338f4);
  static const Color cardColor = Color.fromRGBO(47, 65, 123, 0.6);

  static Color getContextCardColor(BuildContext context) {
    return Theme.of(context).cardColor.withOpacity(0.2);
  }

  static const Color blogEditor = Color(0xFF1976D2);

  static const Color darkViolet = Color.fromRGBO(79, 25, 100, 1);
  static Color deepDarkViolet = const Color.fromRGBO(79, 25, 100, 1).withOpacity(0.6);
}
