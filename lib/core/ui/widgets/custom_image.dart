import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../app_flavour.dart';
import '../../data/implementations/user_controller.dart';
import '../../utils/app_utilities.dart';
import '../../utils/constants/app_route_constants.dart';

Widget customCachedNetworkImage(mediaUrl) {
  AppUtilities.logger.t("Building widget for image url: $mediaUrl");
  return mediaUrl == AppFlavour.getAppLogoUrl() ? const SizedBox.shrink(): CachedNetworkImage(
    key: ValueKey(mediaUrl),
    imageUrl: mediaUrl,
    fit: BoxFit.fill,
    errorWidget: (context,url,error) => const Icon(
      Icons.image_not_supported,
    ),
  );
}

Widget cachedNetworkProfileImage(String profileId, String mediaUrl) {
  return GestureDetector(
    child: CachedNetworkImage(
      key: ValueKey(mediaUrl),
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
    ///DEPRECATED HERO NOT NEEDED AND BAD PERFORMANCE
      // child: Hero(
      //   tag: 'img_file_hero_$mediaUrl',
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Image.file(
            File(mediaUrl),
            fit: BoxFit.fitHeight,
          ),
        ),
      // ),
      onTap: () => Get.toNamed(AppRouteConstants.mediaFullScreen, arguments: [mediaUrl, false])
  );
}

Widget cachedVideoThumbnail({required String thumbnailUrl, required String mediaUrl}) {
  return GestureDetector(
      child: CachedNetworkImage(
        key: ValueKey(mediaUrl),
        imageUrl: thumbnailUrl,
        fit: BoxFit.cover,
        errorWidget: (context,url,error) => const Icon(
          Icons.error,
        ),
      ),
    // ),
    onTap: () => Get.toNamed(AppRouteConstants.videoFullScreen, arguments: [mediaUrl]),
  );
}

// Widget cachedNetworkVideoThumbnail({required String thumbnailUrl, required String mediaUrl}) {
//   return GestureDetector(
//     ///DEPRECATED HERO NOT NEEDED AND BAD PERFORMANCE
//     // child: Hero(
//     //   tag: 'thumbnail_$thumbnailUrl',
//       child: Stack(
//         alignment: Alignment.center,
//       children: [
//         CachedNetworkImage(
//           imageUrl: thumbnailUrl,
//           fit: BoxFit.fitHeight,
//           errorWidget: (context,url,error) => const Icon(Icons.error,),
//           height: 300,
//         ),
//         VideoPlayButton(controllerFunction: () => Get.to(() => FullScreenVideo(mediaUrl: mediaUrl),
//             transition: Transition.zoom),)
//       ],),
//     // ),
//     onTap: () => Get.to(() => FullScreenVideo(mediaUrl: mediaUrl),
//         transition: Transition.zoom),
//   );
// }
