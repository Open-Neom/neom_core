import 'dart:async';
import '../model/external_item.dart';

abstract class GoogleBookGatewayService {

  Future<Map<String, ExternalItem>> searchBooksAsExternalItem(String param);

}
