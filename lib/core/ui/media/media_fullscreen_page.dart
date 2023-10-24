import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../utils/app_color.dart';
import '../../utils/app_theme.dart';
import '../../utils/constants/app_page_id_constants.dart';
import 'media_fullscreen_controller.dart';

class MediaFullScreenPage extends StatelessWidget {
  const MediaFullScreenPage({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<MediaFullScreenController>(
      id: AppPageIdConstants.mediaFullScreen,
      init: MediaFullScreenController(),
      builder: (_) => Scaffold(
        backgroundColor: AppColor.main50,
        body: InteractiveViewer(
          child: Container(
            decoration: AppTheme.boxDecoration,
            child: GestureDetector(
              child: Center(
                child: Hero(
                    tag: _.isRemote ? 'img_url_hero_${_.mediaUrl}' : 'img_file_hero_${_.mediaUrl}',
                    child: _.isRemote
                        ? CachedNetworkImage(imageUrl: _.mediaUrl,)
                        : Image.file(File(_.mediaUrl)
                    ),
                ),
              ),
              onTap: () {
                Navigator.pop(context);
              },
            ),
          ),
        )
      )
    );
  }

}
