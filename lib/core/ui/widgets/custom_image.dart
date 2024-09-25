import 'dart:io';
import 'dart:math';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../app_flavour.dart';
import '../../data/implementations/user_controller.dart';
import '../../utils/app_utilities.dart';
import '../../utils/constants/app_route_constants.dart';
import 'full_screen_video.dart';
import 'video_play_button.dart';

Widget customCachedNetworkHeroImage(mediaUrl) {
  AppUtilities.logger.t("Building hero widget for image url: $mediaUrl");
  return mediaUrl == AppFlavour.getNoImageUrl() ? const SizedBox.shrink(): Hero(
    //TODO Improve removing random int to get real hero functionality
    tag: 'img_${mediaUrl}_${Random().nextInt(10000)}',
    child: CachedNetworkImage(
      imageUrl: mediaUrl,
      fit: BoxFit.fill,
      errorWidget: (context,url,error) => const Icon(
        Icons.image_not_supported,
      ),
    ),
  );
}

Widget cachedNetworkProfileImage(String profileId, String mediaUrl) {
  return GestureDetector(
    child: CachedNetworkImage(
        imageUrl: mediaUrl,
        fit: BoxFit.fitHeight,
        placeholder: (context, url) => const CircularProgressIndicator(),
        errorWidget: (context,url,error) => const Icon(Icons.image_not_supported),
    ),
    onTap: () => Get.find<UserController>().profile.id != profileId ?
    Get.toNamed(AppRouteConstants.mateDetails, arguments: profileId)
        : Get.toNamed(AppRouteConstants.profileDetails, arguments: profileId),
  );
}

Widget fileImage(mediaUrl) {
  return GestureDetector(
      child: Hero(
        tag: 'img_file_hero_$mediaUrl',
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Image.file(
            File(mediaUrl),
            fit: BoxFit.fitHeight,
          ),
        ),
      ),
      onTap: () => Get.toNamed(AppRouteConstants.mediaFullScreen, arguments: [mediaUrl, false])
  );
}

// Widget fileImage(mediaUrl) {
//   return GestureDetector(
//     child: Hero(
//       tag: 'img_file_hero_$mediaUrl',
//       child: Container(
//         decoration: BoxDecoration(
//           borderRadius: BorderRadius.circular(10), // Adjust the radius as needed
//           image: DecorationImage(
//             image: FileImage(File(mediaUrl)),
//             fit: BoxFit.fitHeight,
//           ),
//         ),
//       ),
//     ),
//     onTap: () => Get.toNamed(AppRouteConstants.mediaFullScreen, arguments: [mediaUrl, false])
//   );
// }

Widget cachedNetworkThumbnail({required String thumbnailUrl, required String mediaUrl}) {
  return GestureDetector(
    child: Hero(
      tag: 'thumbnail_$thumbnailUrl',
      child: CachedNetworkImage(
        imageUrl: thumbnailUrl,
        fit: BoxFit.cover,
        errorWidget: (context,url,error) => const Icon(
          Icons.error,
        ),
      ),
    ),
    onTap: () => Get.to(() => FullScreenVideo(thumbnailUrl: thumbnailUrl, mediaUrl: mediaUrl),
        transition: Transition.zoom),
  );
}

Widget cachedNetworkVideoThumbnail({required String thumbnailUrl, required String mediaUrl}) {
  return GestureDetector(
    child: Hero(
      tag: 'thumbnail_$thumbnailUrl',
      child: Stack(
        alignment: Alignment.center,
      children: [
        CachedNetworkImage(
          imageUrl: thumbnailUrl,
          fit: BoxFit.fitHeight,
          errorWidget: (context,url,error) => const Icon(Icons.error,),
          height: 300,
        ),
        VideoPlayButton(controllerFunction: () => Get.to(() => FullScreenVideo(thumbnailUrl: thumbnailUrl, mediaUrl: mediaUrl),
            transition: Transition.zoom),)
      ],),
    ),
    onTap: () => Get.to(() => FullScreenVideo(thumbnailUrl: thumbnailUrl, mediaUrl: mediaUrl),
        transition: Transition.zoom),
  );
}
