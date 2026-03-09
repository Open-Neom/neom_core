import 'dart:async';

import '../../utils/platform/core_io.dart';


abstract class WooMediaService {

  Future<String> uploadMediaToWordPress(File file, {String fileName = ''});
  Future<String> getJwtToken();

}
