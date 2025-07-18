import 'dart:async';
import 'dart:io';


abstract class WooMediaService {

  Future<String> uploadMediaToWordPress(File file, {String fileName = ''});
  Future<String> getJwtToken();

}
