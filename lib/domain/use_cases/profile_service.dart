import 'package:flutter/cupertino.dart';

import '../../utils/enums/media_upload_destination.dart';
import '../model/app_media_item.dart';

abstract class ProfileService {

  Future<void> editProfile();

  void getItemDetails(AppMediaItem appMediaItem);
  void getTotalItems();

  Future<void> updateLocation();
  Future<void> updateProfileData();

  Future<void> handleAndUploadImage(MediaUploadDestination uploadDestination);

  Future<void> showUpdatePhotoDialog(BuildContext context);
  Future<void> showUpdateCoverImgDialog(BuildContext context);

  String get location;

}
