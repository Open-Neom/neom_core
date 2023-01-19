

import 'utils/enums/app_in_use.dart';


class AppFlavour {

  static final AppFlavour _singleton = AppFlavour._internal();
  AppInUse appInUse = AppInUse.emxi;

  factory AppFlavour({AppInUse inUse = AppInUse.cyberneom}) {
    return _singleton;
  }

  AppFlavour._internal();

}
