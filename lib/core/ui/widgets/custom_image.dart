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

Widget customCachedNetworkHeroImage(mediaUrl) {
  AppUtilities.logger.v("Building hero widget for image url: $mediaUrl");
  return mediaUrl == AppFlavour.getNoImageUrl() ? Container(): Hero(
    //TODO Improve removing random int to get real hero functionality
    tag: 'img_${mediaUrl}_${Random().nextInt(1000)}',
    child: CachedNetworkImage(
      imageUrl: mediaUrl,
      fit: BoxFit.fill,
      errorWidget: (context,url,error) => const Icon(
        Icons.image_not_supported,
      ),
    ),
  );
}

CachedNetworkImage customCachedNetworkImage(mediaUrl, {BoxFit fit = BoxFit.fill}) {
  AppUtilities.logger.i("Building cache network widget for image url: $mediaUrl");
  return CachedNetworkImage(
    imageUrl: mediaUrl,
    fit: fit,
    placeholder: (context, url) => const CircularProgressIndicator(),
    errorWidget: (context,url,error)=>const Icon(
        Icons.image_not_supported
    ),
  );
}

CachedNetworkImageProvider customCachedNetworkImageProvider(mediaUrl) {
  AppUtilities.logger.v("Building cache network widget for image url: $mediaUrl");
  return CachedNetworkImageProvider(
    mediaUrl,
  );
}

Widget customCachedNetworkProfileImage(String profileId, String mediaUrl) {
  return GestureDetector(
    child: Hero(
      tag: '${profileId}_img_$mediaUrl',
      child: CachedNetworkImage(
        imageUrl: mediaUrl,
        fit: BoxFit.fitHeight,
        errorWidget: (context,url,error) => const Icon(Icons.error),
      ),
    ),
    onTap: () => Get.find<UserController>().profile.id != profileId ?
      Get.offAndToNamed(AppRouteConstants.mateDetails, arguments: profileId)
    : Get.offAndToNamed(AppRouteConstants.profileDetails, arguments: profileId),
  );
}

Widget fileImage(mediaUrl) {
  return GestureDetector(
    child: Hero(
      tag: 'img_file_hero_$mediaUrl',
      child: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: FileImage(File(mediaUrl)),
            fit: BoxFit.fitHeight,
          ),
        ),
      ),
    ),
    onTap: () => Get.toNamed(AppRouteConstants.mediaFullScreen, arguments: [mediaUrl, false])
  );
}


Widget cachedNetworkThumbnail(thumbnailUrl, mediaUrl) {
  return GestureDetector(
    child: Hero(
      tag: 'thumbnail_$thumbnailUrl',
      child:CachedNetworkImage(
        imageUrl: thumbnailUrl,
        fit: BoxFit.cover,
        errorWidget: (context,url,error)=>const Icon(
          Icons.error,
        ),
      ),
    ),
    onTap: () => Get.to(() => FullScreenVideo(thumbnailUrl: thumbnailUrl,
        mediaUrl: mediaUrl),
        transition: Transition.zoom),
  );
}
