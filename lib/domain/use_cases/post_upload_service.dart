import 'dart:async';
import 'package:flutter/cupertino.dart';

abstract class PostUploadService {







  Future<void> handleSubmit();
  Future<void> handlePostUpload();

  void setUserLocation(String locationSuggestion);
  void clearUserLocation();
  void getBackToUploadImage(BuildContext context);
  Future<void> getLocation(context);

}
