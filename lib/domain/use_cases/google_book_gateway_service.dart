import 'dart:async';
import '../model/app_media_item.dart';

abstract class GoogleBookGatewayService {

  Future<Map<String, AppMediaItem>> searchBooksAsMediaItem(String param);


}
