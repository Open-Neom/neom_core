import 'package:flutter/material.dart';

import '../model/app_media_item.dart';

abstract class DownloadService {

  Future<void> prepareDownload(BuildContext context, AppMediaItem mediaItem,
      {bool createFolder = false,String? folderName,});

  Future<void> downloadMediaItem(BuildContext context, String? dlPath,
    String fileName, AppMediaItem mediaItem);

}
