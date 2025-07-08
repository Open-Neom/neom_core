import 'dart:async';
import '../model/app_info.dart';


abstract class AppInfoRepository {

  Future<AppInfo> retrieve();

}
